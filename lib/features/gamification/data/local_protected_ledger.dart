import 'protected_ledger_config.dart';
import 'queue_lock_stub.dart'
    if (dart.library.js_interop) 'queue_lock_web.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Optional local experiment. Production repositories never construct one.
abstract interface class LocalRecordedActivityHook {
  void assertOwner(String uid);
  Future<void> beforeSourceSave(String uid, String kind, String id);
  Map<String, dynamic> newSourceFields();
  Future<void> sourceSaved(String uid, String kind, String id);
}

class ProtectedLedgerFailure implements Exception {
  const ProtectedLedgerFailure(this.code);
  final String code;
}

/// Local-only Rules ledger adapter, deliberately incompatible with live projects.
/// Client values are proposals. Emulator Rules independently validate every delta.
class LocalProtectedLedger implements LocalRecordedActivityHook {
  LocalProtectedLedger({required this.db, required this.currentUid}) {
    if (db.app.options.projectId != 'demo-sufra-progression-app') {
      throw const ProtectedLedgerFailure('local_demo_project_required');
    }
  }
  final FirebaseFirestore db;
  final String? Function() currentUid;
  final Map<String, String?> _failures = {};
  String? get lastFailure => _failures[currentUid()];
  set lastFailure(String? value) {
    final uid = currentUid();
    if (uid != null) _failures[uid] = value;
  }

  static final Map<String, Future<void>> _queueTails = {};
  Future<T> _serialized<T>(String uid, Future<T> Function() action) async {
    final previous = _queueTails[uid] ?? Future<void>.value();
    final done = Completer<void>();
    _queueTails[uid] = done.future;
    await previous;
    try {
      return await crossTabQueueLock(_queueKey(uid), action);
    } finally {
      done.complete();
      if (identical(_queueTails[uid], done.future)) _queueTails.remove(uid);
    }
  }

  String _queueKey(String uid) => 'sufra.local.ledger.pending.$uid';
  Future<List<String>> pending(String uid) async {
    assertOwner(uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    assertOwner(uid);
    return List<String>.from(prefs.getStringList(_queueKey(uid)) ?? []);
  }

  @override
  Future<void> beforeSourceSave(String uid, String kind, String id) async {
    assertOwner(uid);
    try {
      await _remember(uid, kind, id);
    } catch (_) {
      // Queue quota/storage failure must not prevent an ordinary nutrition save.
      if (currentUid() == uid) _failures[uid] = 'pending_storage_unavailable';
    }
    assertOwner(uid);
  }

  Future<void> _remember(String uid, String kind, String id) =>
      _serialized(uid, () async {
        assertOwner(uid);
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        assertOwner(uid);
        final rows = prefs.getStringList(_queueKey(uid)) ?? [];
        final item = jsonEncode({'kind': kind, 'id': id});
        if (!rows.contains(item)) {
          if (rows.length >= 100) {
            throw const ProtectedLedgerFailure('pending_full');
          }
          await prefs.setStringList(_queueKey(uid), [...rows, item]);
        }
      });

  Future<void> recover(String uid) async {
    for (final item in await pending(uid)) {
      assertOwner(uid);
      final row = jsonDecode(item) as Map;
      await sourceSaved(uid, row['kind'] as String, row['id'] as String);
    }
  }

  Future<void> discardPending(String uid) => _serialized(uid, () async {
    assertOwner(uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    assertOwner(uid);
    await prefs.remove(_queueKey(uid));
  });

  /// Explicit local-only lifecycle proof. Not connected to production settings.
  /// Tombstone stays to prevent reward reset farming for this UID.
  Future<void> eraseLocalRewardsPermanently(String uid) async {
    assertOwner(uid);
    final state = db.doc('users/$uid/reward_lifecycle/state');
    final existing = await state.get(const GetOptions(source: Source.server));
    assertOwner(uid);
    if (!existing.exists) {
      await state.set({'disabledAt': FieldValue.serverTimestamp()});
    }
    final profile = db.doc('users/$uid/gamification/profile');
    while (true) {
      final rows = await profile
          .collection('sources')
          .limit(100)
          .get(const GetOptions(source: Source.server));
      assertOwner(uid);
      if (rows.docs.isEmpty) break;
      final batch = db.batch();
      for (final row in rows.docs) {
        batch.delete(row.reference);
      }
      await batch.commit();
    }
    assertOwner(uid);
    await profile.delete();
    await discardPending(uid);
  }

  static final _id = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
  @override
  void assertOwner(String uid) {
    if (!_id.hasMatch(uid) || currentUid() != uid) {
      throw const ProtectedLedgerFailure('account_changed');
    }
  }

  @override
  Map<String, dynamic> newSourceFields() => {
    'rewardRecordedAt': FieldValue.serverTimestamp(),
  };
  @override
  Future<void> sourceSaved(String uid, String kind, String id) async {
    // Nutrition save remains successful when a separate reward request fails.
    try {
      await _remember(uid, kind, id);
      await award(uid, kind, id);
      assertOwner(uid);
      await _serialized(uid, () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        assertOwner(uid);
        final rows = prefs.getStringList(_queueKey(uid)) ?? [];
        rows.remove(jsonEncode({'kind': kind, 'id': id}));
        await prefs.setStringList(_queueKey(uid), rows);
      });
      if (currentUid() == uid) _failures[uid] = null;
    } catch (_) {
      _failures[uid] = currentUid() != uid
          ? 'account_changed'
          : 'award_pending';
    }
  }

  Future<Map<String, dynamic>?> load(String uid) async {
    assertOwner(uid);
    final snapshot = await db
        .doc('users/$uid/gamification/profile')
        .get(const GetOptions(source: Source.server));
    assertOwner(uid);
    // Never read owner-writable legacy achievements or project source data here.
    return snapshot.data();
  }

  Future<void> award(String uid, String kind, String id) async {
    assertOwner(uid);
    if (!{'meal', 'plan', 'profile'}.contains(kind) || !_id.hasMatch(id)) {
      throw const ProtectedLedgerFailure('unsupported_activity');
    }
    final profile = db.doc('users/$uid/gamification/profile');
    final event = '${kind}_$id';
    final marker = profile.collection('sources').doc(event);
    await db.runTransaction((tx) async {
      assertOwner(uid);
      final previous = await tx.get(profile);
      final duplicate = await tx.get(marker);
      final config = await tx.get(db.doc('app_config/progression_proof'));
      assertOwner(uid);
      if (duplicate.exists) return;
      final c = config.data();
      if (c == null) throw const ProtectedLedgerFailure('missing_config');
      ProtectedLedgerConfig.parse(c);
      final old = previous.data();
      if (old != null && old['configVersion'] != c['version']) {
        throw const ProtectedLedgerFailure('config_migration_required');
      }
      final now = DateTime.now().toUtc();
      final today = Timestamp.fromDate(
        DateTime.utc(now.year, now.month, now.day),
      );
      final epoch = Timestamp.fromMillisecondsSinceEpoch(0);
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
      final meal = kind == 'meal',
          plan = kind == 'plan',
          setup = kind == 'profile';
      final dayKey = meal ? 'lastMealDay' : 'lastPlanDay';
      final same = p[dayKey] == today;
      final xp = setup
          ? c['profileXp']
          : same
          ? 0
          : c[meal ? 'mealXp' : 'planXp'];
      if (xp is! int || xp < 0 || xp > 100) {
        throw const ProtectedLedgerFailure('invalid_config');
      }
      p['xp'] = (p['xp'] as int) + xp;
      if (meal) p['meals'] = (p['meals'] as int) + 1;
      if (plan) p['plans'] = (p['plans'] as int) + 1;
      if (setup) p['setup'] = (p['setup'] as int) + 1;
      if (!setup && p['lastActiveDay'] != today) {
        p['activeDays'] = (p['activeDays'] as int) + 1;
        p['lastActiveDay'] = today;
      }
      if (!setup) p[dayKey] = today;
      final thresholds = List<int>.from(c['levelXp'] as List);
      final levels = List<String>.from(c['levelIds'] as List);
      if (thresholds.length != 5 || levels.length != 5) {
        throw const ProtectedLedgerFailure('invalid_config');
      }
      final index = thresholds.lastIndexWhere((n) => n <= (p['xp'] as int));
      if (index < 0) throw const ProtectedLedgerFailure('invalid_config');
      p['levelId'] = levels[index];
      final targets = Map<String, dynamic>.from(c['badgeTargets'] as Map);
      const metrics = {
        'journey': 'setup',
        'first_meal': 'meals',
        'aware': 'meals',
        'planner': 'plans',
        'planner3': 'plans',
        'active7': 'activeDays',
        'active30': 'activeDays',
        'returning': 'activeDays',
      };
      p['badges'] = {
        for (final e in metrics.entries)
          e.key: (p[e.value] as int) >= (targets[e.key] as int),
      };
      p.addAll({
        'lastEvent': event,
        'awardedAt': FieldValue.serverTimestamp(),
        'configVersion': c['version'],
      });
      assertOwner(uid);
      tx.set(profile, p);
      tx.set(marker, {
        'kind': kind,
        'sourceId': id,
        'awardedAt': FieldValue.serverTimestamp(),
      });
    });
    assertOwner(uid);
  }
}
