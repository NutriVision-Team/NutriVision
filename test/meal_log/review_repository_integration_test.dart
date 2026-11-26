import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/features/meal_log/domain/catalog_meal_draft.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/meal_log/domain/meal_budget_preview.dart';
import 'package:sufradepi/features/meal_log/presentation/cubit/meal_save_cubit.dart';
import '../support/memory_firestore.dart';

void main() {
  const food = FoodCatalogModel(
    foodId: 'off_fixture',
    name: 'Fixture pack',
    source: 'Fixture nutrition',
    nutritionPer100g: {'calories': 539.0, 'protein': 6.3},
  );
  test(
    'real saver and repository preserve reviewed pack image, source and totals across repository restart without duplicate retry',
    () async {
      final db = MemoryFirestore();
      db.seed('users/u/daily_logs/2026-11-24', {
        'dateKey': '2026-11-24',
        'waterIntakeMl': 750,
        'calorieTarget': 2397,
      });
      final draft = CatalogMealDraft([
        FoodPortion(food, 30),
      ], imageUrl: 'https://example.test/fixture-pack.jpg');
      final budget = MealBudgetPreview.calculate(
        target: 2397,
        consumed: 0,
        meal: draft.totals!.energyKcal,
      )!;
      final c = MealSaveCubit(
        draft: draft,
        inputMethod: 'barcode',
        repository: FirestoreNutritionRepository(db),
        uid: 'u',
        currentUid: () => 'u',
        mealType: 'snack',
        clock: () => DateTime(2026, 11, 24, 12),
      );
      db.failAfterCommit = true;
      await c.save();
      expect(c.state, MealSaveStatus.failure);
      await c.save();
      expect(c.state, MealSaveStatus.saved);
      await c.close();
      final restarted = FirestoreNutritionRepository(db);
      final records = await restarted.getMealEntries(
        'u',
        dateKey: '2026-11-24',
      );
      expect(records, hasLength(1));
      expect(records.single.inputMethod, 'barcode');
      expect(records.single.imageUrl, draft.imageUrl);
      expect(records.single.items.single.dataSource, 'Fixture nutrition');
      expect(records.single.items.single.fiber, isNull);
      final day = await restarted.getDailyLog('u', '2026-11-24');
      expect(day!.totalCalories, closeTo(161.7, .0001));
      expect(day.waterIntakeMl, 750);
      expect(
        day.calorieTarget - day.totalCalories!,
        closeTo(budget.after, .0001),
      );
      expect(await restarted.getMealEntries('other'), isEmpty);
    },
  );
  test(
    'source image rejects unsafe URLs and is absent from a replaced ingredient draft',
    () {
      final portions = [FoodPortion(food, 30)];
      expect(
        CatalogMealDraft(portions, imageUrl: 'javascript:alert(1)').imageUrl,
        isNull,
      );
      expect(
        CatalogMealDraft(
          portions,
          imageUrl: 'https://user:pass@example.test/pack.jpg',
        ).imageUrl,
        isNull,
      );
      final original = CatalogMealDraft(
        portions,
        imageUrl: 'https://example.test/pack.jpg',
      );
      final replaced = CatalogMealDraft(original.portions);
      expect(replaced.imageUrl, isNull);
    },
  );
}
