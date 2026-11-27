import 'dart:io';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;

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

  for (final config in [
    ('ar', true, 390.0, 1.0),
    ('en', true, 320.0, 2.0),
    ('ar', false, 320.0, 2.0),
    ('en', false, 390.0, 1.0),
  ]) {
    testWidgets('controlled progress $config', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(config.$3, 844);
      tester.platformDispatcher.textScaleFactorTestValue = config.$4;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
        final key = GlobalKey();
        await pumpScreen(
          tester,
          RepaintBoundary(key: key, child: entry.value),
          source,
          theme: config.$2 ? AppTheme.light() : AppTheme.dark(),
          locale: Locale(config.$1),
        );
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull, reason: '${entry.key} $config');
        if (entry.key == 'progress_weight') {
          final context = tester.element(find.byType(WeightScreen));
          final l = AppLocalizations.of(context);
          final action = find.text(l.weightLogCta);
          final paragraph = tester.renderObject<RenderParagraph>(action);
          final painter = TextPainter(
            text: paragraph.text,
            textDirection: paragraph.textDirection,
            textScaler: paragraph.textScaler,
          )..layout(maxWidth: paragraph.size.width);
          expect(
            paragraph.size.height,
            greaterThanOrEqualTo(painter.height - .1),
            reason: 'Full localized action must have height for all lines',
          );
          painter.dispose();
        }

        Future<void> capture(String suffix) async {
          await tester.runAsync(() async {
            final im =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '/downloads/sufra/verification/${entry.key}_${config.$1}_${config.$2 ? 'light' : 'dark'}_${config.$3.toInt()}$suffix.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            im.dispose();
          });
        }

        await capture('');
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          for (var i = 0; i < 4; i++) {
            final pos = tester
                .state<ScrollableState>(scrollables.first)
                .position;
            pos.jumpTo(pos.maxScrollExtent);
            await tester.pump();
          }
          expect(tester.takeException(), isNull);
          await capture('_bottom');
        }
      }
    });
  }
}
