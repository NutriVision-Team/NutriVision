import '../../../../core/utils/date_utils.dart';
import '../../../../data/models/meal_entry_model.dart';
import 'weekly_personal_review.dart';

/// Compares available records in adjacent calendar windows, never adherence.
class CoachProgressComparison {
  CoachProgressComparison({
    required String todayKey,
    required List<MealEntryModel> meals,
    required Map<String, Set<String>> checkins,
    required int days,
  }) {
    if (days < 1 || days > 183) throw ArgumentError.value(days);
    currentEnd = DateTime.parse('${todayKey}T00:00:00');
    currentStart = SufraDateUtils.shiftDays(currentEnd, 1 - days);
    previousEnd = SufraDateUtils.shiftDays(currentStart, -1);
    previousStart = SufraDateUtils.shiftDays(previousEnd, 1 - days);
    current = WeeklyPersonalReview(
      todayKey: todayKey,
      meals: meals,
      windowDays: days,
    );
    previous = WeeklyPersonalReview(
      todayKey: SufraDateUtils.toDateKey(previousEnd),
      meals: meals,
      windowDays: days,
    );
    Set<String> confirmations(DateTime start, DateTime end) {
      final first = SufraDateUtils.toDateKey(start),
          last = SufraDateUtils.toDateKey(end);
      return {
        for (final e in checkins.entries)
          if (e.key.compareTo(first) >= 0 && e.key.compareTo(last) <= 0)
            for (final id in e.value)
              if (const {
                'log_meal',
                'prepare_meal',
                'review_ingredients',
              }.contains(id))
                '${e.key}/$id',
      };
    }

    currentConfirmations = confirmations(currentStart, currentEnd).length;
    previousConfirmations = confirmations(previousStart, previousEnd).length;
  }
  late final DateTime currentStart, currentEnd, previousStart, previousEnd;
  late final WeeklyPersonalReview current, previous;
  late final int currentConfirmations, previousConfirmations;
  String range(bool prior) =>
      '${SufraDateUtils.toDateKey(prior ? previousStart : currentStart)} / ${SufraDateUtils.toDateKey(prior ? previousEnd : currentEnd)}';

  /// A navigation suggestion, never a health verdict or a completed goal.
  String get nextAction => current.records.isEmpty
      ? 'diary'
      : current.ingredientMeals < current.records.length
      ? 'ingredients'
      : currentConfirmations == 0
      ? 'checkin'
      : 'plan';
}
