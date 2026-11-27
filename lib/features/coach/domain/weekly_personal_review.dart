import '../../../../data/models/meal_entry_model.dart';
import '../../../../core/utils/date_utils.dart';

/// Describes recorded patterns, never real-life adherence or clinical adequacy.
class WeeklyPersonalReview {
  WeeklyPersonalReview({
    required String todayKey,
    required List<MealEntryModel> meals,
    int windowDays = 7,
  }) {
    if (windowDays < 1 || windowDays > 366) {
      throw ArgumentError.value(windowDays);
    }
    final today = DateTime.parse('${todayKey}T00:00:00');
    final first = SufraDateUtils.toDateKey(
      SufraDateUtils.shiftDays(today, 1 - windowDays),
    );
    final previousFirst = SufraDateUtils.toDateKey(
      SufraDateUtils.shiftDays(today, 1 - 2 * windowDays),
    );
    records = meals
        .where(
          (m) =>
              m.dateKey.compareTo(first) >= 0 &&
              m.dateKey.compareTo(todayKey) <= 0,
        )
        .toList();
    previousDays = meals
        .where(
          (m) =>
              m.dateKey.compareTo(previousFirst) >= 0 &&
              m.dateKey.compareTo(first) < 0,
        )
        .map((m) => m.dateKey)
        .toSet()
        .length;
  }
  late final List<MealEntryModel> records;
  late final int previousDays;
  int get loggedDays => records.map((m) => m.dateKey).toSet().length;
  int get ingredientFoods => records
      .expand((m) => m.items)
      .map((i) => i.foodId)
      .where((id) => id.isNotEmpty)
      .toSet()
      .length;
  int get ingredientMeals => records.where((m) => m.items.isNotEmpty).length;
  int knownMeals(double? Function(MealEntryModel) field) => records
      .where((m) => field(m) != null && field(m)!.isFinite && field(m)! >= 0)
      .length;

  /// Unknown meal nutrients invalidate that day's total, not treated as zero.
  ({double? average, int days}) measuredAverage(
    double? Function(MealEntryModel) field,
  ) {
    final sums = <double>[];
    for (final day in records.map((m) => m.dateKey).toSet()) {
      final values = records.where((m) => m.dateKey == day).map(field).toList();
      if (values.any((v) => v == null || !v.isFinite || v < 0)) continue;
      sums.add(values.fold<double>(0, (s, v) => s + v!));
    }
    return (
      average: sums.isEmpty ? null : sums.reduce((a, b) => a + b) / sums.length,
      days: sums.length,
    );
  }
}
