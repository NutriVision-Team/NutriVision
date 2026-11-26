import '../../../../core/utils/nutrition_values.dart';
import '../../../../data/models/meal_entry_model.dart';
import '../../../../data/models/daily_log_model.dart';
import 'health_coach_profile.dart';

/// Numbers are derived from stored records, never model text or estimates.
/// An absent log is unknown, not zero intake or a claim about real consumption.
class CoachTrustedMetric {
  const CoachTrustedMetric({
    required this.key,
    required this.value,
    required this.unit,
    required this.sourceIds,
  });
  final String key;
  final double? value;
  final String unit;
  final List<String> sourceIds;
  String label(String locale) {
    const ar = {
      'logged_energy': 'طاقة مسجلة',
      'logged_protein': 'بروتين مسجل',
      'logged_carbohydrate': 'كربوهيدرات مسجلة',
      'logged_fat': 'دهون مسجلة',
      'logged_fiber': 'ألياف مسجلة',
      'logged_water': 'مياه مسجلة',
    };
    const en = {
      'logged_energy': 'Logged energy',
      'logged_protein': 'Logged protein',
      'logged_carbohydrate': 'Logged carbohydrate',
      'logged_fat': 'Logged fat',
      'logged_fiber': 'Logged fiber',
      'logged_water': 'Logged water',
    };
    return (locale == 'ar' ? ar : en)[key] ?? key;
  }

  CoachRecordFact toFact() =>
      CoachRecordFact(key: key, value: value, source: sourceIds.join(','));
}

class CoachTrustedSnapshot {
  const CoachTrustedSnapshot({required this.metrics});
  final List<CoachTrustedMetric> metrics;
  List<CoachRecordFact> get facts => metrics.map((m) => m.toFact()).toList();

  /// External summaries never include stable local record identifiers.
  List<CoachRecordFact> externalFactsForDate(String dateKey) => metrics
      .map(
        (m) => CoachRecordFact(
          key: m.key,
          value: m.value,
          source: m.key == 'logged_water' ? 'water_log' : 'diary',
          date: dateKey,
          unit: m.unit,
        ),
      )
      .toList(growable: false);

  factory CoachTrustedSnapshot.forDay({
    required String dateKey,
    required List<MealEntryModel> meals,
    DailyLogModel? log,
  }) {
    if (log != null && log.dateKey != dateKey) {
      throw ArgumentError('Daily log date mismatch');
    }
    final today = meals.where((m) => m.dateKey == dateKey).toList();
    final sources = today.isNotEmpty
        ? today.map((m) => 'meal:${m.mealId}').toList()
        : log == null
        ? <String>[]
        : ['daily_log:$dateKey'];
    double? sum(double? Function(MealEntryModel) field, double? fromLog) =>
        today.isNotEmpty
        ? sumKnownNutrients(today.map(field))
        : log != null && log.mealCount > 0
        ? knownNutrient(fromLog)
        : null;
    return CoachTrustedSnapshot(
      metrics: [
        CoachTrustedMetric(
          key: 'logged_energy',
          value: sum((m) => m.totalCalories, log?.totalCalories),
          unit: 'kcal',
          sourceIds: sources,
        ),
        CoachTrustedMetric(
          key: 'logged_protein',
          value: sum((m) => m.totalProtein, log?.totalProtein),
          unit: 'g',
          sourceIds: sources,
        ),
        CoachTrustedMetric(
          key: 'logged_carbohydrate',
          value: sum((m) => m.totalCarbs, log?.totalCarbs),
          unit: 'g',
          sourceIds: sources,
        ),
        CoachTrustedMetric(
          key: 'logged_fat',
          value: sum((m) => m.totalFat, log?.totalFat),
          unit: 'g',
          sourceIds: sources,
        ),
        CoachTrustedMetric(
          key: 'logged_fiber',
          value: sum((m) => m.totalFiber, log?.totalFiber),
          unit: 'g',
          sourceIds: sources,
        ),
        CoachTrustedMetric(
          key: 'logged_water',
          value: knownNutrient(log?.waterIntakeMl),
          unit: 'ml',
          sourceIds: log == null ? [] : ['daily_log:$dateKey'],
        ),
      ],
    );
  }
}
