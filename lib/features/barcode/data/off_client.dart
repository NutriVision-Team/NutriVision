import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException, HttpException, HandshakeException;
import 'package:http/http.dart' as http;

import '../domain/barcode_code.dart';
import '../domain/off_product.dart';

/// Configuration the integrating app must supply. The brief requires a custom,
/// identifiable User-Agent of the form `AppName/Version (ContactEmail)`.
/// Distributors must provide their own OFF_CONTACT (--dart-define).
/// An invalid or empty contact disables network lookup.
class OffConfig {
  const OffConfig({
    this.appName = 'Sufra',
    this.appVersion = '1.0.0',
    this.contact = const String.fromEnvironment('OFF_CONTACT'),
    this.host = 'world.openfoodfacts.org',
    this.timeout = const Duration(seconds: 8),
  });

  final String appName;
  final String appVersion;
  final String contact;
  final String host;
  final Duration timeout;

  bool get isConfigured =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(contact) &&
      !contact.endsWith('example.com') &&
      !contact.endsWith('.invalid');

  String get userAgent => '$appName/$appVersion ($contact)';
}

/// Raw transport result. [body] is only inspected when [status] is 200/404.
class OffHttpResponse {
  const OffHttpResponse(this.status, this.body, {this.retryAfter});
  final int status;
  final String body;
  final Duration? retryAfter;
}

abstract class OffTransport {
  Future<OffHttpResponse> get(Uri uri, {required Map<String, String> headers});
}

/// Cross-platform transport. A fresh client owns each bounded request so timeout
/// and size rejection can close native sockets or browser fetch immediately.
class IoOffTransport implements OffTransport {
  IoOffTransport({
    this.timeout = const Duration(seconds: 8),
    http.Client Function()? clientFactory,
  }) : _factory = clientFactory ?? http.Client.new;
  final Duration timeout;
  final http.Client Function() _factory;
  @override
  Future<OffHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    final client = _factory();
    final abort = Completer<void>();
    final timer = Timer(timeout, () {
      if (!abort.isCompleted) abort.complete();
      client.close();
    });
    try {
      final req = http.AbortableRequest('GET', uri, abortTrigger: abort.future);
      req.headers.addAll(headers);
      final res = await client.send(req);
      final bytes = <int>[];
      await for (final chunk in res.stream) {
        if (bytes.length + chunk.length > 2 * 1024 * 1024) {
          if (!abort.isCompleted) abort.complete();
          throw const FormatException('Product response too large');
        }
        bytes.addAll(chunk);
      }
      final ra = int.tryParse(res.headers['retry-after'] ?? '');
      return OffHttpResponse(
        res.statusCode,
        utf8.decode(bytes),
        retryAfter: ra == null ? null : Duration(seconds: ra),
      );
    } finally {
      timer.cancel();
      client.close();
    }
  }
}

sealed class OffFetchResult {
  const OffFetchResult();
}

class OffFetched extends OffFetchResult {
  const OffFetched(this.product);
  final OffProduct product;
}

class OffNotFound extends OffFetchResult {
  const OffNotFound();
}

enum OffFailure {
  notConfigured,
  offline,
  rateLimited,
  unavailable,
  badResponse,
}

class OffFailed extends OffFetchResult {
  const OffFailed(this.reason, {this.retryAfter});
  final OffFailure reason;
  final Duration? retryAfter;
}

/// Sliding-window limiter. Open Food Facts allows 15 product reads/minute per
/// IP; the default here stays below it at 10 so shared Wi-Fi has headroom.
class RequestThrottle {
  RequestThrottle({
    this.maxPerWindow = 10,
    this.window = const Duration(minutes: 1),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final int maxPerWindow;
  final Duration window;
  final DateTime Function() _now;
  final List<DateTime> _stamps = [];
  DateTime? _blockedUntil;

  /// Returns null when a request may go now (and records it), otherwise how
  /// long to wait.
  Duration? tryAcquire() {
    final now = _now();
    if (_blockedUntil != null && now.isBefore(_blockedUntil!)) {
      return _blockedUntil!.difference(now);
    }
    _stamps.removeWhere((t) => now.difference(t) >= window);
    if (_stamps.length >= maxPerWindow) {
      return window - now.difference(_stamps.first);
    }
    _stamps.add(now);
    return null;
  }

  /// Honors HTTP 429/503 so the next call waits instead of hammering.
  void backOff(Duration d) => _blockedUntil = _now().add(d);
}

/// Open Food Facts API v3 product read. Single-barcode reads only: there is no
/// search and no search-as-you-type.
class OffClient {
  OffClient({
    this.config = const OffConfig(),
    OffTransport? transport,
    RequestThrottle? throttle,
  }) : _transport = transport ?? IoOffTransport(timeout: config.timeout),
       throttle = throttle ?? RequestThrottle();

  final OffConfig config;
  final OffTransport _transport;
  final RequestThrottle throttle;

  Uri uriFor(BarcodeCode code) => Uri.https(
    config.host,
    '/api/v3/product/${code.value}.json',
    {'fields': OffProduct.requestedFields},
  );

  Future<OffFetchResult> fetch(BarcodeCode code) async {
    if (!config.isConfigured) {
      return const OffFailed(OffFailure.notConfigured);
    }
    final wait = throttle.tryAcquire();
    if (wait != null) {
      return OffFailed(OffFailure.rateLimited, retryAfter: wait);
    }
    final OffHttpResponse res;
    try {
      res = await _transport
          .get(
            uriFor(code),
            headers: {
              'User-Agent': config.userAgent,
              'Accept': 'application/json',
            },
          )
          .timeout(config.timeout);
    } on SocketException {
      return const OffFailed(OffFailure.offline);
    } on HttpException {
      return const OffFailed(OffFailure.unavailable);
    } on HandshakeException {
      return const OffFailed(OffFailure.unavailable);
    } on http.RequestAbortedException {
      return const OffFailed(OffFailure.unavailable);
    } on TimeoutException {
      return const OffFailed(OffFailure.unavailable);
    } on FormatException {
      return const OffFailed(OffFailure.badResponse);
    } on http.ClientException {
      return const OffFailed(OffFailure.unavailable);
    } catch (_) {
      // Unknown transport/plugin failures must leave loading and allow retry.
      return const OffFailed(OffFailure.unavailable);
    }
    if (res.status == 429 || res.status == 503) {
      final d = res.retryAfter ?? const Duration(seconds: 60);
      throttle.backOff(d);
      return OffFailed(OffFailure.rateLimited, retryAfter: d);
    }
    if (res.status >= 500) return const OffFailed(OffFailure.unavailable);
    if (res.status != 200 && res.status != 404) {
      return const OffFailed(OffFailure.badResponse);
    }
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return const OffFailed(OffFailure.badResponse);
      }
      json = decoded;
    } on FormatException {
      return const OffFailed(OffFailure.badResponse);
    }
    if (json['status'] == 'success') {
      final product = OffProduct.fromV3(
        code.value,
        json,
        responseUrl: Uri.https(
          config.host,
          '/product/${code.value}',
        ).toString(),
      );
      // A record with no name is treated as not usable, not as a product.
      return product == null
          ? const OffFailed(OffFailure.badResponse)
          : OffFetched(product);
    }
    final id = (json['result'] is Map) ? (json['result'] as Map)['id'] : null;
    if (id == 'product_not_found' || res.status == 404) {
      return const OffNotFound();
    }
    return const OffFailed(OffFailure.badResponse);
  }
}
