import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/gamification/data/trusted_ledger_client.dart';

const policy = {
  'status': 'provisional',
  'dayBasis': 'UTC',
  'retention': 'unresolved',
};
Map<String, Object?> envelope({Object? profile, String uid = 'u'}) => {
  'schemaVersion': 1,
  'uid': uid,
  'policy': policy,
  'profile': profile,
};
Map<String, Object?> profile() => {
  'schemaVersion': 1,
  'uid': 'u',
  'totalXp': 10,
  'configVersion': 'v1',
  'levelId': 'seed',
  'counts': {'profile': 0, 'meal': 10, 'plan': 0, 'activeDay': 1},
  'earnedBadgeIds': <String>[],
};
void main() {
  test('null ledger means absent, not computed reward', () async {
    final client = TrustedLedgerClient(
      currentUid: () => 'u',
      transport: (_, _, _) async => LedgerResponse(200, envelope()),
    );
    expect((await client.load()).profile, isNull);
  });
  test('account switch drops late owned profile', () async {
    String uid = 'u';
    final pending = Completer<LedgerResponse>();
    final client = TrustedLedgerClient(
      currentUid: () => uid,
      transport: (_, _, _) => pending.future,
    );
    final result = client.load();
    uid = 'other';
    pending.complete(LedgerResponse(200, envelope(profile: profile())));
    await expectLater(result, throwsA(isA<TrustedLedgerUnavailable>()));
  });
  test(
    'outage malformed and cross-owner never fall back to projection',
    () async {
      for (final response in [
        LedgerResponse(503, {}),
        LedgerResponse(200, {}),
        LedgerResponse(200, envelope(uid: 'other', profile: profile())),
        LedgerResponse(200, envelope(profile: {...profile(), 'totalXp': -1})),
        LedgerResponse(
          200,
          envelope(
            profile: {
              ...profile(),
              'counts': {'meal': 10},
            },
          ),
        ),
      ]) {
        final client = TrustedLedgerClient(
          currentUid: () => 'u',
          transport: (_, _, _) async => response,
        );
        await expectLater(
          client.load(),
          throwsA(isA<TrustedLedgerUnavailable>()),
        );
      }
    },
  );
  test(
    'activity request sends only kind/source and never client XP/UID/date',
    () async {
      final calls = <Map<String, Object?>?>[];
      final client = TrustedLedgerClient(
        currentUid: () => 'u',
        transport: (method, path, body) async {
          expect(method, 'POST');
          expect(path, '/v1/award');
          calls.add(body);
          return LedgerResponse(200, {
            ...envelope(),
            'result': {'status': 'already_awarded', 'xp': 0},
          });
        },
      );
      await client.requestRecordedActivity('meal', 'm0');
      expect(calls.single, {'kind': 'meal', 'sourceId': 'm0'});
      await expectLater(
        client.requestRecordedActivity('lesson', 'm1'),
        throwsA(isA<TrustedLedgerUnavailable>()),
      );
      await expectLater(
        client.requestRecordedActivity('profile', 'other'),
        throwsA(isA<TrustedLedgerUnavailable>()),
      );
      expect(calls.length, 1);
    },
  );
  test('signed-out request never reaches transport', () async {
    var calls = 0;
    final client = TrustedLedgerClient(
      currentUid: () => null,
      transport: (_, _, _) async {
        calls++;
        return const LedgerResponse(200, {});
      },
    );
    await expectLater(client.load(), throwsA(isA<TrustedLedgerUnavailable>()));
    expect(calls, 0);
  });
  final fixture = Platform.environment['SUFRA_LEDGER_FIXTURE_PATH'];
  test(
    'actual emulator contract profile accepted without recomputing XP',
    () async {
      final body = (jsonDecode(File(fixture!).readAsStringSync()) as Map)
          .cast<String, Object?>();
      final client = TrustedLedgerClient(
        currentUid: () => 'u',
        transport: (_, _, _) async => LedgerResponse(200, body),
      );
      final loaded = await client.load();
      expect(loaded.profile!['totalXp'], 10);
      expect((loaded.profile!['counts'] as Map)['meal'], 10);
    },
    skip: fixture == null
        ? 'Run with demo-emulator generated envelope path.'
        : false,
  );
}
