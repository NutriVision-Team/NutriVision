import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/features/food_catalog/data/local_food_repository.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('Home saved meals $lang $dark $scale', (t) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.reset);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final h = await Harness.signedIn();
          final key = GlobalKey();
          final food = await t.runAsync(
            () => LocalFoodRepository().getFoodById('usda_sr_168878'),
          );
          final meal = FoodPortion(food!, 150).toMeal(
            uid: 'u1',
            id: 'catalog-rice',
            at: DateTime(2026, 11, 22, 12),
            mealType: 'suhoor',
          );
          final custom = MealEntryModel.fromMap('custom-rice', {
            ...meal.toMap(),
            'mealId': 'custom-rice',
            'title': 'Family rice recipe',
            'createdAt': null,
            'updatedAt': null,
            'mealType': 'iftar',
          });
          h.nutritionRepository.meals = [meal, custom];
          await t.pumpWidget(
            RepaintBoundary(
              key: key,
              child: h.wrap(
                HomeScreen(clock: () => DateTime(2026, 11, 22, 12)),
                locale: Locale(lang),
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                additionalRoutes: [
                  GoRoute(
                    path: '/meal/:id',
                    builder: (_, s) => Scaffold(
                      body: Text('details:${s.pathParameters['id']}'),
                    ),
                  ),
                ],
              ),
            ),
          );
          await t.runAsync(() async {
            await precacheImage(
              const ResizeImage(
                AssetImage('assets/images/generated_food/168878.png'),
                width: 62,
              ),
              key.currentContext!,
            );
            await Future<void>.delayed(const Duration(milliseconds: 300));
          });
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          final target = find.byKey(const ValueKey('home-meal-catalog-rice'));
          await t.scrollUntilVisible(
            target,
            300,
            scrollable: find.byType(Scrollable).first,
            maxScrolls: 40,
          );
          await t.pump(const Duration(seconds: 1));
          await t.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          });
          await t.pump();
          expect(
            find.text(
              lang == 'en' ? 'Cooked white rice, no added oil' : food.name,
            ),
            findsWidgets,
          );
          expect(find.text(lang == 'en' ? 'Suhoor' : 'سحور'), findsWidgets);
          expect(find.text('Family rice recipe'), findsOneWidget);
          expect(t.takeException(), isNull);
          await t.runAsync(() async {
            final im =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final b = await im.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '/downloads/sufra-recovered/homemeal1538_${lang}_${dark ? 'dark' : 'light'}_$scale.png',
            ).writeAsBytes(b!.buffer.asUint8List());
            im.dispose();
          });
          await t.tap(target);
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          expect(find.text('details:catalog-rice'), findsOneWidget);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
          await h.dispose();
        });
      }
    }
  }
}
