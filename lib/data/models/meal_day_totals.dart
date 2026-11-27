import '../../core/utils/nutrition_values.dart';
import 'meal_entry_model.dart';

/// Nutrition recorded on a date, not a claim about unrecorded food intake.
/// A missing nutrient in any entry makes that day's nutrient total unknown.
Map<String, dynamic> mealDayTotals(Iterable<MealEntryModel> input) {
  final meals = input.toList(growable: false);
  return {
    'mealCount': meals.length,
    'totalCalories': meals.fold<double>(0, (sum, m) => sum + m.totalCalories),
    'totalProtein': sumKnownNutrients(meals.map((m) => m.totalProtein)),
    'totalCarbs': sumKnownNutrients(meals.map((m) => m.totalCarbs)),
    'totalFat': sumKnownNutrients(meals.map((m) => m.totalFat)),
    'totalFiber': sumKnownNutrients(meals.map((m) => m.totalFiber)),
    'totalSugar': sumKnownNutrients(meals.map((m) => m.totalSugar)),
    'totalSodium': sumKnownNutrients(meals.map((m) => m.totalSodium)),
  };
}
