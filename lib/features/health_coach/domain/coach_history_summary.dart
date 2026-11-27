import '../../../data/models/meal_entry_model.dart';
import '../../../core/utils/nutrition_values.dart';

/// Summarizes confirmed account records, never claims complete real intake.
class CoachHistorySummary {
  const CoachHistorySummary(
    this.from,
    this.to,
    this.meals,
    this.recordedDays,
    this.energyKcal,
    this.proteinG,
  );
  final String from, to;
  final int meals, recordedDays;
  final double? energyKcal, proteinG;
  factory CoachHistorySummary.build(
    List<MealEntryModel> records, {
    required String uid,
    required DateTime now,
    required int days,
  }) {
    if (!const [7, 30, 0].contains(days)) throw ArgumentError('Period');
    String date(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final to = date(now);
    final lower = days == 0
        ? '0001-01-01'
        : date(
            DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(Duration(days: days - 1)),
          );
    final selected = records
        .where(
          (m) =>
              m.userId == uid &&
              m.analysisStatus == 'confirmed' &&
              RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(m.dateKey) &&
              m.dateKey.compareTo(lower) >= 0 &&
              m.dateKey.compareTo(to) <= 0,
        )
        .toList();
    selected.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return CoachHistorySummary(
      days == 0 && selected.isNotEmpty ? selected.first.dateKey : lower,
      to,
      selected.length,
      selected.map((m) => m.dateKey).toSet().length,
      selected.isEmpty
          ? null
          : sumKnownNutrients(selected.map((m) => m.totalCalories)),
      selected.isEmpty
          ? null
          : sumKnownNutrients(selected.map((m) => m.totalProtein)),
    );
  }
  Map<String, Object?> toContext() => {
    'from': from,
    'to': to,
    'confirmedMeals': meals,
    'recordedDays': recordedDays,
    'energyKcal': energyKcal,
    'proteinG': proteinG,
    'coverage': 'recorded_confirmed_meals_only',
    'missingDays': 'unknown',
  };
  Map<String, String> display(bool ar) => {
    ar ? 'الفترة المسجلة' : 'Recorded period': '$from / $to',
    ar ? 'وجبات مؤكدة' : 'Confirmed meals': '$meals',
    ar ? 'أيام لها وجبات' : 'Days with meals': '$recordedDays',
    ar ? 'إجمالي الطاقة المسجلة' : 'Total recorded energy': energyKcal == null
        ? (ar ? 'غير معروف' : 'Unknown')
        : '${energyKcal!.toStringAsFixed(1)} kcal',
    ar ? 'إجمالي البروتين المسجل' : 'Total recorded protein': proteinG == null
        ? (ar ? 'غير معروف' : 'Unknown')
        : '${proteinG!.toStringAsFixed(1)} g',
  };
}
