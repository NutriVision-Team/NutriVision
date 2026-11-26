import '../../../../data/models/food_catalog_model.dart';
import '../../../../data/repositories/food_repository.dart';
import '../../meal_log/domain/food_portion.dart';
import '../../meal_log/domain/catalog_meal_draft.dart';
import '../../recipes/domain/recipe_catalog_repository.dart';
import '../../recipes/data/datasources/local_recipe_data_source.dart';

/// Typed read/calculation tools. No provider, database query or write capability.
class CoachCatalogTools {
  const CoachCatalogTools({required this.foods, required this.recipes});
  final FoodRepository foods;
  final RecipeCatalogRepository recipes;
  Future<List<FoodCatalogModel>> searchFoods(String query) async {
    final q = query.trim();
    if (q.isEmpty || q.length > 100) return [];
    return (await foods.searchFood(q)).take(8).toList(growable: false);
  }

  Future<List<LocalRecipeRecord>> searchRecipes(String query) async {
    if (query.trim().isEmpty || query.length > 100) return [];
    return RecipeCatalogRepository.filter(
      await recipes.getAll(),
      query,
    ).take(5).toList(growable: false);
  }

  /// Explicit record IDs and weighed grams only, never model-made nutrition.
  Future<CatalogMealDraft> calculate(Map<String, double> weighedFoods) async {
    if (weighedFoods.isEmpty || weighedFoods.length > 20) {
      throw ArgumentError('Choose and weigh ingredients');
    }
    final portions = <FoodPortion>[];
    for (final item in weighedFoods.entries) {
      final food = await foods.getFoodById(item.key);
      if (food == null) throw StateError('Unknown catalog food');
      portions.add(FoodPortion(food, item.value));
    }
    final draft = CatalogMealDraft(portions);
    if (!draft.canSave || draft.totals == null) {
      throw StateError('Missing source nutrition');
    }
    return draft;
  }
}
