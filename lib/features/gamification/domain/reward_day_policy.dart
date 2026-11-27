import 'package:timezone/timezone.dart' as tz;
import 'progression_engine.dart';

/// Source-only approved policy contract. Caller must supply server-recorded time
/// and an immutable, trusted account timezone, never device preferences/clock.
class RewardDay {
  const RewardDay({
    required this.zone,
    required this.key,
    required this.startUtc,
    required this.endUtc,
  });
  final String zone, key;
  final DateTime startUtc, endUtc;
  bool contains(DateTime instant) =>
      !instant.toUtc().isBefore(startUtc) && instant.toUtc().isBefore(endUtc);
  Map<String, Object> calendarRecord() => {
    'zone': zone,
    'dayKey': key,
    'startUtc': startUtc.toIso8601String(),
    'endUtc': endUtc.toIso8601String(),
  };
}

class RewardDayPolicy {
  const RewardDayPolicy({required this.zone, required this.activatedAtUtc});
  final String zone;
  final DateTime activatedAtUtc;
  RewardDay at(DateTime recordedAtUtc) {
    // Timezone DB is initialized once by the application/tool, not per award.
    final location = tz.getLocation(zone);
    final local = tz.TZDateTime.from(recordedAtUtc.toUtc(), location);
    final start = tz.TZDateTime(location, local.year, local.month, local.day);
    final end = tz.TZDateTime(location, local.year, local.month, local.day + 1);
    return RewardDay(
      zone: zone,
      key: ProgressionEngine.keyOf(local),
      startUtc: start.toUtc(),
      endUtc: end.toUtc(),
    );
  }

  /// No old-record backfill, no arbitrary retry expiration. A later retry keeps
  /// the original recorded day. Null/legacy timestamps can never become now.
  RewardDay eligibleDay({
    required DateTime? recordedAtUtc,
    required DateTime trustedNowUtc,
    required String fixedOwnerZone,
  }) {
    if (fixedOwnerZone != zone) {
      throw StateError('reward_timezone_change_requires_migration');
    }
    if (recordedAtUtc == null ||
        recordedAtUtc.toUtc().isBefore(activatedAtUtc.toUtc()) ||
        recordedAtUtc.toUtc().isAfter(trustedNowUtc.toUtc())) {
      throw StateError('ineligible_recorded_activity');
    }
    return at(recordedAtUtc);
  }
}

/// Award source IDs/day buckets are persisted under protected Rules. This pure
/// helper does not grant XP or claim server trust on its own.
class RetainedRewardHistory {
  RetainedRewardHistory({
    Set<String> sourceIds = const {},
    Set<String> dayBuckets = const {},
    this.xp = 0,
    Set<String> badges = const {},
  }) : sourceIds = Set.unmodifiable(sourceIds),
       dayBuckets = Set.unmodifiable(dayBuckets),
       badges = Set.unmodifiable(badges);
  final Set<String> sourceIds, dayBuckets, badges;
  final int xp;
  RetainedRewardHistory record({
    required String kind,
    required String sourceId,
    required RewardDay day,
    required int dailyXp,
    Set<String> earnedBadges = const {},
  }) {
    if (!{'meal', 'plan', 'profile'}.contains(kind) ||
        !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(sourceId) ||
        dailyXp < 0 ||
        dailyXp > 100) {
      throw ArgumentError('Unsupported reward event');
    }
    final source = '$kind:$sourceId';
    if (sourceIds.contains(source)) return this;
    final bucket = kind == 'profile'
        ? 'profile:once'
        : '$kind:${day.zone}:${day.key}';
    return RetainedRewardHistory(
      sourceIds: {...sourceIds, source},
      dayBuckets: {...dayBuckets, bucket},
      xp: xp + (dayBuckets.contains(bucket) ? 0 : dailyXp),
      badges: {...badges, ...earnedBadges},
    );
  }

  // Normal source mutations do not rewrite accepted history. This is NOT the
  // separate full-account deletion/retention policy.
  RetainedRewardHistory sourceEditedOrDeleted(String sourceId) => this;
}
