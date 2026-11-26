import '../../../core/utils/date_utils.dart';
import '../../../data/models/food_catalog_model.dart';
import '../../../data/models/meal_entry_model.dart';

/// Catalog arithmetic only. AI and design sample numbers are not nutrition
/// sources. Missing values remain null, including when scaling portions.
class FoodPortion {
  FoodPortion(this.food, this.grams) {
    if (!grams.isFinite || grams <= 0 || grams > 10000) {
      throw ArgumentError.value(grams, 'grams', 'Must be between 0 and 10000');
    }
  }
  final FoodCatalogModel food;
  final double grams;
  static const nutrients = [
    'calories',
    'protein',
    'carbohydrates',
    'fat',
    'fiber',
    'sugar',
    'sodium',
  ];

  double? amount(String key) {
    final raw = food.nutritionPer100g?[key];
    if (raw is! num || !raw.isFinite || raw < 0) return null;
    final result = raw.toDouble() * grams / 100;
    return result.isFinite ? result : null;
  }

  bool get canSave =>
      food.foodId.isNotEmpty &&
      food.name.trim().isNotEmpty &&
      (food.source?.trim().isNotEmpty ?? false) &&
      amount('calories') != null;

  MealEntryModel toMeal({
    required String uid,
    required String id,
    required DateTime at,
    required String mealType,
  }) {
    if (!canSave || uid.isEmpty || id.isEmpty) {
      throw StateError('Cannot persist incomplete catalog nutrition');
    }
    final item = MealItemModel(
      foodId: food.foodId,
      foodName: food.name,
      quantity: grams,
      unit: 'g',
      weightInGrams: grams,
      calories: amount('calories')!,
      protein: amount('protein'),
      carbohydrates: amount('carbohydrates'),
      fat: amount('fat'),
      fiber: amount('fiber'),
      sugar: amount('sugar'),
      sodium: amount('sodium'),
      dataSource: food.source!,
      confidence: null,
    );
    return MealEntryModel(
      mealId: id,
      userId: uid,
      dateKey: SufraDateUtils.toDateKey(at),
      consumedAt: at,
      mealType: mealType,
      inputMethod: 'catalog',
      title: food.name,
      items: [item],
      totalCalories: item.calories,
      totalProtein: item.protein,
      totalCarbs: item.carbohydrates,
      totalFat: item.fat,
      totalFiber: item.fiber,
      totalSugar: item.sugar,
      totalSodium: item.sodium,
      analysisStatus: 'confirmed',
      nutritionSource: food.source,
    );
  }
}
