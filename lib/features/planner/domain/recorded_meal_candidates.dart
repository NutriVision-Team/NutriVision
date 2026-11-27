import '../../../../data/models/meal_entry_model.dart';
import '../../../../data/models/meal_plan_model.dart';
import '../../alternatives/domain/food_preference_filter.dart';
import '../../food_catalog/data/datasources/local_food_data_source.dart';

/// Previously reviewed catalog-weight entries only, never image estimates or
/// recipe household-measure conversions. A match is not a balanced-diet claim.
abstract final class RecordedMealCandidates {
  static List<MealPlanMealModel> build({
    required String ownerUid,
    required DateTime asOf,
    required List<MealEntryModel> records,
    required List<LocalFoodRecord> catalog,
    List<String> allergies = const [],
    List<String> exclusions = const [],
    List<String> dietaryPreferences = const [],
  }) {
    final byId = {for (final f in catalog) f.id: f};
    final result = <MealPlanMealModel>[];
    final seen = <String>{};
    for (final m in records) {
      if (m.userId != ownerUid ||
          m.inputMethod != 'catalog' ||
          m.analysisStatus != 'confirmed' ||
          !m.totalCalories.isFinite ||
          m.totalCalories <= 0 ||
          m.consumedAt.isAfter(asOf) ||
          asOf.difference(m.consumedAt).inDays > 90 ||
          !const [
            'breakfast',
            'lunch',
            'dinner',
            'snack',
          ].contains(m.mealType) ||
          m.items.length < 2 ||
          m.items.length > 12) {
        continue;
      }
      final portions = <MealPlanFoodPortion>[];
      final categories = <String>{};
      var energy = 0.0, valid = true;
      for (final item in m.items) {
        final f = byId[item.foodId];
        if (f == null ||
            !item.calories.isFinite ||
            item.calories < 0 ||
            item.dataSource.trim().isEmpty ||
            !item.weightInGrams.isFinite ||
            item.weightInGrams <= 0 ||
            item.weightInGrams > 500 ||
            item.unit != 'g' ||
            f.nutrientsPer100g.energyKcal == null ||
            !FoodPreferenceFilter.allows(
              f,
              allergies: allergies,
              dietaryPreferences: dietaryPreferences,
            )) {
          valid = false;
          break;
        }
        final name = FoodPreferenceFilter.normalize(
          [f.id, f.nameAr, f.nameEn, ...f.aliases].join(' '),
        );
        if (exclusions.any(
              (t) =>
                  t.trim().isNotEmpty &&
                  name.contains(FoodPreferenceFilter.normalize(t)),
            ) ||
            (const [
                  'meat',
                  'poultry',
                  'fish',
                  'eggs',
                  'legumes',
                  'grains',
                ].contains(f.category) &&
                !const [
                  'cooked',
                  'prepared',
                  'canned',
                ].contains(f.foodState))) {
          valid = false;
          break;
        }
        final kcal = item.weightInGrams / 100 * f.nutrientsPer100g.energyKcal!;
        if (!kcal.isFinite || (kcal - item.calories).abs() > 1) {
          valid = false;
          break;
        }
        energy += kcal;
        categories.add(f.category);
        portions.add(
          MealPlanFoodPortion(foodId: f.id, grams: item.weightInGrams),
        );
      }
      if (!valid ||
          categories.length < 2 ||
          energy <= 0 ||
          (energy - m.totalCalories).abs() > 2 ||
          portions.fold<double>(0, (s, p) => s + p.grams) > 1200) {
        continue;
      }
      // Prevent a measured condiment-only entry from being presented as a meal.
      if (m.mealType != 'snack' &&
          (!categories.contains('grains') ||
              !categories.any(
                const {
                  'legumes',
                  'dairy',
                  'poultry',
                  'meat',
                  'fish',
                  'eggs',
                }.contains,
              ))) {
        continue;
      }
      final signature = portions.map((p) => '${p.foodId}:${p.grams}').join('|');
      if (!seen.add('${m.mealType}:$signature')) continue;
      result.add(
        MealPlanMealModel(
          mealId: m.mealId,
          title: portions.map((p) => byId[p.foodId]!.nameAr).join(' و'),
          mealType: m.mealType,
          calories: energy,
          foods: portions.map((p) => p.foodId).toList(),
          foodPortions: portions,
        ),
      );
    }
    return result;
  }
}
