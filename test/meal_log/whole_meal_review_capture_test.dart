import 'dart:io';
import 'dart:ui' as ui;
import 'package:go_router/go_router.dart';
import 'package:sufradepi/features/alternatives/presentation/screens/alternatives_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_review_screen.dart';
import 'package:sufradepi/features/meal_log/domain/catalog_meal_draft.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/meal_log/presentation/widgets/meal_budget_card.dart';
import 'package:sufradepi/features/food_catalog/data/local_food_repository.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final ar in [true, false]) {
    testWidgets('actual four component review budget ${ar ? 'ar' : 'en'}', (
      t,
    ) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await Harness.signedIn();
      final calls = <MethodCall>[];
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (c) async {
          calls.add(c);
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final repo = LocalFoodRepository();
      final portions = <FoodPortion>[];
      for (final spec in [
        ('usda_sr_168878', 150.0),
        ('usda_foundation_331960', 120.0),
        ('usda_foundation_2346406', 100.0),
        ('usda_foundation_1999634', 100.0),
      ]) {
        final food = await t.runAsync(() => repo.getFoodById(spec.$1));
        portions.add(FoodPortion(food!, spec.$2));
      }
      h.nutritionRepository.meals = [
        MealEntryModel(
          mealId: 'fixture_previous',
          userId: 'u1',
          dateKey: '2026-11-22',
          consumedAt: DateTime(2026, 11, 22, 9),
          mealType: 'breakfast',
          inputMethod: 'catalog',
          title: 'fixture earlier meals',
          items: const [],
          totalCalories: 2200,
          totalProtein: null,
          totalCarbs: null,
          totalFat: null,
          totalFiber: null,
          totalSugar: null,
          totalSodium: null,
          analysisStatus: 'confirmed',
        ),
      ];
      await h.homeCubit.load('u1');
      OwnedReviewedMeal? sentToCoach;
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: h.wrap(
            MealReviewScreen(
              draft: CatalogMealDraft(portions),
              initialTitle: ar
                  ? 'أرز وفراخ وخضار'
                  : 'Rice, chicken and vegetables',
              inputMethod: 'photo',
            ),
            locale: Locale(ar ? 'ar' : 'en'),
            additionalRoutes: [
              GoRoute(
                path: '/coach',
                builder: (_, state) {
                  sentToCoach = state.extra as OwnedReviewedMeal;
                  return const Scaffold(body: Text('Coach handoff'));
                },
              ),
              GoRoute(
                path: '/alternatives',
                builder: (c, s) => const AlternativesScreen(),
              ),
            ],
          ),
        ),
      );
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await t.pump(const Duration(seconds: 1));
      Future<void> shot(String name) async {
        await t.runAsync(() async {
          for (final e in find.byType(Image).evaluate()) {
            await precacheImage((e.widget as Image).image, e);
          }
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
          im.dispose();
          await File(
            '/downloads/sufra-recovered/mixed_review_${ar ? 'ar' : 'en'}_$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
        });
      }

      await shot('components');
      await t.scrollUntilVisible(
        find.byType(MealBudgetCard),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pump(const Duration(milliseconds: 400));
      await shot('budget');
      expect(
        calls
            .where(
              (c) =>
                  c.method == 'HapticFeedback.vibrate' &&
                  c.arguments == 'HapticFeedbackType.heavyImpact',
            )
            .length,
        1,
      );
      expect(find.text(ar ? '235 سعرة' : '235 kcal'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.tap(find.text(ar ? 'استكشف بدائل' : 'Explore alternatives'));
      await t.pump();
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await t.pump(const Duration(seconds: 1));
      await shot('alternatives');
      expect(t.takeException(), isNull);
      await t.tap(find.byIcon(Icons.close).last);
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text(ar ? '235 سعرة' : '235 kcal'), findsOneWidget);
      expect(h.nutritionRepository.meals.length, 1);
      await t.tap(find.text(ar ? 'استكشف بدائل' : 'Explore alternatives'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      final use = find
          .text(ar ? 'استخدم الكميات دي وراجع' : 'Use these amounts and review')
          .last;
      await t.ensureVisible(use);
      await t.pump();
      await shot('within_budget_option');
      await t.tap(use);
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(h.nutritionRepository.meals.length, 1);
      expect(find.text(ar ? '24 سعرة' : '24 kcal'), findsOneWidget);
      await shot('adjusted');
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('meal_review_coach')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pump(const Duration(milliseconds: 400));
      await shot('coach_button');
      expect(find.byKey(const ValueKey('meal_review_coach')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('meal_review_coach')));
      await t.pump(const Duration(seconds: 1));
      expect(sentToCoach!.uid, 'u1');
      expect(sentToCoach!.draft.totals!.energyKcal, closeTo(173, .6));
      expect(h.nutritionRepository.meals.length, 1);

      await t.pumpWidget(const SizedBox());
      await h.dispose();
    });
  }
}
