import 'dart:async';

abstract interface class PushDeviceBackend {
  Future<bool> hasPermission();
  Future<String?> token();
  Future<void> deleteToken();
  Future<void> save(String uid, String token);
  Future<void> remove(String uid);
  Future<void> rememberOwner(String? uid);
}

/// Serialized owner changes. No prompt and no token content in diagnostics.
class PushDeviceLifecycle {
  PushDeviceLifecycle(this.backend, {String? initialOwner})
    : _owner = initialOwner;
  final PushDeviceBackend backend;
  String? _owner;
  String? _desired;
  int _generation = 0;
  Future<void> _chain = Future.value();
  bool unavailable = false;

  Future<void> sync(String? uid) {
    _desired = uid;
    final generation = ++_generation;
    final next = _chain.then((_) async {
      try {
        if (_owner != null &&
            (_owner != uid || !await backend.hasPermission())) {
          // Revoke at the provider first. Never reuse an old account's token
          // when its owned record cannot be removed.
          await backend.deleteToken();
          await backend.remove(_owner!);
          await backend.rememberOwner(null);
          _owner = null;
        }
        if (generation != _generation || uid == null || _desired != uid) return;
        if (!await backend.hasPermission()) return;
        final value = await backend.token();
        if (generation != _generation ||
            _desired != uid ||
            value == null ||
            value.isEmpty) {
          return;
        }
        // Remember ownership before a potentially partially successful write.
        await backend.rememberOwner(uid);
        _owner = uid;
        await backend.save(uid, value);
        unavailable = false;
      } catch (_) {
        unavailable = true;
        // Block account relinking until revocation/removal can be retried.
        rethrow;
      }
    });
    _chain = next.catchError((Object _) {});
    return next;
  }
}

String? ownedPushRoute(Map<String, dynamic> data, String? uid) {
  if (uid == null || data['uid'] != uid) return null;
  return switch (data['type']) {
    'water' => '/water',
    'weight' => '/weight',
    'meal' => '/diary',
    _ => null,
  };
}
