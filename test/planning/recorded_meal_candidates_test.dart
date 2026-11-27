import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/meal_log/domain/catalog_meal_draft.dart';
import 'package:sufradepi/features/planner/domain/recorded_meal_candidates.dart';
import 'package:sufradepi/features/planner/domain/weekly_plan_generator.dart';
import 'plan_generator_test.dart' as f;

void main() {
  final at = DateTime(2026, 11, 24, 12);
  final catalog = f.catalog();
  CatalogMealDraft draft() => CatalogMealDraft([
    FoodPortion(
      const FoodCatalogModel(
        foodId: 'rice1',
        name: 'bread',
        source: 'fixture',
        nutritionPer100g: {'calories': 359.0},
      ),
      100,
    ),
    FoodPortion(
      const FoodCatalogModel(
        foodId: 'lentil1',
        name: 'lentil',
        source: 'fixture',
        nutritionPer100g: {'calories': 360.0},
      ),
      100,
    ),
    FoodPortion(
      const FoodCatalogModel(
        foodId: 'spinach1',
        name: 'cucumber',
        source: 'fixture',
        nutritionPer100g: {'calories': 25.0},
      ),
      100,
    ),
  ]);
  test('confirmed weighed owner meal reused unchanged and recalculated', () {
    final record = draft().toMeal(
      uid: 'u1',
      id: 'm',
      at: at,
      mealType: 'lunch',
    );
    final candidates = RecordedMealCandidates.build(
      ownerUid: 'u1',
      asOf: at,
      records: [record],
      catalog: catalog,
    );
    expect(candidates.length, 1);
    expect(candidates.single.calories, 744);
    expect(candidates.single.foodPortions!.map((p) => p.grams), [
      100,
      100,
      100,
    ]);
    final plan = WeeklyPlanGenerator(catalog: catalog).generate(
      weekStart: DateTime(2026, 11, 21),
      dailyCalorieTarget: 2100,
      seed: 1,
      recordedMeals: candidates,
    );
    // Limited reuse, no false week-long diversity from one stored meal.
    expect(
      plan.meals
          .where((m) => m.mealType == 'lunch' && m.calories == 744)
          .length,
      2,
    );
  });
  test('reject wrong owner future old photo and dietary exclusions', () {
    final entries = [
      draft().toMeal(uid: 'other', id: 'a', at: at, mealType: 'lunch'),
      draft().toMeal(
        uid: 'u1',
        id: 'b',
        at: at.add(const Duration(days: 1)),
        mealType: 'lunch',
      ),
      draft().toMeal(
        uid: 'u1',
        id: 'c',
        at: at.subtract(const Duration(days: 91)),
        mealType: 'lunch',
      ),
      draft().toMeal(
        uid: 'u1',
        id: 'd',
        at: at,
        mealType: 'lunch',
        inputMethod: 'photo',
      ),
    ];
    expect(
      RecordedMealCandidates.build(
        ownerUid: 'u1',
        asOf: at,
        records: entries,
        catalog: catalog,
      ),
      isEmpty,
    );
    final valid = draft().toMeal(uid: 'u1', id: 'e', at: at, mealType: 'lunch');
    expect(
      RecordedMealCandidates.build(
        ownerUid: 'u1',
        asOf: at,
        records: [valid],
        catalog: catalog,
        exclusions: ['lentil'],
      ),
      isEmpty,
    );
    expect(
      RecordedMealCandidates.build(
        ownerUid: 'u1',
        asOf: at,
        records: [valid],
        catalog: catalog,
        allergies: ['wheat'],
      ),
      isEmpty,
    );
  });
}
