import '../meal_log/catalog_flow_test.dart' show catalog;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/diary/presentation/screens/diary_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_review_screen.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/nutrition_plan/presentation/plan_screen.dart';
import 'package:sufradepi/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import 'package:sufradepi/features/progress/presentation/screens/stats_screen.dart';
import '../features/progress/progress_test.dart' show FakeWaterWeightRepository;
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  testWidgets('matched light Review Diary Stats Plan actual fixtures', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = await Harness.signedIn();
    h.setupCubit.update(
      ProfileSetupData(
        nutritionGoal: 'lose',
        gender: 'male',
        dateOfBirth: DateTime(2000, 8, 7),
        heightCm: 175,
        currentWeightKg: 90,
        targetWeightKg: 80,
        activityLevel: 'moderate',
      ),
    );
    while (h.setupCubit.state.step < 6) {
      h.setupCubit.next();
    }
    await t.runAsync(() => h.setupCubit.finish('u1'));
    for (final entry in <String, Widget>{
      'review': MealReviewScreen(portion: FoodPortion(catalog(), 150)),
      'diary': DiaryScreen(initialDate: DateTime(2026, 11, 22)),
      'stats': StatsScreen(waterWeightRepository: FakeWaterWeightRepository()),
      'plan': const PlanScreen(),
    }.entries) {
      final key = GlobalKey();
      await t.runAsync(() async {
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: h.wrap(entry.value, themeMode: ThemeMode.light),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 250));
      });
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      final dir = Platform.environment['SUFRA_LIGHT_DIR'];
      if (dir != null) {
        await t.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '$dir/${entry.key}.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    await t.pumpWidget(const SizedBox.shrink());
    await h.dispose();
  });
}
