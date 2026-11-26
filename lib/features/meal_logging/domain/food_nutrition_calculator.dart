/// Deterministic nutrition calculator for foods and meals.
///
/// For each nutrient: total = Σ (quantityGrams / 100 × nutrientPer100g).
/// Independent of any AI provider. Unknown source nutrients stay unknown:
/// they are never silently replaced with zero.
class NutrientsPer100g {
  const NutrientsPer100g({
    required this.energyKcal,
    this.proteinG,
    this.fatG,
    this.carbohydrateG,
    this.fiberG,
    this.sugarsG,
    this.sodiumMg,
  });

  final double energyKcal;
  final double? proteinG;
  final double? fatG;
  final double? carbohydrateG;
  final double? fiberG;
  final double? sugarsG;
  final double? sodiumMg;
}

class FoodPortion {
  const FoodPortion({
    required this.foodId,
    required this.quantityGrams,
    required this.per100g,
    this.servings = 1,
  });

  final String foodId;
  final double quantityGrams;
  final NutrientsPer100g per100g;

  /// Number of servings of [quantityGrams].
  final double servings;
}

class NutritionTotals {
  const NutritionTotals({
    required this.energyKcal,
    this.proteinG,
    this.fatG,
    this.carbohydrateG,
    this.fiberG,
    this.sugarsG,
    this.sodiumMg,
    required this.isComplete,
  });

  final double energyKcal;

  /// Null when at least one contributing food lacked the nutrient.
  final double? proteinG;
  final double? fatG;
  final double? carbohydrateG;
  final double? fiberG;
  final double? sugarsG;
  final double? sodiumMg;

  /// False when any nutrient could not be fully calculated.
  final bool isComplete;
}

class FoodNutritionCalculator {
  const FoodNutritionCalculator();

  double? _sumNullable(Iterable<double?> values) {
    var total = 0.0;
    var any = false;
    for (final v in values) {
      if (v == null) return null;
      total += v;
      any = true;
    }
    return any ? total : null;
  }

  NutritionTotals calculate(List<FoodPortion> portions) {
    if (portions.isEmpty) {
      return const NutritionTotals(energyKcal: 0, isComplete: true);
    }

    double scale(FoodPortion p) => p.quantityGrams * p.servings / 100;

    final energy = portions.fold<double>(
      0,
      (sum, p) => sum + scale(p) * p.per100g.energyKcal,
    );
    final protein = _sumNullable(
      portions.map(
        (p) =>
            p.per100g.proteinG == null ? null : scale(p) * p.per100g.proteinG!,
      ),
    );
    final fat = _sumNullable(
      portions.map(
        (p) => p.per100g.fatG == null ? null : scale(p) * p.per100g.fatG!,
      ),
    );
    final carbs = _sumNullable(
      portions.map(
        (p) => p.per100g.carbohydrateG == null
            ? null
            : scale(p) * p.per100g.carbohydrateG!,
      ),
    );
    final fiber = _sumNullable(
      portions.map(
        (p) => p.per100g.fiberG == null ? null : scale(p) * p.per100g.fiberG!,
      ),
    );
    final sugars = _sumNullable(
      portions.map(
        (p) => p.per100g.sugarsG == null ? null : scale(p) * p.per100g.sugarsG!,
      ),
    );
    final sodium = _sumNullable(
      portions.map(
        (p) =>
            p.per100g.sodiumMg == null ? null : scale(p) * p.per100g.sodiumMg!,
      ),
    );

    final complete =
        protein != null &&
        fat != null &&
        carbs != null &&
        fiber != null &&
        sugars != null &&
        sodium != null;

    return NutritionTotals(
      energyKcal: energy,
      proteinG: protein,
      fatG: fat,
      carbohydrateG: carbs,
      fiberG: fiber,
      sugarsG: sugars,
      sodiumMg: sodium,
      isComplete: complete,
    );
  }
}
