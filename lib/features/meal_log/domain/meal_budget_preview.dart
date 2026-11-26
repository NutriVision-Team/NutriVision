/// A transparent comparison with the configured calorie target, never a
/// recommendation that a food is medically suitable or should be eaten.
class MealBudgetPreview {
  const MealBudgetPreview._(this.before, this.after);
  final double before, after;
  static MealBudgetPreview? calculate({
    required double? target,
    required double consumed,
    required double? meal,
  }) {
    if (target == null ||
        meal == null ||
        !target.isFinite ||
        !consumed.isFinite ||
        !meal.isFinite ||
        target <= 0 ||
        consumed < 0 ||
        meal < 0) {
      return null;
    }
    return MealBudgetPreview._(target - consumed, target - consumed - meal);
  }
}
