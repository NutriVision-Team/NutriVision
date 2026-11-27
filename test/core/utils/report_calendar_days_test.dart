import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/features/planner/domain/weekly_plan_generator.dart';
import 'package:sufradepi/features/planner/presentation/cubit/planner_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/utils/date_utils.dart';
import 'package:sufradepi/features/progress/presentation/cubit/progress_cubit.dart';
import 'package:sufradepi/features/progress/domain/day_nutrition.dart';
import 'package:sufradepi/features/home/presentation/cubit/home_cubit.dart';
import '../../features/progress/progress_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'week and Home/report streaks use7distinct dates across Cairo DST',
    () async {
      SharedPreferences.setMockInitialValues({});
      final date = DateTime(2026, 4, 26);
      final nutrition = fixture.FakeNutritionRepository()
        ..logs = [
          for (var day = 20; day <= 26; day++) fixture.log('2026-04-$day'),
        ];
      final report = ProgressCubit(
        nutritionRepository: nutrition,
        uid: 'u',
        currentUid: () => 'u',
        clock: () => date,
      );
      final home = HomeCubit(
        userRepository: fixture.FakeUserRepository(),
        nutritionRepository: nutrition,
        clock: () => date,
      );
      await report.load();
      await home.load('u');
      expect(report.state.days.map((d) => d.dateKey), [
        for (var d = 20; d <= 26; d++) '2026-04-$d',
      ]);
      expect(report.state.streakDays, 7);
      expect((home.state as HomeLoaded).streakDays, 7);
      expect(computeTrackedStreak(report.state.days, date), 7);
      expect(SufraDateUtils.shiftDays(DateTime(2026, 10, 30), -1).day, 29);
      await report.close();
      await home.close();
    },
  );
  test(
    'planner generation and day selection preserve7calendar dates through Cairo DST',
    () {
      final raw =
          jsonDecode(File('assets/data/foods.json').readAsStringSync()) as Map;
      final g = WeeklyPlanGenerator(
        catalog: (raw['foods'] as List)
            .map((f) => LocalFoodRecord.fromJson(Map<String, dynamic>.from(f)))
            .toList(),
      );
      final start = DateTime(2026, 4, 18);
      final plan = g.generate(
        weekStart: start,
        dailyCalorieTarget: 2100,
        seed: 1,
      );
      final state = PlannerState(
        status: PlannerStatus.ready,
        weekStart: start,
        plan: plan,
      );
      for (var i = 0; i < 7; i++) {
        final expected = SufraDateUtils.toDateKey(DateTime(2026, 4, 18 + i));
        expect(state.mealsForDay(i).map((m) => m.dateKey).toSet(), {expected});
        expect(state.mealsForDay(i).length, 4);
      }
      expect(WeeklyPlanGenerator.weekStartOf(DateTime(2026, 4, 24)).day, 18);
    },
  );
}
