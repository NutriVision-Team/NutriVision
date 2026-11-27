import '../../../../data/models/meal_plan_model.dart';
import '../../food_catalog/data/datasources/local_food_data_source.dart';

/// Authored assembly choices for cooked/ready-to-eat catalog components.
/// Discrete ordinary portion multiples, not a balanced-diet certification or
/// optimisation of medical nutrients. No invented household conversions.
abstract final class AssemblyPortions {
  static MealPlanMealModel? compose({
    required List<LocalFoodRecord> picked,
    required List<LocalFoodRecord> eligibleExtras,
    required String mealId,
    required String mealType,
    required String dateKey,
    required double targetKcal,
  }) {
    if (picked.isEmpty) return null;
    List<double> quantities(LocalFoodRecord f) {
      final n = f.nameEn.toLowerCase();
      switch (f.category) {
        case 'dairy':
          if (n.contains('cottage')) return [100, 150];
          if (n.contains('cheese')) return [30];
          return [125, 150, 200, 250];
        case 'grains':
          return n.contains('bread') ? [35, 70, 105] : [75, 150, 225, 300];
        case 'legumes':
          return [75, 150, 225];
        case 'poultry':
        case 'meat':
          return [90, 135];
        case 'fish':
          return [140];
        case 'eggs':
          return [120];
        case 'fruits':
          return f.foodState == 'dried' ? [30] : [80, 160];
        case 'vegetables':
          return [80, 160];
        case 'nuts_seeds':
          return [15, 30];
        default:
          return [];
      }
    }

    final options = picked.map(quantities).toList();
    if (options.any((v) => v.isEmpty)) return null;
    // Only a measured small oil addition to a savoury main, never calorie
    // padding with butter, dressings, unknown sauces or oil in a fruit snack.
    final oil = (mealType == 'lunch' || mealType == 'dinner')
        ? eligibleExtras.where((f) => f.id == 'usda_sr_171413').firstOrNull
        : null;
    final nuts = mealType == 'breakfast'
        ? eligibleExtras
              .where((f) => f.category == 'nuts_seeds' && f.foodState == 'raw')
              .firstOrNull
        : null;
    final extra = oil ?? nuts;
    final extraOptions = oil != null
        ? [0.0, 5.0, 10.0]
        : nuts != null
        ? [0.0, 15.0]
        : [0.0];
    var bestDistance = double.infinity;
    List<double>? best;
    var bestExtra = 0.0;
    void visit(int index, List<double> grams, double kcal) {
      if (index < picked.length) {
        for (final q in options[index]) {
          visit(index + 1, [
            ...grams,
            q,
          ], kcal + q / 100 * picked[index].nutrientsPer100g.energyKcal!);
        }
        return;
      }
      for (final x in extraOptions) {
        final energy =
            kcal +
            (extra == null ? 0 : x / 100 * extra.nutrientsPer100g.energyKcal!);
        final mass = grams.fold<double>(0, (s, g) => s + g) + x;
        if (mass > 850) continue;
        final distance = (energy - targetKcal).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          best = grams;
          bestExtra = x;
        }
      }
    }

    visit(0, [], 0);
    if (best == null) return null;
    final foods = [...picked, if (bestExtra > 0) extra!];
    final grams = [...best!, if (bestExtra > 0) bestExtra];
    return MealPlanMealModel(
      mealId: mealId,
      title: foods.map((f) => f.nameAr).join(' و'),
      mealType: mealType,
      dateKey: dateKey,
      calories: foods.indexed.fold<double>(
        0,
        (s, v) => s + grams[v.$1] / 100 * v.$2.nutrientsPer100g.energyKcal!,
      ),
      foods: foods.map((f) => f.id).toList(),
      foodPortions: [
        for (final v in foods.indexed)
          MealPlanFoodPortion(foodId: v.$2.id, grams: grams[v.$1]),
      ],
    );
  }
}
