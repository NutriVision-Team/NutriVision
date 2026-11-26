import '../../../core/utils/nutrition_values.dart';
import '../../../data/models/meal_entry_model.dart';
import '../../meal_logging/domain/food_nutrition_calculator.dart'
    as calculation;
import 'food_portion.dart';

/// User-reviewed catalog ingredients. This type never accepts AI nutrition.
/// Its quantities refer to the same catalog records and preparation states.
class CatalogMealDraft {
  CatalogMealDraft(Iterable<FoodPortion> values, {String? imageUrl})
    : portions = List.unmodifiable(values),
      imageUrl = _safeImage(imageUrl) {
    if (portions.length > 50) throw ArgumentError('Too many ingredients');
  }
  final List<FoodPortion> portions;

  /// Source product image only. Edits that replace ingredients create a fresh
  /// draft without an image, avoiding a stale product photo on another food.
  final String? imageUrl;
  static String? _safeImage(String? value) {
    final uri = value == null ? null : Uri.tryParse(value);
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? value
        : null;
  }

  bool get canSave => portions.isNotEmpty && portions.every((p) => p.canSave);

  calculation.NutritionTotals? get totals {
    if (!canSave) return null;
    double? nutrient(FoodPortion p, String key) =>
        knownNutrient(p.food.nutritionPer100g?[key]);
    final result = const calculation.FoodNutritionCalculator().calculate([
      for (final p in portions)
        calculation.FoodPortion(
          foodId: p.food.foodId,
          quantityGrams: p.grams,
          per100g: calculation.NutrientsPer100g(
            energyKcal: nutrient(p, 'calories')!,
            proteinG: nutrient(p, 'protein'),
            carbohydrateG: nutrient(p, 'carbohydrates'),
            fatG: nutrient(p, 'fat'),
            fiberG: nutrient(p, 'fiber'),
            sugarsG: nutrient(p, 'sugar'),
            sodiumMg: nutrient(p, 'sodium'),
          ),
        ),
    ]);
    if (!result.energyKcal.isFinite) return null;
    return calculation.NutritionTotals(
      energyKcal: result.energyKcal,
      proteinG: knownNutrient(result.proteinG),
      fatG: knownNutrient(result.fatG),
      carbohydrateG: knownNutrient(result.carbohydrateG),
      fiberG: knownNutrient(result.fiberG),
      sugarsG: knownNutrient(result.sugarsG),
      sodiumMg: knownNutrient(result.sodiumMg),
      isComplete: result.isComplete,
    );
  }

  MealEntryModel toMeal({
    required String uid,
    required String id,
    required DateTime at,
    required String mealType,
    String? title,
    String? notes,
    String inputMethod = 'catalog',
  }) {
    final total = totals;
    final name = (title ?? portions.map((p) => p.food.name).join(' + ')).trim();
    if (total == null ||
        !const {'catalog', 'barcode', 'photo', 'voice'}.contains(inputMethod) ||
        uid.isEmpty ||
        id.isEmpty ||
        name.isEmpty ||
        (notes?.length ?? 0) > 1000 ||
        !const [
          'breakfast',
          'lunch',
          'dinner',
          'snack',
          'suhoor',
          'iftar',
        ].contains(mealType)) {
      throw StateError('Cannot save an unconfirmed or invalid meal draft');
    }
    final records = [
      for (final p in portions)
        p.toMeal(uid: uid, id: id, at: at, mealType: mealType),
    ];
    return MealEntryModel(
      mealId: id,
      userId: uid,
      dateKey: records.first.dateKey,
      consumedAt: at,
      mealType: mealType,
      inputMethod: inputMethod,
      title: name.length > 120 ? name.substring(0, 120) : name,
      items: List.unmodifiable(records.expand((m) => m.items)),
      totalCalories: total.energyKcal,
      totalProtein: total.proteinG,
      totalCarbs: total.carbohydrateG,
      totalFat: total.fatG,
      totalFiber: total.fiberG,
      totalSugar: total.sugarsG,
      totalSodium: total.sodiumMg,
      // Confirmed means the user saved this reviewed record, not that photo
      // quantities were measured. Photo uncertainty is retained by inputMethod.
      analysisStatus: 'confirmed',
      imageUrl: imageUrl,
      nutritionSource: portions.map((p) => p.food.source!).toSet().join('; '),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    );
  }
}

/// Local navigation only. Never carries the photo or sends without review.
class OwnedReviewedMeal {
  const OwnedReviewedMeal(this.uid, this.draft);
  final String uid;
  final CatalogMealDraft draft;
}
