import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/services/push_device_lifecycle.dart';
import 'package:sufradepi/services/optional_messaging_startup.dart';

class Backend implements PushDeviceBackend {
  bool allowed = true, failRemove = false;
  String value = 'one';
  String? remembered;
  Completer<String?>? gate;
  final records = <String, String>{};
  final calls = <String>[];
  @override
  Future<bool> hasPermission() async => allowed;
  @override
  Future<String?> token() async => gate == null ? value : gate!.future;
  @override
  Future<void> deleteToken() async {
    calls.add('revoke');
  }

  @override
  Future<void> remove(String uid) async {
    calls.add('remove:$uid');
    if (failRemove) throw StateError('offline');
    records.remove(uid);
  }

  @override
  Future<void> save(String uid, String token) async {
    calls.add('save:$uid');
    records[uid] = token;
  }

  @override
  Future<void> rememberOwner(String? uid) async {
    remembered = uid;
  }
}

void main() {
  test('denied permission never gets/saves a token', () async {
    final b = Backend()..allowed = false;
    await PushDeviceLifecycle(b).sync('a');
    expect(b.records, isEmpty);
    expect(b.calls, isEmpty);
  });
  test(
    'rotation updates same owned installation and signout revokes before unlink',
    () async {
      final b = Backend();
      final l = PushDeviceLifecycle(b);
      await l.sync('a');
      b.value = 'two';
      await l.sync('a');
      expect(b.records, {'a': 'two'});
      await l.sync(null);
      expect(b.records, isEmpty);
      expect(b.calls.sublist(2), ['revoke', 'remove:a']);
      expect(b.remembered, isNull);
    },
  );
  test('account change during token wait cannot save prior owner', () async {
    final b = Backend()..gate = Completer<String?>();
    final l = PushDeviceLifecycle(b);
    final first = l.sync('a');
    await Future<void>.delayed(Duration.zero);
    final second = l.sync('b');
    b.gate!.complete('token');
    await Future.wait([first, second]);
    expect(b.records, {'b': 'token'});
  });
  test(
    'unlink failure blocks relink and recovers only after cleanup',
    () async {
      final b = Backend();
      final l = PushDeviceLifecycle(b);
      await l.sync('a');
      b.failRemove = true;
      await expectLater(l.sync('b'), throwsStateError);
      expect(b.records.keys, ['a']);
      expect(l.unavailable, isTrue);
      b.failRemove = false;
      await l.sync('b');
      expect(b.records, {'b': 'one'});
      expect(l.unavailable, isFalse);
    },
  );
  test('permission revoked unlinks remembered owner after restart', () async {
    final b = Backend()
      ..allowed = false
      ..records['a'] = 'old';
    await PushDeviceLifecycle(b, initialOwner: 'a').sync('a');
    expect(b.records, isEmpty);
    expect(b.calls, ['revoke', 'remove:a']);
  });
  test('push routing rejects foreign owner and arbitrary routes', () {
    expect(ownedPushRoute({'uid': 'a', 'type': 'water'}, 'a'), '/water');
    expect(ownedPushRoute({'uid': 'b', 'type': 'water'}, 'a'), isNull);
    expect(
      ownedPushRoute({'uid': 'a', 'type': 'https://outside'}, 'a'),
      isNull,
    );
    expect(ownedPushRoute({'type': 'meal'}, null), isNull);
  });
  test('optional push failure never escapes into startup', () async {
    expect(
      await initializeOptionalMessaging(
        () async => throw StateError('private'),
      ),
      isFalse,
    );
    expect(await initializeOptionalMessaging(() async {}), isTrue);
  });
}
