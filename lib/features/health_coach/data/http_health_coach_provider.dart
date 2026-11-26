import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../domain/health_coach_orchestrator.dart';

/// An explicitly configured trusted backend, never a client-side model key.
/// Not enabled by normal routing. A reviewed backend deployment is required.
class HttpHealthCoachProvider
    implements HealthCoachProvider, CancellableCoachProvider {
  HttpHealthCoachProvider({
    required this.endpoint,
    required this.allowedHosts,
    required this.userId,
    required this.currentUid,
    required this.idToken,
    required this.client,
    this.timeout = const Duration(seconds: 30),
    this.knownSourceIds = const {},
  });

  static bool _sameSelection(Object? raw, Object? reviewed) {
    if (raw is! List || reviewed is! List || raw.length != reviewed.length) {
      return false;
    }
    for (var i = 0; i < raw.length; i++) {
      final a = raw[i], b = reviewed[i];
      if (a is! Map ||
          b is! Map ||
          a.length != 2 ||
          a['foodId'] != b['foodId'] ||
          a['grams'] != b['grams']) {
        return false;
      }
    }
    return true;
  }

  final Uri endpoint;
  final Set<String> allowedHosts;
  final String userId;
  final String? Function() currentUid;
  final Future<String?> Function() idToken;
  final http.Client client;
  final Duration timeout;
  final Set<String> knownSourceIds;

  void _active() {
    if (userId.isEmpty || currentUid() != userId) {
      throw StateError('Inactive account');
    }
  }

  final Set<Completer<void>> _pending = {};

  @override
  void cancelPending() {
    for (final signal in _pending.toList(growable: false)) {
      if (!signal.isCompleted) signal.complete();
    }
  }

  @override
  Future<HealthCoachReply> generate(HealthCoachRequest request) async {
    // No queued or parallel requests for one account-scoped provider.
    if (_pending.isNotEmpty) throw StateError('Request already in flight');
    final signal = Completer<void>();
    _pending.add(signal);
    final timer = Timer(timeout, () {
      if (!signal.isCompleted) signal.complete();
    });
    try {
      return await _generate(
        request,
        DateTime.now().add(timeout),
        signal,
      ).timeout(timeout);
    } finally {
      timer.cancel();
      if (!signal.isCompleted) signal.complete();
      _pending.remove(signal);
    }
  }

  Future<HealthCoachReply> _generate(
    HealthCoachRequest request,
    DateTime deadline,
    Completer<void> signal,
  ) async {
    _active();
    if (endpoint.scheme != 'https' ||
        !allowedHosts.contains(endpoint.host) ||
        endpoint.path != '/chat' ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        endpoint.userInfo.isNotEmpty ||
        (endpoint.hasPort && endpoint.port != 443)) {
      throw StateError('Unapproved backend');
    }
    final body = jsonEncode({
      'question': request.question,
      'locale': request.locale,
      'consentVersion': 'coach-external-v1',
      'context': request.context,
    });
    if (utf8.encode(body).length > 24000) throw StateError('Context too large');
    final token = await idToken();
    _active();
    if (signal.isCompleted || !DateTime.now().isBefore(deadline)) {
      throw TimeoutException('Expired request');
    }
    if (token == null || token.isEmpty) throw StateError('Missing identity');
    final outgoing =
        http.AbortableRequest('POST', endpoint, abortTrigger: signal.future)
          ..followRedirects = false
          ..headers.addAll({
            'authorization': 'Bearer $token',
            'content-type': 'application/json',
          })
          ..body = body;
    final response = await client.send(outgoing);
    _active();
    if (signal.isCompleted) throw StateError('Request cancelled');
    if (response.statusCode != 200) throw StateError('Coach unavailable');
    final media = response.headers['content-type']?.split(';').first.trim();
    if (media != 'application/json') throw StateError('Invalid content type');
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      _active();
      if (bytes.length + chunk.length > 24000) {
        throw StateError('Reply too large');
      }
      bytes.addAll(chunk);
    }
    _active();
    if (signal.isCompleted) throw StateError('Request cancelled');
    final value = jsonDecode(utf8.decode(bytes));
    if (value is! Map<String, dynamic> ||
        !value.keys.every(
          const {
            'text',
            'origin',
            'sourceIds',
            'navigation',
            'requiresUserReview',
            'model',
            'calculation',
          }.contains,
        ) ||
        !const {'ai', 'safety'}.contains(value['origin']) ||
        value['text'] is! String ||
        value['sourceIds'] is! List ||
        value['navigation'] is! List) {
      throw StateError('Invalid reply');
    }
    final sources = value['sourceIds'] as List;
    final navigation = value['navigation'] as List;
    if (sources.length > 8 ||
        !sources.every((id) => id is String && knownSourceIds.contains(id)) ||
        navigation.length > 3 ||
        !navigation.every(
          const {'planner', 'diary', 'water', 'recipes', 'report'}.contains,
        )) {
      throw StateError('Unknown reference');
    }
    final calculation = value['calculation'];
    final reviewed = request.context['reviewedCalculation'];
    final stats = <String, String>{};
    if (reviewed != null && value['origin'] == 'ai') {
      if (calculation is! Map ||
          calculation['saved'] != false ||
          !_sameSelection(calculation['selection'], reviewed) ||
          calculation['catalogVersion'] != '1.0.0' ||
          calculation['energyKcal'] is! num ||
          !(calculation['energyKcal'] as num).isFinite ||
          (calculation['energyKcal'] as num) < 0 ||
          (calculation['proteinG'] != null &&
              (calculation['proteinG'] is! num ||
                  !(calculation['proteinG'] as num).isFinite ||
                  (calculation['proteinG'] as num) < 0))) {
        throw StateError('Invalid deterministic calculation');
      }
      final ar = request.locale == 'ar';
      stats[ar ? 'الطاقة من الكتالوج' : 'Catalog energy'] =
          '${(calculation['energyKcal'] as num).toStringAsFixed(1)} kcal';
      stats[ar
          ? 'البروتين من الكتالوج'
          : 'Catalog protein'] = calculation['proteinG'] == null
          ? (ar ? 'غير معروف' : 'Unknown')
          : '${(calculation['proteinG'] as num).toStringAsFixed(1)} g';
    } else if (calculation != null) {
      throw StateError('Unrequested calculation');
    }
    // Navigation is not executed. The presentation layer must offer a fixed
    // route after user interaction; generated writes are never accepted here.
    return HealthCoachReply(
      text: value['text'] as String,
      trustedToolStats: stats,
      calculationValues: calculation is Map
          ? [
              (calculation['energyKcal'] as num).toDouble(),
              (calculation['proteinG'] as num?)?.toDouble(),
            ]
          : null,
      origin: value['origin'] == 'safety'
          ? CoachReplyOrigin.safety
          : CoachReplyOrigin.ai,
      sourceIds: sources.cast<String>().toSet().toList(),
    );
  }
}
