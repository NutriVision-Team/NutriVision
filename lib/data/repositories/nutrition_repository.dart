import '../models/favorite_model.dart';
import '../../features/gamification/data/local_protected_ledger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/nutrition_values.dart';
import '../models/meal_day_totals.dart';
import '../models/daily_log_model.dart';
import '../models/meal_entry_model.dart';
import '../models/nutrition_profile_model.dart';

abstract class NutritionRepository {
  Future<void> saveNutritionProfile(String uid, NutritionProfileModel profile);
  Future<List<NutritionProfileModel>> getNutritionProfiles(String uid);
  Future<void> saveMealEntry(String uid, MealEntryModel meal);
  Future<void> deleteMealEntry(String uid, String mealId);
  Future<List<MealEntryModel>> getMealEntries(String uid, {String? dateKey});
  Future<void> upsertDailyLog(String uid, DailyLogModel dailyLog);
  Future<DailyLogModel?> getDailyLog(String uid, String dateKey);
  Future<List<DailyLogModel>> getDailyLogs(String uid, {int limit = 30});
}

abstract interface class LiveDiaryRepository {
  Stream<List<MealEntryModel>> watchMealEntries(String uid, String dateKey);
  Stream<DailyLogModel?> watchDailyLog(String uid, String dateKey);
}

class FirestoreNutritionRepository
    implements NutritionRepository, LiveDiaryRepository {
  @override
  Stream<List<MealEntryModel>> watchMealEntries(String uid, String dateKey) {
    if (uid.isEmpty || uid.contains('/')) throw ArgumentError('Invalid owner');
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.mealEntries)
        .where('dateKey', isEqualTo: dateKey)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MealEntryModel.fromMap(doc.id, doc.data()))
              .where((meal) => meal.userId == uid && meal.dateKey == dateKey)
              .toList(),
        );
  }

  @override
  Stream<DailyLogModel?> watchDailyLog(String uid, String dateKey) {
    if (uid.isEmpty ||
        uid.contains('/') ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateKey)) {
      throw ArgumentError('Invalid owner/date');
    }
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.dailyLogs)
        .doc(dateKey)
        .snapshots()
        .map((doc) => doc.exists ? DailyLogModel.fromMap(doc.data()!) : null);
  }

  FirestoreNutritionRepository(this._firestore, {this.localActivityHook});

  final LocalRecordedActivityHook? localActivityHook;

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveNutritionProfile(
    String uid,
    NutritionProfileModel profile,
  ) async {
    final ref = _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.nutritionProfiles)
        .doc(profile.profileId);

    await ref.set(profile.toMap(), SetOptions(merge: true));
  }

  @override
  Future<List<NutritionProfileModel>> getNutritionProfiles(String uid) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.nutritionProfiles)
        .get();

    return snapshot.docs
        .map((doc) => NutritionProfileModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> saveMealEntry(String uid, MealEntryModel meal) async {
    if (meal.userId != uid ||
        meal.title.trim().isEmpty ||
        meal.dateKey != SufraDateUtils.toDateKey(meal.consumedAt) ||
        knownNutrient(meal.totalCalories) == null) {
      throw ArgumentError('Invalid or mismatched meal');
    }
    localActivityHook?.assertOwner(uid);
    await localActivityHook?.beforeSourceSave(uid, 'meal', meal.mealId);
    await _mutateMeal(uid, meal.mealId, meal);
    await localActivityHook?.sourceSaved(uid, 'meal', meal.mealId);
  }

  @override
  Future<void> deleteMealEntry(String uid, String mealId) =>
      _mutateMeal(uid, mealId, null);

  Future<void> _mutateMeal(
    String uid,
    String id,
    MealEntryModel? replacement,
  ) async {
    if (uid.isEmpty || uid.contains('/') || id.isEmpty || id.contains('/')) {
      throw ArgumentError('Valid owner and meal IDs are required');
    }
    final user = _firestore.collection(FirestoreCollections.users).doc(uid);
    final entries = user.collection(FirestoreCollections.mealEntries);
    final ref = entries.doc(id);
    // Snapshot a current target only for a newly created current-day log.
    // A historical date must not acquire today's target by assumption.
    final profiles = replacement == null
        ? <NutritionProfileModel>[]
        : await getNutritionProfiles(uid);
    final active = profiles.where((p) => p.isActive).firstOrNull;
    await _firestore.runTransaction((transaction) async {
      localActivityHook?.assertOwner(uid);
      final old = await transaction.get(ref);
      final oldData = old.data();
      if (oldData != null && oldData['userId'] != uid) {
        throw StateError('Meal ownership mismatch');
      }
      if (!old.exists && replacement == null) return;
      final dates = <String>{
        if (oldData != null) oldData['dateKey'] as String,
        if (replacement != null) replacement.dateKey,
      };
      final logs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final key in dates) {
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
          throw const FormatException('Invalid recorded date');
        }
        logs[key] = await transaction.get(
          user.collection(FirestoreCollections.dailyLogs).doc(key),
        );
      }
      // Every app meal mutation reads this shared daily document before the
      // server query and writes it in the same transaction. Concurrent app
      // writes therefore retry and rebuild from the latest records, rather
      // than applying deltas to possibly stale legacy aggregates.
      final totals = <String, Map<String, dynamic>>{};
      for (final key in dates) {
        final snapshot = await entries
            .where('dateKey', isEqualTo: key)
            .get(const GetOptions(source: Source.server));
        final owned = <String, MealEntryModel>{};
        for (final doc in snapshot.docs) {
          if (doc.id == id) continue;
          final meal = MealEntryModel.fromMap(doc.id, doc.data());
          if (meal.userId != uid || meal.dateKey != key) {
            throw StateError('Meal query ownership or date mismatch');
          }
          // Include document versions in the transaction read set as well.
          final checked = await transaction.get(doc.reference);
          if (checked.exists) {
            final current = MealEntryModel.fromMap(doc.id, checked.data()!);
            if (current.userId != uid || current.dateKey != key) {
              throw StateError('Changed meal ownership or date mismatch');
            }
            owned[doc.id] = current;
          }
        }
        if (replacement != null && replacement.dateKey == key) {
          owned[id] = replacement;
        }
        totals[key] = mealDayTotals(owned.values);
      }
      // Derive sixth-addition favorites from confirmed source records. Reads
      // join this transaction before any writes, so retries are idempotent.
      final automatic = <FavoriteModel>[];
      final counters =
          <DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>{};
      DocumentReference<Map<String, dynamic>>? preferenceLock;
      if (!old.exists && replacement?.analysisStatus == 'confirmed') {
        final favorites = user.collection(FirestoreCollections.favorites);
        preferenceLock = favorites.doc('_food_repeat_serialization');
        await transaction.get(preferenceLock);
        final foodIds = replacement!.items
            .map((i) => i.foodId)
            .where((id) => id.isNotEmpty)
            .toSet();
        final missing = <String>{};
        final counts = <String, int>{};
        for (final foodId in foodIds) {
          final counter = await transaction.get(
            favorites.doc('_repeat_${Uri.encodeComponent(foodId)}'),
          );
          if (counter.exists) {
            counts[foodId] = (counter.data()?['count'] as num?)?.toInt() ?? 0;
          } else {
            missing.add(foodId);
          }
        }
        // One-time migration from saved confirmed meals per food. Subsequently
        // bounded counter documents avoid rereading all history on each save.
        if (missing.isNotEmpty) {
          final all = await entries.get(
            const GetOptions(source: Source.server),
          );
          for (final foodId in missing) {
            counts[foodId] = 0;
          }
          for (final doc in all.docs) {
            if (missing.every((id) => counts[id]! >= 6)) break;
            final checked = await transaction.get(doc.reference);
            if (!checked.exists) continue;
            final meal = MealEntryModel.fromMap(doc.id, checked.data()!);
            if (meal.userId != uid || meal.analysisStatus != 'confirmed') {
              continue;
            }
            for (final foodId
                in meal.items
                    .map((i) => i.foodId)
                    .toSet()
                    .intersection(missing)) {
              counts[foodId] = (counts[foodId]! + 1).clamp(0, 6);
            }
          }
        }
        for (final foodId in foodIds) {
          final before = counts[foodId]!;
          final after = (before + 1).clamp(0, 6);
          counters[favorites.doc('_repeat_${Uri.encodeComponent(foodId)}')] = {
            'targetType': 'internal_food_repeat',
            'targetId': foodId,
            'count': after,
          };
          if (before < 6 && after == 6 ||
              missing.contains(foodId) && after == 6) {
            final f = FavoriteModel(
              favoriteId: 'food_${Uri.encodeComponent(foodId)}',
              targetId: foodId,
              targetType: 'food',
              title: replacement.items
                  .firstWhere((i) => i.foodId == foodId)
                  .foodName,
            );
            final existing = await transaction.get(favorites.doc(f.favoriteId));
            if (existing.exists &&
                (existing.data()?['targetType'] != 'food' ||
                    existing.data()?['targetId'] != foodId)) {
              throw StateError('Favorite identity collision');
            }
            if (!existing.exists) automatic.add(f);
          }
        }
      }
      localActivityHook?.assertOwner(uid);
      if (preferenceLock != null) {
        transaction.set(preferenceLock, {
          'targetType': 'internal_repeat_lock',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      for (final entry in counters.entries) {
        transaction.set(entry.key, entry.value);
      }
      for (final f in automatic) {
        transaction.set(
          user.collection(FirestoreCollections.favorites).doc(f.favoriteId),
          f.toMap(),
        );
      }
      if (replacement == null) {
        transaction.delete(ref);
      } else {
        final payload = replacement.toMap();
        if (!old.exists && localActivityHook != null) {
          payload.addAll(localActivityHook!.newSourceFields());
        }
        if (oldData?['createdAt'] != null) {
          payload['createdAt'] = oldData!['createdAt'];
        }
        transaction.set(ref, payload, SetOptions(merge: true));
      }
      for (final key in dates) {
        final log = logs[key]!;
        final patch = <String, dynamic>{
          ...totals[key]!,
          'dateKey': key,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (!log.exists &&
            key == SufraDateUtils.toDateKey(DateTime.now()) &&
            active != null) {
          patch.addAll({
            'calorieTarget': active.dailyCalorieTarget,
            'proteinTarget': active.proteinTarget,
            'carbsTarget': active.carbsTarget,
            'fatTarget': active.fatTarget,
          });
        }
        // Do not touch waterIntakeMl, timezone or other feature-owned fields.
        transaction.set(log.reference, patch, SetOptions(merge: true));
      }
    });
  }

  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.mealEntries);

    if (dateKey != null) {
      query = query.where('dateKey', isEqualTo: dateKey);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => MealEntryModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> upsertDailyLog(String uid, DailyLogModel dailyLog) async {
    final ref = _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.dailyLogs)
        .doc(dailyLog.dateKey);

    await ref.set(dailyLog.toMap(), SetOptions(merge: true));
  }

  @override
  Future<DailyLogModel?> getDailyLog(String uid, String dateKey) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.dailyLogs)
        .doc(dateKey)
        .get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return DailyLogModel.fromMap(snapshot.data()!);
  }

  @override
  Future<List<DailyLogModel>> getDailyLogs(String uid, {int limit = 30}) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.dailyLogs)
        .orderBy('dateKey', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => DailyLogModel.fromMap(doc.data()))
        .toList();
  }
}
