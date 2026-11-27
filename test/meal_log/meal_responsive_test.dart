import 'package:sufradepi/core/widgets/app_buttons.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_detail_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_review_screen.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;
import 'catalog_flow_test.dart' show catalog;

Future<void> shot(WidgetTester t, String name) async {
  final p = Platform.environment['SUFRA_MEAL_PIXEL'];
  if (p == null) return;
  final b = t.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('meal-shot')),
  );
  await t.runAsync(() async {
    final i = await b.toImage();
    final d = await i.toByteData(format: ui.ImageByteFormat.png);
    File('$p-$name.png').writeAsBytesSync(d!.buffer.asUint8List());
    i.dispose();
  });
}

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final detail in [false, true]) {
        testWidgets(
          'meal ${detail ? 'detail' : 'review'} $lang 320px scale$scale no overflow',
          (t) async {
            t.view.devicePixelRatio = 1;
            t.view.physicalSize = const Size(320, 640);
            addTearDown(() {
              t.view.resetPhysicalSize();
              t.view.resetDevicePixelRatio();
            });
            final h = await Harness.signedIn();
            final fixture = catalog();
            final meal = FoodPortion(fixture, 150).toMeal(
              uid: 'u1',
              id: 'detail',
              at: DateTime(2026, 11, 22, 14),
              mealType: 'lunch',
            );
            h.nutritionRepository.meals = [meal];
            final screen = detail
                ? MealDetailScreen(mealId: meal.mealId, dateKey: meal.dateKey)
                : MealReviewScreen(portion: FoodPortion(fixture, 150));
            await t.pumpWidget(
              h.wrap(
                Builder(
                  builder: (c) => Localizations.override(
                    context: c,
                    locale: Locale(lang),
                    child: MediaQuery(
                      data: MediaQuery.of(
                        c,
                      ).copyWith(textScaler: TextScaler.linear(scale)),
                      child: RepaintBoundary(
                        key: const ValueKey('meal-shot'),
                        child: screen,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await t.pump();
            await t.pump(const Duration(seconds: 1));
            await shot(t, '${detail ? 'detail' : 'review'}-$lang-$scale-top');
            if (!detail && scale == 2) {
              final l = await AppLocalizations.delegate.load(Locale(lang));
              expect(
                t.getSize(find.text(l.mealReviewTitle)).width,
                greaterThan(240),
              );
            }
            expect(t.takeException(), isNull);
            final scroll = t.state<ScrollableState>(
              find.byType(Scrollable).first,
            );
            for (var i = 0; i < 5; i++) {
              scroll.position.jumpTo(scroll.position.maxScrollExtent);
              await t.pump();
            }
            await t.pump();
            await shot(
              t,
              '${detail ? 'detail' : 'review'}-$lang-$scale-bottom',
            );
            expect(t.takeException(), isNull);
            if (!detail) {
              final l = await AppLocalizations.delegate.load(Locale(lang));
              final btn = find.widgetWithText(GradientButton, l.mealSave);
              final macro = find.text('${l.foodFat}: 12.0 ${l.foodGramUnit}');
              expect(macro, findsOneWidget);
              expect(t.getRect(macro).bottom, lessThan(t.getRect(btn).top));
              final label = t.getRect(find.text(l.mealSave));
              final box = t.getRect(btn);
              expect(label.left, greaterThanOrEqualTo(box.left));
              expect(label.right, lessThanOrEqualTo(box.right));
              expect(label.top, greaterThanOrEqualTo(box.top));
              expect(label.bottom, lessThanOrEqualTo(box.bottom));
              await t.tap(btn);
              await t.pump();
              await t.pump(const Duration(milliseconds: 500));
              expect(h.nutritionRepository.meals, hasLength(2));
              expect(h.nutritionRepository.meals.last.totalCalories, 300);
              expect(h.nutritionRepository.meals.last.userId, 'u1');
            }
            await t.pumpWidget(const SizedBox.shrink());
            await h.dispose();
          },
        );
      }
    }
  }
}
