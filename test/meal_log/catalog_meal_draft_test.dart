import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/meal_log/domain/catalog_meal_draft.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/meal_log/presentation/cubit/meal_save_cubit.dart';
import 'catalog_flow_test.dart' show catalog;
import 'recent_meals_cubit_test.dart' show RecordingNutrition;

void main() {
  test(
    'multiple confirmed ingredients use the deterministic calculator and retain each source',
    () {
      final draft = CatalogMealDraft([
        FoodPortion(catalog(), 150),
        FoodPortion(
          catalog(
            source: 'second test source',
            nutrition: {'calories': 100, 'protein': null, 'fat': 5},
          ),
          200,
        ),
      ]);
      expect(draft.totals!.energyKcal, 500);
      expect(draft.totals!.proteinG, isNull);
      expect(draft.totals!.fatG, 22);
      final saved = draft.toMeal(
        uid: 'u1',
        id: 'meal',
        at: DateTime(2026, 11, 22),
        mealType: 'lunch',
        title: 'My lunch',
        notes: ' user note ',
      );
      expect(saved.items, hasLength(2));
      expect(saved.items[1].dataSource, 'second test source');
      expect(saved.totalCalories, 500);
      expect(saved.totalProtein, isNull);
      expect(saved.notes, 'user note');
      expect(saved.title, 'My lunch');
    },
  );
  test('empty, incomplete and excessive drafts cannot be persisted', () {
    expect(CatalogMealDraft([]).canSave, isFalse);
    final incomplete = CatalogMealDraft([
      FoodPortion(catalog(nutrition: {}), 100),
    ]);
    expect(incomplete.totals, isNull);
    expect(
      () => incomplete.toMeal(
        uid: 'u1',
        id: 'x',
        at: DateTime(2026),
        mealType: 'lunch',
      ),
      throwsStateError,
    );
    expect(
      () => CatalogMealDraft(
        List.generate(51, (_) => FoodPortion(catalog(), 100)),
      ),
      throwsArgumentError,
    );
  });
  test('multi-item save retries the exact ID and submitted contents', () async {
    final repo = RecordingNutrition()..failNext = true;
    final c = MealSaveCubit(
      draft: CatalogMealDraft([
        FoodPortion(catalog(), 100),
        FoodPortion(catalog(), 50),
      ]),
      title: 'Lunch',
      notes: 'Note',
      repository: repo,
      uid: 'u1',
      currentUid: () => 'u1',
      mealType: 'lunch',
    );
    await c.save();
    expect(c.state, MealSaveStatus.failure);
    await c.save();
    expect(c.state, MealSaveStatus.saved);
    expect(repo.writes[0].mealId, repo.writes[1].mealId);
    expect(repo.writes.last.items, hasLength(2));
    expect(repo.writes.last.totalCalories, 300);
    expect(repo.writes.last.notes, 'Note');
    await c.close();
  });
  test(
    'invalid meal type becomes a save failure, not an uncaught exception',
    () async {
      final repo = RecordingNutrition();
      final c = MealSaveCubit(
        portion: FoodPortion(catalog(), 100),
        repository: repo,
        uid: 'u1',
        currentUid: () => 'u1',
        mealType: 'invalid',
      );
      await c.save();
      expect(c.state, MealSaveStatus.failure);
      expect(repo.writes, isEmpty);
      await c.close();
    },
  );
  test('overflowed scaled energy is not considered measured energy', () {
    expect(
      FoodPortion(catalog(nutrition: {'calories': 1e308}), 10000).canSave,
      isFalse,
    );
  });
}
