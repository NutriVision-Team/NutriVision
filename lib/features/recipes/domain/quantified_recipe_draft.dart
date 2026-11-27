import '../../meal_log/domain/catalog_meal_draft.dart';
import '../../meal_log/domain/food_portion.dart';

/// An explicit user construction, never a conversion of provider measures.
class QuantifiedRecipeDraft {
  QuantifiedRecipeDraft({
    required this.sourceId,
    required this.ingredientCount,
    required Map<int, FoodPortion> ingredients,
    required Set<int> excluded,
    required this.yieldServings,
    required this.servingsToLog,
  }) : ingredients = Map.unmodifiable(ingredients),
       excluded = Set.unmodifiable(excluded) {
    if (sourceId.isEmpty ||
        ingredientCount < 1 ||
        ingredientCount > 50 ||
        !yieldServings.isFinite ||
        yieldServings <= 0 ||
        yieldServings > 1000 ||
        !servingsToLog.isFinite ||
        servingsToLog <= 0 ||
        servingsToLog > yieldServings ||
        ingredients.keys.any((i) => i < 0 || i >= ingredientCount) ||
        excluded.any((i) => i < 0 || i >= ingredientCount) ||
        ingredients.keys.any(excluded.contains)) {
      throw ArgumentError('Invalid quantified recipe');
    }
  }
  final String sourceId;
  final int ingredientCount;
  final Map<int, FoodPortion> ingredients;
  final Set<int> excluded;
  final double yieldServings, servingsToLog;
  bool get complete =>
      ingredients.isNotEmpty &&
      ingredients.length + excluded.length == ingredientCount &&
      ingredients.values.every((p) => p.canSave);
  CatalogMealDraft? get meal {
    if (!complete) return null;
    try {
      return CatalogMealDraft([
        for (final i in (ingredients.keys.toList()..sort()))
          FoodPortion(
            ingredients[i]!.food,
            ingredients[i]!.grams * servingsToLog / yieldServings,
          ),
      ]);
    } on ArgumentError {
      return null;
    }
  }
}
