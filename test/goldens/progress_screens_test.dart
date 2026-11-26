import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'milestone1_screens_test.dart' show loadRealFonts;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sufradepi/data/models/water_log_model.dart';
import 'package:sufradepi/data/models/weight_log_model.dart';
import 'package:sufradepi/features/progress/presentation/screens/export_report_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/report_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/stats_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/water_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/weight_screen.dart';

import '../features/progress/progress_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  FakeNutritionRepository nutrition() => FakeNutritionRepository()
    ..activeProfile = NutritionProfileModel(
      profileId: 'fixture',
      gender: 'male',
      dateOfBirth: DateTime(2000),
      heightCm: 180,
      currentWeightKg: 89,
      targetWeightKg: 80,
      activityLevel: 'sedentary',
      nutritionGoal: 'lose',
      dailyCalorieTarget: 1850,
      proteinTarget: 120,
      carbsTarget: 200,
      fatTarget: 60,
    )
    ..meals = [
      for (var i = 0; i < 6; i++)
        MealEntryModel(
          mealId: 'm$i',
          userId: 'u1',
          dateKey: '2026-11-22',
          consumedAt: DateTime(2026, 11, 22, 12),
          mealType: ['breakfast', 'lunch', 'dinner'][i % 3],
          inputMethod: 'catalog',
          title: 'fixture',
          items: const [],
          totalCalories: 100,
          totalProtein: null,
          totalCarbs: null,
          totalFat: null,
          totalFiber: null,
          totalSugar: null,
          totalSodium: null,
          analysisStatus: 'confirmed',
        ),
    ]
    ..logs = [
      log('2026-11-16', meals: 2, cal: 1700),
      log('2026-11-17', meals: 3, cal: 1900),
      log('2026-11-18', meals: 2, cal: 1650),
      log('2026-11-19', meals: 0, cal: 0),
      log('2026-11-20', meals: 3, cal: 2050),
      log('2026-11-21', meals: 2, cal: 1800),
      log('2026-11-22', meals: 3, cal: 1950),
    ];

  testWidgets('goldens: progress screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final cases = <String, Widget>{
      'progress_stats': StatsScreen(
        waterWeightRepository: FakeWaterWeightRepository()
          ..weight = [
            WeightLogModel(
              weightId: 'a',
              weightKg: 88.2,
              recordedAt: DateTime(2026, 11, 22),
              dateKey: '2026-11-22',
            ),
            WeightLogModel(
              weightId: 'b',
              weightKg: 89,
              recordedAt: DateTime(2026, 11, 15),
              dateKey: '2026-11-15',
            ),
          ],
      ),
      'progress_water': WaterScreen(
        waterWeightRepository: FakeWaterWeightRepository()
          ..water = [
            WaterLogModel(
              waterId: 'w1',
              amountMl: 250,
              consumedAt: DateTime(2026, 11, 22, 8),
              dateKey: '2026-11-22',
            ),
            WaterLogModel(
              waterId: 'w2',
              amountMl: 500,
              consumedAt: DateTime(2026, 11, 22, 12),
              dateKey: '2026-11-22',
            ),
          ],
      ),
      'progress_weight': WeightScreen(
        waterWeightRepository: FakeWaterWeightRepository()
          ..weight = [
            WeightLogModel(
              weightId: 'g1',
              weightKg: 88.2,
              recordedAt: DateTime(2026, 11, 22, 7),
              dateKey: '2026-11-22',
            ),
            WeightLogModel(
              weightId: 'g2',
              weightKg: 89.0,
              recordedAt: DateTime(2026, 11, 15, 7),
              dateKey: '2026-11-15',
            ),
          ],
      ),
      'progress_report': const ReportScreen(),
      'progress_export': ExportReportScreen(
        waterWeightRepository: FakeWaterWeightRepository(),
      ),
    };
    for (final entry in cases.entries) {
      final source = nutrition();
      if (entry.key == 'progress_water') {
        source.logs = [
          for (var i = 0; i < 7; i++)
            DailyLogModel(
              dateKey: source.logs[i].dateKey,
              timezone: 'Africa/Cairo',
              calorieTarget: 0,
              proteinTarget: 0,
              carbsTarget: 0,
              fatTarget: 0,
              totalCalories: null,
              totalProtein: null,
              totalCarbs: null,
              totalFat: null,
              totalFiber: null,
              totalSugar: null,
              totalSodium: null,
              waterIntakeMl: [
                0.0,
                1500.0,
                1000.0,
                2000.0,
                500.0,
                1250.0,
                750.0,
              ][i],
              mealCount: 0,
            ),
        ];
      }
      await pumpScreen(tester, entry.value, source);
      await tester.pump(const Duration(seconds: 2));
      await expectLater(
        find.byType(entry.value.runtimeType),
        matchesGoldenFile('progress/${entry.key}.png'),
      );
    }
  });
}
