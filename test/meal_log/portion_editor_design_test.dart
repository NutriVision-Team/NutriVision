import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/food_catalog/data/local_food_repository.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_review_screen.dart';
import 'package:sufradepi/core/widgets/app_buttons.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('portion live preview $lang $dark $scale', (t) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.reset);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final h = await Harness.signedIn();
          final before = h.nutritionRepository.meals.length;
          final food = await t.runAsync(
            () => LocalFoodRepository().getFoodById('usda_sr_168878'),
          );
          final key = GlobalKey();
          await t.pumpWidget(
            RepaintBoundary(
              key: key,
              child: h.wrap(
                MealReviewScreen(portion: FoodPortion(food!, 150)),
                locale: Locale(lang),
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              ),
            ),
          );
          await t.runAsync(() async {
            await precacheImage(
              const ResizeImage(
                AssetImage('assets/images/generated_food/168878.png'),
                width: 56,
              ),
              key.currentContext!,
            );
          });
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          await t.tap(find.text('150.0 ${lang == 'ar' ? 'جم' : 'g'}').first);
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          final input = find.byKey(const ValueKey('portion-grams'));
          expect(input, findsOneWidget);
          await t.tap(find.byKey(const ValueKey('portion-preset-200')));
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          expect((t.widget<TextField>(input).controller!).text, '200.0');
          expect(find.text('260'), findsOneWidget);
          Future<void> snap(String stage) async {
            expect(t.takeException(), isNull);
            await t.runAsync(() async {
              final image =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '/downloads/sufra-recovered/portion1520_${lang}_${dark ? 'dark' : 'light'}_${scale}_$stage.png',
              ).writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }

          await snap('top');
          if (lang == 'ar' && dark && scale == 1.0) {
            var frame = 0;
            for (final preset in [50, 100, 150, 200]) {
              final target = find.byKey(ValueKey('portion-preset-$preset'));
              final gesture = await t.startGesture(t.getCenter(target));
              for (var n = 0; n < 3; n++) {
                await t.pump(const Duration(milliseconds: 67));
                await snap('motion${(frame++).toString().padLeft(3, '0')}');
              }
              await gesture.up();
              for (var n = 0; n < 12; n++) {
                await t.pump(const Duration(milliseconds: 67));
                await snap('motion${(frame++).toString().padLeft(3, '0')}');
              }
            }
          }
          await t.enterText(input, '٠');
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          expect(
            t
                .widget<GradientButton>(
                  find.byKey(const ValueKey('portion-apply')),
                )
                .onPressed,
            isNull,
          );
          await t.enterText(input, '١٢٥٫٥');
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          expect(find.text('163'), findsOneWidget);
          await t.ensureVisible(find.byKey(const ValueKey('portion-apply')));
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          await snap('apply');
          await t.tap(find.byKey(const ValueKey('portion-apply')));
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          expect(find.byKey(const ValueKey('portion-editor')), findsNothing);
          expect(
            find.text('125.5 ${lang == 'ar' ? 'جم' : 'g'}'),
            findsOneWidget,
          );
          expect(h.nutritionRepository.meals.length, before);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
          await h.dispose();
        });
      }
    }
  }
}
