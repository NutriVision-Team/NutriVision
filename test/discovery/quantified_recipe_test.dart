import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/recipes/domain/quantified_recipe_draft.dart';
import 'package:sufradepi/features/recipes/domain/ingredient_recipe_matcher.dart';
import 'package:sufradepi/features/recipes/domain/recipe_catalog_repository.dart';
import 'package:sufradepi/features/recipes/data/datasources/local_recipe_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const f = FoodCatalogModel(
    foodId: 'rice',
    name: 'rice',
    source: 'fixture',
    nutritionPer100g: {
      'calories': 100,
      'protein': 2,
      'carbohydrates': 20,
      'fat': null,
    },
  );
  test(
    'reviewed whole-recipe grams scale by explicit yield, unknown nutrient remains null',
    () {
      final d = QuantifiedRecipeDraft(
        sourceId: 'recipe',
        ingredientCount: 2,
        ingredients: {0: FoodPortion(f, 400)},
        excluded: {1},
        yieldServings: 4,
        servingsToLog: 2,
      );
      expect(d.meal!.portions.single.grams, 200);
      expect(d.meal!.totals!.energyKcal, 200);
      expect(d.meal!.totals!.proteinG, 4);
      expect(d.meal!.totals!.fatG, isNull);
      final incomplete = QuantifiedRecipeDraft(
        sourceId: 'recipe',
        ingredientCount: 2,
        ingredients: {0: FoodPortion(f, 400)},
        excluded: {},
        yieldServings: 4,
        servingsToLog: 2,
      );
      expect(incomplete.meal, isNull);
      expect(
        () => QuantifiedRecipeDraft(
          sourceId: 'r',
          ingredientCount: 1,
          ingredients: {0: FoodPortion(f, 100)},
          excluded: {0},
          yieldServings: 1,
          servingsToLog: 1,
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'strict recipe constraints never accept missing source metadata',
    () async {
      final recipes = await RecipeCatalogRepository().getAll();
      expect(
        IngredientRecipeMatcher.match(
          recipes,
          const RecipeRequest(
            mealType: 'lunch',
            ingredients: ['rice'],
            requireMealType: true,
            maxCalories: 600,
            maxCookingMinutes: 30,
          ),
        ),
        isEmpty,
      );
      final r = LocalRecipeRecord(
        id: 'fixture',
        sourceMealId: 'fixture',
        nameAr: null,
        nameEn: 'rice',
        tags: const [],
        ingredients: const [LocalRecipeIngredient(name: 'rice')],
        instructions: const [],
        nutritionStatus: 'fixture',
        source: const LocalRecipeSource(
          provider: 'fixture',
          mealId: 'fixture',
          licenseNote: 'fixture',
          url: 'fixture',
        ),
        mealTypes: const ['lunch'],
        caloriesPerServing: 500,
        cookingMinutes: 20,
      );
      expect(
        IngredientRecipeMatcher.match(
          [r],
          const RecipeRequest(
            mealType: 'lunch',
            ingredients: ['rice'],
            requireMealType: true,
            maxCalories: 600,
            maxCookingMinutes: 30,
          ),
        ),
        hasLength(1),
      );
      expect(
        IngredientRecipeMatcher.match(
          [r],
          const RecipeRequest(
            mealType: 'dinner',
            ingredients: ['rice'],
            requireMealType: true,
          ),
        ),
        isEmpty,
      );
    },
  );
}
