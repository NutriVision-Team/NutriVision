import 'coach_catalog_tools.dart';

/// Optional planning interface. Production provider does not implement it.
/// A provider may request only a typed tool, never supply nutrient values.
class CoachCalculationRequest {
  CoachCalculationRequest(Map<String, double> portions)
    : weighedFoods = Map.unmodifiable(portions);
  final Map<String, double> weighedFoods;
}

abstract interface class CoachToolPlanner {
  Future<CoachCalculationRequest?> selectCalculation(String question);
}

class CoachGroundedCalculation {
  const CoachGroundedCalculation(this.energyKcal, this.proteinG, this.sources);
  final double energyKcal;
  final double? proteinG;
  final List<String> sources;
  Map<String, String> display(bool ar) => {
    ar ? 'الطاقة من الكتالوج' : 'Catalog energy':
        '${energyKcal.toStringAsFixed(1)} kcal',
    ar ? 'البروتين من الكتالوج' : 'Catalog protein': proteinG == null
        ? (ar ? 'غير معروف' : 'Unknown')
        : '${proteinG!.toStringAsFixed(1)} g',
  };
}

class CoachConversationTools {
  const CoachConversationTools({
    required this.catalog,
    this.reviewedPortions = const {},
  });
  final CoachCatalogTools catalog;

  /// Exact food/state/grams approved in a user preview. Planner output alone
  /// cannot establish quantities or silently resolve ambiguous food matches.
  final Map<String, double> reviewedPortions;
  Future<CoachGroundedCalculation> execute(
    CoachCalculationRequest request,
  ) async {
    if (reviewedPortions.isEmpty ||
        request.weighedFoods.length != reviewedPortions.length ||
        request.weighedFoods.entries.any(
          (e) => reviewedPortions[e.key] != e.value,
        )) {
      throw StateError('Review selected foods and weights first');
    }
    final draft = await catalog.calculate(request.weighedFoods);
    return CoachGroundedCalculation(
      draft.totals!.energyKcal,
      draft.totals!.proteinG,
      draft.portions.map((p) => p.food.source!).toSet().toList(growable: false),
    );
  }
}
