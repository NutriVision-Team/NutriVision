import 'protected_ledger_config.dart';
import 'local_account_day_ledger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/progression_engine.dart';
import 'local_protected_ledger.dart';
import 'progression_repository.dart';

/// Protected server aggregate, not reconstruction from mutable nutrition records.
class LocalProtectedProgressionRepository implements ProgressionRepository {
  LocalProtectedProgressionRepository(this.ledger);
  final LocalProtectedLedger ledger;
  @override
  Future<ProgressionSnapshot> load(String uid, String todayKey) async {
    ledger.assertOwner(uid);
    final raw = await ledger.load(uid);
    final c =
        (await ledger.db
                .doc('app_config/progression_proof')
                .get(const GetOptions(source: Source.server)))
            .data();
    ledger.assertOwner(uid);
    if (c == null) throw const ProtectedLedgerFailure('missing_config');
    final labels = await BundledProgressionConfigSource().load();
    ledger.assertOwner(uid);
    final validated = ProtectedLedgerConfig.parse(c);
    final config = validated.display(labels);
    final levels = config.levels;
    final xp = raw?['xp'] as int? ?? 0;
    if (raw != null && raw['configVersion'] != config.version) {
      throw const ProtectedLedgerFailure('config_migration_required');
    }
    final index = levels.lastIndexWhere((l) => l.xp <= xp);
    if (index < 0 || (raw != null && raw['levelId'] != levels[index].id)) {
      throw const ProtectedLedgerFailure('invalid_profile');
    }
    final awarded = raw == null
        ? <String>{}
        : (raw['badges'] as Map).entries
              .where((e) => e.value == true)
              .map((e) => e.key as String)
              .toSet();
    final count = raw?['activeDays'] as int? ?? 0;
    final events = ledger is LocalAccountDayLedger
        ? await (ledger as LocalAccountDayLedger).acceptedActivity(uid)
        : <ProgressionEvent>[];
    final days = events.map((e) => e.dayKey).toSet();
    if (ledger is LocalAccountDayLedger && days.length != count) {
      throw const ProtectedLedgerFailure('inconsistent_day_history');
    }
    final accountToday = ledger is LocalAccountDayLedger
        ? await (ledger as LocalAccountDayLedger).accountTodayKey(
            uid,
            DateTime.now(),
          )
        : todayKey;
    final streak = ProgressionEngine(config).project(uid, accountToday, events);
    final result = ProgressionProfile(
      uid: uid,
      configVersion: config.version,
      xp: xp,
      level: levels[index],
      nextLevel: index + 1 < levels.length ? levels[index + 1] : null,
      counts: {
        'meal': raw?['meals'] as int? ?? 0,
        'plan': raw?['plans'] as int? ?? 0,
        'profile': raw?['setup'] as int? ?? 0,
        'activeDay': count,
      },
      badges: awarded,
      activeDays: days,
      currentStreak: streak.currentStreak,
      bestStreak: streak.bestStreak,
      todayKey: accountToday,
    );
    final pending = await ledger.pending(uid);
    ledger.assertOwner(uid);
    return ProgressionSnapshot(
      result,
      config,
      events,
      authoritative: true,
      activeDayCount: count,
      pendingCount: pending.length,
      draftPolicy: true,
      hasLedger: raw != null,
    );
  }
}
