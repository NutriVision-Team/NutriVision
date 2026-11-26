import 'package:cloud_firestore/cloud_firestore.dart';

class SavedCoachChoices {
  const SavedCoachChoices({
    this.profile = const {},
    this.goals = const [],
    this.habits = const [],
    this.checkins = const {},
    this.fields = const [],
  });
  final Map<String, Object> profile;
  final List<String> goals, habits, fields;
  final Map<String, List<String>> checkins;
}

abstract class CoachHealthStore {
  Future<SavedCoachChoices> load();
  Future<void> save(SavedCoachChoices value, String day);
  Future<void> deleteDay(String day);
  Future<void> deleteAll();
}

/// Explicit online transactions only. No offline write queue, chat or AI context.
class FirestoreCoachHealthStore implements CoachHealthStore {
  FirestoreCoachHealthStore(
    this.db, {
    required this.uid,
    required this.assertActive,
  });
  final FirebaseFirestore db;
  final String uid;
  final void Function(String) assertActive;
  DocumentReference<Map<String, dynamic>> doc(String c, String id) {
    assertActive(uid);
    return db.collection('users').doc(uid).collection(c).doc(id);
  }

  @override
  Future<SavedCoachChoices> load() async {
    final p = await doc(
      'coach_preferences',
      'current',
    ).get(const GetOptions(source: Source.server));
    assertActive(uid);
    // Always read deletable records too, even if preferences were removed.

    final profile = await doc(
      'health_profile',
      'current',
    ).get(const GetOptions(source: Source.server));
    assertActive(uid);
    final goals = await doc(
      'health_goals',
      'current',
    ).get(const GetOptions(source: Source.server));
    assertActive(uid);
    final checks = await db
        .collection('users')
        .doc(uid)
        .collection('health_checkins')
        .orderBy('day', descending: true)
        .limit(62)
        .get(const GetOptions(source: Source.server));
    assertActive(uid);
    List<String> list(dynamic v) =>
        v is List ? v.whereType<String>().toList() : [];
    return SavedCoachChoices(
      profile: Map<String, Object>.from(profile.data()?['values'] ?? {}),
      goals: list(goals.data()?['goals']),
      habits: list(goals.data()?['habits']),
      fields: list(p.data()?['fields']),
      checkins: {for (final d in checks.docs) d.id: list(d.data()['done'])},
    );
  }

  @override
  Future<void> save(SavedCoachChoices v, String day) async {
    final prefs = doc('coach_preferences', 'current'),
        profile = doc('health_profile', 'current'),
        goals = doc('health_goals', 'current'),
        check = doc('health_checkins', day);
    await db.runTransaction((tx) async {
      assertActive(uid);
      await tx.get(prefs);
      assertActive(uid);
      final stamp = FieldValue.serverTimestamp();
      tx.set(prefs, {'version': 1, 'fields': v.fields, 'updatedAt': stamp});
      tx.set(profile, {'version': 1, 'values': v.profile, 'updatedAt': stamp});
      tx.set(goals, {
        'version': 1,
        'goals': v.goals,
        'habits': v.habits,
        'updatedAt': stamp,
      });
      tx.set(check, {
        'version': 1,
        'day': day,
        'done': v.checkins[day] ?? <String>[],
        'updatedAt': stamp,
      });
    }, maxAttempts: 1);
    assertActive(uid);
    final read = await load();
    assertActive(uid);
    if (read.fields.length != v.fields.length ||
        read.checkins[day]?.join('|') != (v.checkins[day] ?? []).join('|')) {
      throw StateError('Save not verified');
    }
  }

  @override
  Future<void> deleteDay(String day) async {
    final ref = doc('health_checkins', day);
    await db.runTransaction((tx) async {
      assertActive(uid);
      await tx.get(ref);
      assertActive(uid);
      tx.delete(ref);
    }, maxAttempts: 1);
    assertActive(uid);
    if ((await ref.get(const GetOptions(source: Source.server))).exists) {
      throw StateError('Delete not verified');
    }
    assertActive(uid);
  }

  @override
  Future<void> deleteAll() async {
    final checks = await db
        .collection('users')
        .doc(uid)
        .collection('health_checkins')
        .limit(400)
        .get(const GetOptions(source: Source.server));
    assertActive(uid);
    if (checks.docs.length == 400) {
      throw StateError('Too many records, delete days in smaller groups');
    }
    final refs = [
      doc('coach_preferences', 'current'),
      doc('health_profile', 'current'),
      doc('health_goals', 'current'),
      ...checks.docs.map((d) => d.reference),
    ];
    await db.runTransaction((tx) async {
      assertActive(uid);
      await tx.get(refs.first);
      assertActive(uid);
      for (final ref in refs) {
        tx.delete(ref);
      }
    }, maxAttempts: 1);
    assertActive(uid);
    final left = await load();
    if (left.fields.isNotEmpty ||
        left.profile.isNotEmpty ||
        left.goals.isNotEmpty ||
        left.habits.isNotEmpty ||
        left.checkins.isNotEmpty) {
      throw StateError('Delete not verified');
    }
  }
}
