import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/features/camera_analysis/domain/food_recognition_provider.dart';
import 'package:sufradepi/features/meal_log/domain/catalog_meal_draft.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/meal_log/domain/meal_review_input.dart';
import 'package:sufradepi/features/meal_log/presentation/cubit/meal_save_cubit.dart';
import '../../support/memory_firestore.dart';

void main() {
  test(
    'historical confirmed food migration triggers sixth without rewriting source records',
    () async {
      final store = MemoryFirestore();
      final repo = FirestoreNutritionRepository(store);
      final food = FoodCatalogModel(
        foodId: 'migrate',
        name: 'Migrated food',
        source: 'Synthetic',
        nutritionPer100g: const {'calories': 100},
      );
      for (var i = 0; i < 5; i++) {
        final meal = FoodPortion(food, 100).toMeal(
          uid: 'u1',
          id: 'old$i',
          at: DateTime(2026, 10, 23, 12, i),
          mealType: 'lunch',
        );
        store.seed('users/u1/meal_entries/old$i', store.resolve(meal.toMap()));
      }
      final meal = FoodPortion(food, 100).toMeal(
        uid: 'u1',
        id: 'new6',
        at: DateTime(2026, 11, 23, 12),
        mealType: 'lunch',
      );
      await repo.saveMealEntry('u1', meal);
      expect(
        store.documents['users/u1/favorites/food_migrate']?['targetId'],
        'migrate',
      );
      expect(
        store.documents['users/u1/favorites/_repeat_migrate']?['count'],
        6,
      );
      expect(
        store.documents['users/u1/meal_entries/old0']?['title'],
        'Migrated food',
      );
    },
  );

  test(
    'food counter saturates and removal survives seventh addition',
    () async {
      final store = MemoryFirestore();
      final repo = FirestoreNutritionRepository(store);
      final food = FoodCatalogModel(
        foodId: 'x',
        name: 'X',
        source: 'Synthetic',
        nutritionPer100g: const {'calories': 100},
      );
      for (var i = 1; i <= 7; i++) {
        await repo.saveMealEntry(
          'u1',
          FoodPortion(food, 100).toMeal(
            uid: 'u1',
            id: 'x$i',
            at: DateTime(2026, 11, 23, 12, i),
            mealType: 'lunch',
          ),
        );
        if (i == 6) store.documents.remove('users/u1/favorites/food_x');
      }
      expect(store.documents['users/u1/favorites/_repeat_x']!['count'], 6);
      expect(store.documents.containsKey('users/u1/favorites/food_x'), false);
    },
  );

  test(
    'sixth confirmed food addition creates persistent favorite once, not fifth or edited retry',
    () async {
      final store = MemoryFirestore();
      final repository = FirestoreNutritionRepository(store);
      final selected = FoodCatalogModel(
        foodId: 'verified-food',
        name: 'Catalog rice',
        source: 'Synthetic catalog',
        nutritionPer100g: const {'calories': 130, 'protein': null},
      );
      for (var i = 1; i <= 6; i++) {
        final meal = FoodPortion(selected, 150).toMeal(
          uid: 'u1',
          id: 'm$i',
          at: DateTime(2026, 11, 23, 12, i),
          mealType: 'lunch',
        );
        await repository.saveMealEntry('u1', meal);
        expect(
          store.documents.containsKey('users/u1/favorites/food_verified-food'),
          i == 6,
        );
        if (i == 6) await repository.saveMealEntry('u1', meal);
      }
      final favorite =
          store.documents['users/u1/favorites/food_verified-food']!;
      expect(favorite['targetId'], 'verified-food');
      expect(favorite['targetType'], 'food');
      expect(
        store.documents.keys.where(
          (k) => k.startsWith('users/u1/favorites/food_'),
        ),
        hasLength(1),
      );
      expect(store.documents.keys.any((k) => k.startsWith('users/u2/')), false);
    },
  );

  test(
    'reviewed photo draft persists catalog nutrition and photo provenance once',
    () async {
      final proposed = FoodRecognitionResult.parse(
        '{"requiresUserReview":true,"items":[{"name":"visual food","calories":9999,"protein":999,"suggestedPortionGrams":900}]}',
        catalogIds: {},
      );
      expect(proposed.requiresUserReview, isTrue);
      // A separately selected catalog food and explicit reviewed grams replace
      // the image proposal. The model's numeric fields never enter this draft.
      final selected = FoodCatalogModel(
        foodId: 'verified-food',
        name: 'Catalog rice',
        source: 'synthetic verified catalog source',
        nutritionPer100g: const {'calories': 130, 'protein': 2.5},
      );
      final input = MealReviewInput(
        draft: CatalogMealDraft([FoodPortion(selected, 150)]),
        mealType: 'dinner',
        inputMethod: 'photo',
        notes: 'Reviewed manually',
      );
      final store = MemoryFirestore();
      final repository = FirestoreNutritionRepository(store);
      final save = MealSaveCubit(
        draft: input.draft,
        repository: repository,
        uid: 'u1',
        currentUid: () => 'u1',
        mealType: input.mealType,
        notes: input.notes,
        inputMethod: input.inputMethod,
        clock: () => DateTime(2026, 11, 23, 12),
      );
      addTearDown(save.close);
      expect(store.documents, isEmpty);
      await save.save();
      await save.save();
      expect(save.state, MealSaveStatus.saved);
      final meals = await repository.getMealEntries('u1');
      expect(meals, hasLength(1));
      final meal = meals.single;
      expect(meal.inputMethod, 'photo');
      expect(meal.mealType, 'dinner');
      expect(meal.notes, 'Reviewed manually');
      expect(meal.totalCalories, 195);
      expect(meal.totalProtein, 3.75);
      expect(meal.totalFiber, isNull);
      expect(meal.items.single.foodId, 'verified-food');
      expect(meal.items.single.weightInGrams, 150);
      expect(meal.items.single.confidence, isNull);
      final daily = await repository.getDailyLog('u1', '2026-11-23');
      expect(daily!.totalCalories, 195);
      expect(daily.mealCount, 1);
      expect(
        store.documents.keys.every((p) => p.startsWith('users/u1/')),
        isTrue,
      );
    },
  );
}
