/// Experimental trusted-ledger client boundary. Not wired to production UI.
/// No client-side XP computation or fallback to projection on server failure.
library;

typedef LedgerTransport =
    Future<LedgerResponse> Function(
      String method,
      String path,
      Map<String, Object?>? body,
    );

class LedgerResponse {
  const LedgerResponse(this.status, this.body);
  final int status;
  final Map<String, Object?> body;
}

class TrustedLedgerUnavailable implements Exception {
  const TrustedLedgerUnavailable(this.code);
  final String code;
}

class TrustedLedgerSnapshot {
  const TrustedLedgerSnapshot({required this.uid, required this.profile});
  final String uid;

  /// Null means no server profile, never an inferred zero-XP award.
  final Map<String, Object?>? profile;
}

class TrustedLedgerClient {
  TrustedLedgerClient({required this.currentUid, required this.transport});
  final String? Function() currentUid;

  /// Transport owns secure auth. This client never reads or persists a token.
  final LedgerTransport transport;
  static final _id = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
  String _owner() {
    final uid = currentUid();
    if (uid == null || !_id.hasMatch(uid)) {
      throw const TrustedLedgerUnavailable('authentication_required');
    }
    return uid;
  }

  Map<String, Object?> _envelope(LedgerResponse response, String owner) {
    if (currentUid() != owner) {
      throw const TrustedLedgerUnavailable('account_changed');
    }
    if (response.status != 200) {
      throw const TrustedLedgerUnavailable('ledger_unavailable');
    }
    final body = response.body;
    final policy = body['policy'];
    if (body['schemaVersion'] != 1 ||
        body['uid'] != owner ||
        policy is! Map ||
        policy['status'] != 'provisional' ||
        policy['dayBasis'] != 'UTC' ||
        policy['retention'] != 'unresolved') {
      throw const TrustedLedgerUnavailable('invalid_ledger_response');
    }
    return body;
  }

  Future<TrustedLedgerSnapshot> load() async {
    final owner = _owner();
    final response = await transport('GET', '/v1/profile', null);
    final body = _envelope(response, owner);
    final raw = body['profile'];
    if (raw == null) return TrustedLedgerSnapshot(uid: owner, profile: null);
    if (raw is! Map ||
        raw['uid'] != owner ||
        raw['schemaVersion'] != 1 ||
        raw['totalXp'] is! int ||
        (raw['totalXp'] as int) < 0 ||
        raw['configVersion'] is! String ||
        raw['levelId'] is! String ||
        raw['counts'] is! Map ||
        raw['earnedBadgeIds'] is! List) {
      throw const TrustedLedgerUnavailable('invalid_ledger_response');
    }
    final counts = raw['counts'] as Map;
    if ([
          'profile',
          'meal',
          'plan',
          'activeDay',
        ].any((key) => counts[key] is! int || (counts[key] as int) < 0) ||
        (raw['earnedBadgeIds'] as List).any(
          (id) => id is! String || !_id.hasMatch(id),
        )) {
      throw const TrustedLedgerUnavailable('invalid_ledger_response');
    }
    return TrustedLedgerSnapshot(
      uid: owner,
      profile: Map<String, Object?>.unmodifiable(raw.cast<String, Object?>()),
    );
  }

  Future<void> requestRecordedActivity(String kind, String sourceId) async {
    final owner = _owner();
    if (!{'meal', 'plan', 'profile'}.contains(kind) ||
        !_id.hasMatch(sourceId) ||
        (kind == 'profile' && sourceId != 'setup')) {
      throw const TrustedLedgerUnavailable('unsupported_activity');
    }
    final body = _envelope(
      await transport('POST', '/v1/award', {
        'kind': kind,
        'sourceId': sourceId,
      }),
      owner,
    );
    final result = body['result'];
    if (result is! Map ||
        !{
          'awarded',
          'activity_recorded',
          'already_awarded',
          'source_already_rewarded',
        }.contains(result['status']) ||
        result['xp'] is! int ||
        (result['xp'] as int) < 0 ||
        (result['xp'] as int) > 100) {
      throw const TrustedLedgerUnavailable('invalid_ledger_response');
    }
    // Acknowledgment only. Caller must reload the server profile, never add XP.
  }
}
