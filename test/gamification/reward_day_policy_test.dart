import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:sufradepi/features/gamification/domain/reward_day_policy.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  final activation = DateTime.utc(2026, 1, 1);
  RewardDayPolicy policy(String zone) =>
      RewardDayPolicy(zone: zone, activatedAtUtc: activation);
  test('Cairo local midnight is not UTC midnight', () {
    final p = policy('Africa/Cairo');
    expect(p.at(DateTime.utc(2026, 11, 24, 21, 59, 59)).key, '2026-11-24');
    expect(p.at(DateTime.utc(2026, 11, 24, 22)).key, '2026-11-25');
  });
  test('Cairo spring transition day is 23h and fallback day 25h', () {
    final p = policy('Africa/Cairo');
    final spring = p.at(DateTime.utc(2026, 4, 24, 12)),
        fall = p.at(DateTime.utc(2026, 10, 29, 12));
    expect(spring.endUtc.difference(spring.startUtc).inHours, 23);
    expect(fall.endUtc.difference(fall.startUtc).inHours, 25);
    expect(
      p.at(spring.endUtc.subtract(const Duration(microseconds: 1))).key,
      spring.key,
    );
    expect(p.at(spring.endUtc).key, isNot(spring.key));
  });
  test(
    'other IANA timezone boundaries use pinned database, no hardcoded offset',
    () {
      final p = policy('America/New_York');
      expect(
        p
            .at(DateTime.utc(2026, 3, 8, 12))
            .endUtc
            .difference(p.at(DateTime.utc(2026, 3, 8, 12)).startUtc)
            .inHours,
        23,
      );
      expect(
        p
            .at(DateTime.utc(2026, 11, 1, 12))
            .endUtc
            .difference(p.at(DateTime.utc(2026, 11, 1, 12)).startUtc)
            .inHours,
        25,
      );
      expect(() => policy('invalid/zone').at(activation), throwsA(anything));
    },
  );
  test('delayed retry stays original day without 48h cutoff', () {
    final p = policy('Africa/Cairo'),
        recorded = DateTime.utc(2026, 11, 20, 22, 30);
    final day = p.eligibleDay(
      recordedAtUtc: recorded,
      trustedNowUtc: DateTime.utc(2026, 12, 10),
      fixedOwnerZone: 'Africa/Cairo',
    );
    expect(day.key, '2026-11-21');
    expect(day.contains(recorded), isTrue);
    expect(day.contains(day.endUtc), isFalse);
  });
  test('legacy/future/preactivation fail closed, owner zone cannot hop', () {
    final p = policy('Africa/Cairo');
    for (final recorded in [
      null,
      DateTime.utc(2025, 12, 31),
      DateTime.utc(2027),
    ]) {
      expect(
        () => p.eligibleDay(
          recordedAtUtc: recorded,
          trustedNowUtc: DateTime.utc(2026, 11, 24),
          fixedOwnerZone: 'Africa/Cairo',
        ),
        throwsStateError,
      );
    }
    expect(
      () => p.eligibleDay(
        recordedAtUtc: DateTime.utc(2026, 11, 24),
        trustedNowUtc: DateTime.utc(2026, 11, 24),
        fixedOwnerZone: 'UTC',
      ),
      throwsStateError,
    );
  });
  test(
    'per-day buckets prevent reverse-order retry from reminting; edits/delete retain',
    () {
      final p = policy('Africa/Cairo');
      final d1 = p.at(DateTime.utc(2026, 11, 20)),
          d2 = p.at(DateTime.utc(2026, 11, 21));
      final h = RetainedRewardHistory()
          .record(
            kind: 'meal',
            sourceId: 'one',
            day: d2,
            dailyXp: 10,
            earnedBadges: {'first_meal'},
          )
          .record(kind: 'meal', sourceId: 'old_retry', day: d1, dailyXp: 10)
          .record(kind: 'meal', sourceId: 'same_day', day: d2, dailyXp: 10);
      expect(h.xp, 20);
      expect(h.sourceIds.length, 3);
      expect(
        h.record(kind: 'meal', sourceId: 'one', day: d1, dailyXp: 10),
        same(h),
      );
      expect(h.sourceEditedOrDeleted('one'), same(h));
      expect(h.badges, {'first_meal'});
    },
  );
  test('setup once is not a per-day allowance', () {
    final p = policy('Africa/Cairo');
    final h = RetainedRewardHistory().record(
      kind: 'profile',
      sourceId: 'setup',
      day: p.at(activation),
      dailyXp: 20,
    );
    expect(
      h
          .record(
            kind: 'profile',
            sourceId: 'setup2',
            day: p.at(activation.add(const Duration(days: 10))),
            dailyXp: 20,
          )
          .xp,
      20,
    );
  });
}
