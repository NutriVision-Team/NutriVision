import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/coach/domain/weekly_personal_review.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';

MealEntryModel m(String id, String day, {double? fiber = 3}) => MealEntryModel(
  mealId: id,
  userId: 'u1',
  dateKey: day,
  consumedAt: DateTime.parse('${day}T12:00:00'),
  mealType: 'lunch',
  inputMethod: 'manual',
  title: 'entry',
  items: const [],
  totalCalories: 400,
  totalProtein: 20,
  totalCarbs: 30,
  totalFat: 10,
  totalFiber: fiber,
  totalSugar: null,
  totalSodium: null,
  analysisStatus: 'confirmed',
);
void main() {
  test(
    'missing nutrients invalidate daily total but preserve other measured days',
    () {
      final r = WeeklyPersonalReview(
        todayKey: '2026-11-24',
        meals: [
          m('a', '2026-11-24'),
          m('b', '2026-11-24', fiber: null),
          m('c', '2026-11-23', fiber: 6),
        ],
      );
      expect(r.loggedDays, 2);
      expect(r.measuredAverage((m) => m.totalFiber), (average: 6.0, days: 1));
      expect(r.measuredAverage((m) => m.totalCalories), (
        average: 600.0,
        days: 2,
      ));
    },
  );
  test(
    'previous coverage and current window omit future and older entries',
    () {
      final r = WeeklyPersonalReview(
        todayKey: '2026-11-24',
        meals: [
          m('a', '2026-11-24'),
          m('b', '2026-11-17'),
          m('c', '2026-11-12'),
          m('d', '2026-11-25'),
          m('e', '2026-11-01'),
        ],
      );
      expect(r.loggedDays, 1);
      expect(r.previousDays, 2);
      expect(r.ingredientMeals, 0);
      expect(r.ingredientFoods, 0);
    },
  );
  test('empty records do not become zero-nutrient averages', () {
    final r = WeeklyPersonalReview(todayKey: '2026-11-24', meals: []);
    expect(r.measuredAverage((m) => m.totalProtein), (average: null, days: 0));
  });
  test('daily and rolling30 windows use calendar bounds, not all history', () {
    final meals = [
      m('today', '2026-11-24'),
      m('first', '2026-10-26'),
      m('before', '2026-10-25'),
      m('future', '2026-11-25'),
    ];
    final daily = WeeklyPersonalReview(
      todayKey: '2026-11-24',
      meals: meals,
      windowDays: 1,
    );
    expect(daily.loggedDays, 1);
    expect(daily.records.single.mealId, 'today');
    final monthly = WeeklyPersonalReview(
      todayKey: '2026-11-24',
      meals: meals,
      windowDays: 30,
    );
    expect(monthly.records.map((m) => m.mealId), ['today', 'first']);
    expect(monthly.previousDays, 1);
    expect(
      () => WeeklyPersonalReview(
        todayKey: '2026-11-24',
        meals: meals,
        windowDays: 0,
      ),
      throwsArgumentError,
    );
  });
}
