import '../../gamification/data/local_protected_ledger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../data/models/meal_plan_model.dart';

/// Persistence boundary for weekly meal plans. Widgets never touch
/// Firestore directly.
abstract class PlannerRepository {
  Future<MealPlanModel?> getPlan(String uid, String planId);
  Future<void> savePlan(String uid, MealPlanModel plan);
}

/// Stores plans under the existing `users/{uid}/meal_plans/{planId}` path
/// with the existing [MealPlanModel] document shape.
class FirestorePlannerRepository implements PlannerRepository {
  FirestorePlannerRepository(
    this._firestore, {
    this.assertActive,
    this.localActivityHook,
  });
  final LocalRecordedActivityHook? localActivityHook;
  final void Function(String uid)? assertActive;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _plans(String uid) {
    localActivityHook?.assertOwner(uid);
    assertActive?.call(uid);
    if (uid.isEmpty || uid.contains('/')) {
      throw ArgumentError.value(uid, 'uid', 'A valid owner id is required');
    }
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.mealPlans);
  }

  @override
  Future<MealPlanModel?> getPlan(String uid, String planId) async {
    final snapshot = await _plans(uid).doc(planId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return MealPlanModel.fromMap(snapshot.id, snapshot.data()!);
  }

  @override
  Future<void> savePlan(String uid, MealPlanModel plan) async {
    if (plan.planId.isEmpty || plan.planId.contains('/')) {
      throw ArgumentError.value(plan.planId, 'plan.planId');
    }
    if (plan.endDate.isBefore(plan.startDate)) {
      throw ArgumentError.value(plan.endDate, 'plan.endDate');
    }
    if (!plan.dailyCalorieTarget.isFinite || plan.dailyCalorieTarget <= 0) {
      throw ArgumentError.value(plan.dailyCalorieTarget);
    }
    for (final meal in plan.meals) {
      if (meal.mealId.isEmpty ||
          !meal.calories.isFinite ||
          meal.calories < 0 ||
          meal.foods.any((id) => id.isEmpty || id.contains('/'))) {
        throw ArgumentError.value(meal.mealId, 'meal.mealId');
      }
    }
    for (final meal in plan.meals) {
      for (final portion in meal.foodPortions ?? <MealPlanFoodPortion>[]) {
        if (!meal.foods.contains(portion.foodId) ||
            !portion.grams.isFinite ||
            portion.grams <= 0 ||
            portion.grams > 10000) {
          throw const FormatException('Invalid planned portion');
        }
      }
    }
    final ref = _plans(uid).doc(plan.planId);
    await localActivityHook?.beforeSourceSave(uid, 'plan', plan.planId);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      final payload = plan.toMap();
      if (!existing.exists && localActivityHook != null) {
        payload.addAll(localActivityHook!.newSourceFields());
      }
      // An update must not move the original creation timestamp.
      final createdAt = existing.data()?['createdAt'];
      if (createdAt != null) {
        payload['createdAt'] = createdAt;
      }
      payload['updatedAt'] = FieldValue.serverTimestamp();
      localActivityHook?.assertOwner(uid);
      assertActive?.call(uid);
      transaction.set(ref, payload, SetOptions(merge: true));
    });
    await localActivityHook?.sourceSaved(uid, 'plan', plan.planId);
  }
}
