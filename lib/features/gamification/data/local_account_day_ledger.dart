import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import '../domain/progression_engine.dart';
import 'local_protected_ledger.dart';
import 'protected_ledger_config.dart';

/// Integrated account-day candidate. Inherits demo-project guard and durable
/// pending/recovery. Production activation is deliberately not available here.
class LocalAccountDayLedger extends LocalProtectedLedger {
  LocalAccountDayLedger({required super.db, required super.currentUid});
  Future<String> accountTodayKey(String uid, DateTime instant) async {
    assertOwner(uid);
    final policy =
        (await db
                .doc('reward_policies/$uid')
                .get(const GetOptions(source: Source.server)))
            .data();
    assertOwner(uid);
    if (policy == null) throw const ProtectedLedgerFailure('missing_policy');
    return ProgressionEngine.keyOf(
      tz.TZDateTime.from(instant, tz.getLocation(policy['zone'] as String)),
    );
  }

  @override
  Future<void> eraseLocalRewardsPermanently(String uid) async {
    assertOwner(uid);
    throw const ProtectedLedgerFailure('full_deletion_policy_unselected');
  }

  Future<List<ProgressionEvent>> acceptedActivity(String uid) async {
    assertOwner(uid);
    final rows = await db
        .collection('users/$uid/gamification/profile/days')
        .limit(3661)
        .get(const GetOptions(source: Source.server));
    assertOwner(uid);
    if (rows.docs.length > 3660) {
      throw const ProtectedLedgerFailure('day_history_limit');
    }
    return [
      for (final row in rows.docs)
        for (final kind in ['meal', 'plan'])
          if (row.data()[kind] == true)
            ProgressionEvent(
              uid: uid,
              sourceId: 'accepted_${kind}_${row.id}',
              kind: kind,
              dayKey: row.id,
            ),
    ];
  }

  @override
  Future<void> award(String uid, String kind, String id) async {
    assertOwner(uid);
    if (!{'meal', 'plan', 'profile'}.contains(kind) ||
        !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(id)) {
      throw const ProtectedLedgerFailure('unsupported_activity');
    }
    final profile = db.doc('users/$uid/gamification/profile'),
        event = '${kind}_$id';
    final marker = profile.collection('sources').doc(event);
    await db.runTransaction((tx) async {
      assertOwner(uid);
      final previous = await tx.get(profile), duplicate = await tx.get(marker);
      if (duplicate.exists) return;
      final config = (await tx.get(
        db.doc('app_config/progression_proof'),
      )).data();
      final ownerPolicy = (await tx.get(db.doc('reward_policies/$uid'))).data();
      final sourcePath = kind == 'profile'
          ? 'users/$uid'
          : kind == 'meal'
          ? 'users/$uid/meal_entries/$id'
          : 'users/$uid/meal_plans/$id';
      final source = (await tx.get(db.doc(sourcePath))).data();
      assertOwner(uid);
      if (config == null || ownerPolicy == null || source == null) {
        throw const ProtectedLedgerFailure('missing_policy_or_source');
      }
      final validated = ProtectedLedgerConfig.parse(config);
      validated.requireCompatible(previous.data());
      final zone = ownerPolicy['zone'] as String,
          zoneId = ownerPolicy['zoneId'] as String;
      final recorded =
          source[kind == 'profile'
              ? 'rewardSetupRecordedAt'
              : 'rewardRecordedAt'];
      if (recorded is! Timestamp ||
          ownerPolicy['activatedAt'] is! Timestamp ||
          recorded.compareTo(ownerPolicy['activatedAt'] as Timestamp) < 0) {
        throw const ProtectedLedgerFailure('legacy_source_not_eligible');
      }
      final local = tz.TZDateTime.from(recorded.toDate(), tz.getLocation(zone));
      final day = ProgressionEngine.keyOf(local);
      final calendar = (await tx.get(
        db.doc('reward_calendars/$zoneId/days/$day'),
      )).data();
      if (calendar == null ||
          calendar['zone'] != zone ||
          calendar['dayKey'] != day ||
          calendar['start'] is! Timestamp ||
          calendar['end'] is! Timestamp ||
          recorded.compareTo(calendar['start'] as Timestamp) < 0 ||
          recorded.compareTo(calendar['end'] as Timestamp) >= 0) {
        throw const ProtectedLedgerFailure('trusted_calendar_unavailable');
      }
      final dayRef = profile.collection('days').doc(day);
      final oldDay = (await tx.get(dayRef)).data();
      final setup = kind == 'profile',
          meal = kind == 'meal',
          plan = kind == 'plan';
      final old = previous.data();
      if (old != null && old['rewardZoneId'] != zoneId) {
        throw const ProtectedLedgerFailure('reward_zone_migration_required');
      }
      final epoch = Timestamp.fromMillisecondsSinceEpoch(0),
          today = Timestamp.fromDate(
            DateTime.utc(local.year, local.month, local.day),
          );
      final p = <String, dynamic>{
        'xp': 0,
        'meals': 0,
        'plans': 0,
        'setup': 0,
        'activeDays': 0,
        'lastActiveDay': epoch,
        'lastMealDay': epoch,
        'lastPlanDay': epoch,
        ...?old,
      };
      final d = <String, dynamic>{'meal': false, 'plan': false, ...?oldDay};
      final firstActive = !setup && oldDay == null;
      final firstKind = setup || d[kind] != true;
      p['xp'] =
          (p['xp'] as int) +
          (firstKind
              ? config[setup
                        ? 'profileXp'
                        : meal
                        ? 'mealXp'
                        : 'planXp']
                    as int
              : 0);
      if (meal) p['meals'] = (p['meals'] as int) + 1;
      if (plan) p['plans'] = (p['plans'] as int) + 1;
      if (setup) p['setup'] = (p['setup'] as int) + 1;
      if (firstActive) p['activeDays'] = (p['activeDays'] as int) + 1;
      if (!setup) {
        if ((p['lastActiveDay'] as Timestamp).compareTo(today) < 0) {
          p['lastActiveDay'] = today;
        }
        final key = meal ? 'lastMealDay' : 'lastPlanDay';
        if ((p[key] as Timestamp).compareTo(today) < 0) p[key] = today;
        d[kind] = true;
        d['lastEvent'] = event;
      }
      final thresholds = List<int>.from(config['levelXp'] as List),
          levels = List<String>.from(config['levelIds'] as List);
      p['levelId'] =
          levels[thresholds.lastIndexWhere((n) => n <= (p['xp'] as int))];
      const metrics = {
        'journey': 'setup',
        'first_meal': 'meals',
        'aware': 'meals',
        'planner': 'plans',
        'planner3': 'plans',
        'returning': 'activeDays',
        'active7': 'activeDays',
        'active30': 'activeDays',
      };
      final targets = Map<String, dynamic>.from(config['badgeTargets'] as Map);
      p['badges'] = {
        for (final e in metrics.entries)
          e.key: (p[e.value] as int) >= (targets[e.key] as int),
      };
      p.addAll({
        'lastEvent': event,
        'awardedAt': FieldValue.serverTimestamp(),
        'configVersion': config['version'],
        'rewardZoneId': zoneId,
      });
      assertOwner(uid);
      tx.set(profile, p);
      tx.set(marker, {
        'kind': kind,
        'sourceId': id,
        'dayKey': day,
        'zoneId': zoneId,
        'awardedAt': FieldValue.serverTimestamp(),
      });
      if (!setup) tx.set(dayRef, d);
    });
    assertOwner(uid);
  }
}
