import '../../../core/utils/date_utils.dart';
import '../../../data/models/daily_log_model.dart';

/// Per-day nutrition snapshot used by the progress statistics.
///
/// Honesty contract (aligned with the lead's shared-model migration that
/// makes optional nutrient totals nullable):
/// - A day only counts as tracked when it owns actual meal records
///   (daily log mealCount > 0). Water-only or absent days are unknown,
///   never a verified zero-calorie day.
/// - Defaulted DailyLogModel zeros are not treated as measured nutrition.
/// - Null/unknown totals are excluded from averages (never coalesced
///   to zero); [trackedDays] reports the coverage behind every average.
class DayNutrition {
  const DayNutrition({
    required this.dateKey,
    required this.date,
    required this.tracked,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.waterMl = 0,
    this.mealCount = 0,
    this.calorieTarget,
    this.proteinTarget,
    this.carbsTarget,
    this.fatTarget,
  });

  final String dateKey;
  final DateTime date;

  /// True only when the day owns at least one recorded meal.
  final bool tracked;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final double waterMl;
  final int mealCount;
  final double? calorieTarget;
  final double? proteinTarget, carbsTarget, fatTarget;

  static final _zeroDate = DateTime(1970);

  /// Unknown/empty day (no daily log document at all).
  factory DayNutrition.empty(String dateKey) => DayNutrition(
    dateKey: dateKey,
    date: DateTime.tryParse(dateKey) ?? _zeroDate,
    tracked: false,
  );

  /// From a daily-log aggregate. Days without meals stay untracked and
  /// their totals become unknown (null), per the honesty contract.
  factory DayNutrition.fromLog(DailyLogModel log) {
    final tracked = log.mealCount > 0;
    return DayNutrition(
      dateKey: log.dateKey,
      date: DateTime.tryParse(log.dateKey) ?? _zeroDate,
      tracked: tracked,
      calories: tracked ? log.totalCalories : null,
      protein: tracked ? log.totalProtein : null,
      carbs: tracked ? log.totalCarbs : null,
      fat: tracked ? log.totalFat : null,
      fiber: tracked ? log.totalFiber : null,
      sugar: tracked ? log.totalSugar : null,
      sodium: tracked ? log.totalSodium : null,
      waterMl: log.waterIntakeMl,
      mealCount: log.mealCount,
      calorieTarget: tracked && log.calorieTarget > 0
          ? log.calorieTarget
          : null,
      proteinTarget: tracked && log.proteinTarget > 0
          ? log.proteinTarget
          : null,
      carbsTarget: tracked && log.carbsTarget > 0 ? log.carbsTarget : null,
      fatTarget: tracked && log.fatTarget > 0 ? log.fatTarget : null,
    );
  }

  /// Adherence band for the daily-commitment cells, based on measured
  /// calories vs target. Untracked days and days without a target
  /// return null (rendered as unknown, never red/green).
  double? get adherence {
    final c = calories;
    final t = calorieTarget;
    if (!tracked || c == null || t == null || t <= 0) return null;
    return c / t;
  }
}

/// Averages over tracked days only; null when coverage is empty.
class NutritionAverages {
  const NutritionAverages({
    required this.trackedDays,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.calorieTarget,
    this.proteinTarget,
    this.carbsTarget,
    this.fatTarget,
  });

  final int trackedDays;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final double? sugar;
  final double? calorieTarget;
  final double? proteinTarget;
  final double? carbsTarget;
  final double? fatTarget;

  static double? _avg(Iterable<double?> values) {
    final present = values.whereType<double>().toList();
    if (present.isEmpty) return null;
    return present.reduce((a, b) => a + b) / present.length;
  }

  static double? _targetAverage(
    List<DayNutrition> days,
    double? Function(DayNutrition) value,
    double? Function(DayNutrition) target,
  ) {
    final measured = days.where((d) => value(d) != null).toList();
    if (measured.isEmpty || measured.any((d) => target(d) == null)) return null;
    return _avg(measured.map(target));
  }

  factory NutritionAverages.of(List<DayNutrition> days) {
    final tracked = days.where((d) => d.tracked).toList();
    return NutritionAverages(
      trackedDays: tracked.length,
      calories: _avg(tracked.map((d) => d.calories)),
      protein: _avg(tracked.map((d) => d.protein)),
      carbs: _avg(tracked.map((d) => d.carbs)),
      fat: _avg(tracked.map((d) => d.fat)),
      fiber: _avg(tracked.map((d) => d.fiber)),
      sugar: _avg(tracked.map((d) => d.sugar)),
      calorieTarget: _targetAverage(
        tracked,
        (d) => d.calories,
        (d) => d.calorieTarget,
      ),
      proteinTarget: _targetAverage(
        tracked,
        (d) => d.protein,
        (d) => d.proteinTarget,
      ),
      carbsTarget: _targetAverage(
        tracked,
        (d) => d.carbs,
        (d) => d.carbsTarget,
      ),
      fatTarget: _targetAverage(tracked, (d) => d.fat, (d) => d.fatTarget),
    );
  }

  /// Percentage (0..100+) of an average against its target; null when
  /// either side is unknown so the UI can show an honest dash.
  static double? percent(double? value, double? target) {
    if (value == null || target == null || target <= 0) return null;
    return value / target * 100;
  }
}

/// Consecutive tracked days ending today (or yesterday when today has
/// no meals yet). Same rule as HomeCubit; kept local so the progress
/// feature stays self-contained for the isolated merge.
int computeTrackedStreak(List<DayNutrition> days, DateTime now) {
  final byDate = {for (final d in days) d.dateKey: d};
  String keyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  var cursor = SufraDateUtils.startOfDay(now);
  final today = byDate[keyOf(cursor)];
  if (today == null || !today.tracked) {
    cursor = SufraDateUtils.shiftDays(cursor, -1);
  }
  var streak = 0;
  while (true) {
    final day = byDate[keyOf(cursor)];
    if (day == null || !day.tracked) break;
    streak++;
    cursor = SufraDateUtils.shiftDays(cursor, -1);
  }
  return streak;
}
