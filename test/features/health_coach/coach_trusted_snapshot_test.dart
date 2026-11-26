import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/health_coach/domain/coach_history_summary.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'package:sufradepi/features/health_coach/domain/coach_trusted_snapshot.dart';

void main() {
  const day = '2026-11-24';
  MealEntryModel meal(String id, double? protein, {String date = day}) =>
      MealEntryModel(
        mealId: id,
        userId: 'u',
        dateKey: date,
        consumedAt: DateTime(2026, 11, 24),
        mealType: 'breakfast',
        inputMethod: 'manual',
        title: 'fixture',
        items: [],
        totalCalories: 100,
        totalProtein: protein,
        totalCarbs: 10,
        totalFat: 2,
        totalFiber: null,
        totalSugar: null,
        totalSodium: null,
        analysisStatus: 'confirmed',
      );
  DailyLogModel log(String date) => DailyLogModel(
    dateKey: date,
    timezone: 'Africa/Cairo',
    totalCalories: 900,
    totalProtein: 90,
    totalCarbs: 100,
    totalFat: 20,
    totalFiber: null,
    totalSugar: null,
    totalSodium: null,
    calorieTarget: 2000,
    proteinTarget: 100,
    carbsTarget: 200,
    fatTarget: 70,
    waterIntakeMl: 750,
    mealCount: 2,
  );
  test(
    'history period respects account boundaries, confirmed records and unknowns',
    () {
      final data = [
        meal('a', 10),
        meal('b', null, date: '2026-11-01'),
        meal('future', 10, date: '2026-12-01'),
      ];
      final week = CoachHistorySummary.build(
        data,
        uid: 'u',
        now: DateTime(2026, 11, 25),
        days: 7,
      );
      expect(week.meals, 1);
      expect(week.energyKcal, 100);
      expect(week.recordedDays, 1);
      final all = CoachHistorySummary.build(
        data,
        uid: 'u',
        now: DateTime(2026, 11, 25),
        days: 0,
      );
      expect(all.meals, 2);
      expect(all.proteinG, null);
      expect(all.from, '2026-11-01');
      final other = CoachHistorySummary.build(
        data,
        uid: 'other',
        now: DateTime(2026, 11, 25),
        days: 30,
      );
      expect(other.meals, 0);
      expect(other.energyKcal, null);
      expect(all.toContext().toString(), isNot(contains('fixture')));
      expect(all.toContext().toString(), isNot(contains('mealId')));
    },
  );
  test(
    'meal sums do not double-count aggregate, keep unknown and provenance',
    () {
      final s = CoachTrustedSnapshot.forDay(
        dateKey: day,
        meals: [
          meal('a', 10),
          meal('b', null),
          meal('y', 20, date: '2026-11-23'),
        ],
        log: log(day),
      );
      expect(s.metrics.first.value, 200);
      expect(s.metrics[1].value, null);
      expect(s.metrics.first.sourceIds, ['meal:a', 'meal:b']);
      expect(s.metrics.last.value, 750);
      expect(s.metrics.last.sourceIds, ['daily_log:2026-11-24']);
    },
  );
  test('no records are unknown, not invented zero consumption', () {
    final s = CoachTrustedSnapshot.forDay(dateKey: day, meals: []);
    expect(s.metrics.every((m) => m.value == null), true);
    expect(s.metrics.every((m) => m.sourceIds.isEmpty), true);
  });
  test('water-only aggregate must not invent zero food consumption', () {
    final s = CoachTrustedSnapshot.forDay(
      dateKey: day,
      meals: [],
      log: const DailyLogModel(
        dateKey: day,
        timezone: 'Africa/Cairo',
        totalCalories: 0,
        totalProtein: null,
        totalCarbs: null,
        totalFat: null,
        totalFiber: null,
        totalSugar: null,
        totalSodium: null,
        calorieTarget: 0,
        proteinTarget: 0,
        carbsTarget: 0,
        fatTarget: 0,
        waterIntakeMl: 250,
        mealCount: 0,
      ),
    );
    expect(s.metrics.first.value, isNull);
    expect(s.metrics.last.value, 250);
  });
  test('fallback log is grounded and different-day log rejected', () {
    expect(
      CoachTrustedSnapshot.forDay(
        dateKey: day,
        meals: [],
        log: log(day),
      ).metrics.first.value,
      900,
    );
    expect(
      () => CoachTrustedSnapshot.forDay(
        dateKey: day,
        meals: [],
        log: log('2026-11-23'),
      ),
      throwsArgumentError,
    );
  });
}
