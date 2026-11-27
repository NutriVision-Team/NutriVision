import 'dart:io';
import 'package:sufradepi/core/widgets/saved_catalog_label.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/repositories/food_repository.dart';
import 'package:sufradepi/features/food_catalog/data/local_food_repository.dart';
import 'package:sufradepi/features/meal_log/presentation/cubit/food_search_cubit.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_log_hub_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/food_search_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/food_detail_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_review_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_detail_screen.dart';
import 'package:sufradepi/features/diary/presentation/screens/diary_screen.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  test(
    'changing category retains the active query and filters actual bundled rows',
    () async {
      final repo = LocalFoodRepository();
      await repo.browseFoods();
      final c = FoodSearchCubit(repo, debounce: Duration.zero);
      c.search('rice');
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(c.state.foods, isNotEmpty);
      c.filter(category: 'vegetables');
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(c.state.query, 'rice');
      expect(c.state.foods.every((f) => f.category == 'vegetables'), isTrue);
      c.filter(category: 'grains');
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(c.state.query, 'rice');
      expect(c.state.foods, isNotEmpty);
      await c.close();
    },
  );
  testWidgets('catalog labels localize without overwriting a custom name', (
    t,
  ) async {
    final h = await Harness.signedIn();
    final record = await t.runAsync(
      () => LocalFoodRepository().getFoodById('usda_sr_168878'),
    );
    final item = FoodPortion(record!, 150)
        .toMeal(
          uid: 'u1',
          id: 'x',
          at: DateTime(2026, 11, 22),
          mealType: 'lunch',
        )
        .items
        .single;
    final custom = MealItemModel.fromMap({
      ...item.toMap(),
      'foodName': 'My family rice',
    });
    await t.pumpWidget(
      h.wrap(
        Scaffold(
          body: Column(
            children: [
              SavedCatalogLabel(item: item),
              SavedCatalogLabel(item: custom),
            ],
          ),
        ),
        locale: const Locale('en'),
      ),
    );
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await t.pump();
    expect(find.text('Cooked white rice, no added oil'), findsOneWidget);
    expect(find.text('My family rice'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
    await h.dispose();
  });
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        for (final screen in [
          'hub',
          'search',
          'food',
          'review',
          'diary',
          'detail',
        ]) {
          testWidgets('food screens $screen $lang $dark $scale', (t) async {
            t.view.physicalSize = const Size(390, 844);
            t.view.devicePixelRatio = 1;
            t.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(t.view.reset);
            addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
            final h = await Harness.signedIn();
            final repo = LocalFoodRepository();
            final food = await t.runAsync(
              () => repo.getFoodById('usda_sr_168878'),
            );
            final portion = FoodPortion(food!, 150);
            final meal = portion.toMeal(
              uid: 'u1',
              id: 'fixture',
              at: DateTime(2026, 11, 22, 14),
              mealType: 'lunch',
            );
            h.nutritionRepository.meals = [meal];
            final content = switch (screen) {
              'hub' => const MealLogHubScreen(),
              'search' => const FoodSearchScreen(),
              'food' => FoodDetailScreen(food: food),
              'review' => MealReviewScreen(portion: portion),
              'diary' => DiaryScreen(initialDate: DateTime(2026, 11, 22)),
              _ => MealDetailScreen(mealId: meal.mealId, dateKey: meal.dateKey),
            };
            final key = GlobalKey();
            await t.runAsync(() async {
              await t.pumpWidget(
                RepositoryProvider<FoodRepository>.value(
                  value: repo,
                  child: RepaintBoundary(
                    key: key,
                    child: h.wrap(
                      content,
                      locale: Locale(lang),
                      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                    ),
                  ),
                ),
              );
              await Future<void>.delayed(const Duration(milliseconds: 120));
            });
            await t.runAsync(() async {
              for (final width in [56, 136, 110]) {
                await precacheImage(
                  ResizeImage(
                    const AssetImage('assets/images/generated_food/168878.png'),
                    width: width,
                  ),
                  key.currentContext!,
                );
              }
              await Future<void>.delayed(const Duration(milliseconds: 80));
            });
            await t.pump();
            await t.pump(const Duration(seconds: 2));
            await t.runAsync(() async {
              await Future<void>.delayed(const Duration(milliseconds: 250));
            });
            await t.pump();
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
                  '/downloads/sufra-recovered/food1455_${screen}_${lang}_${dark ? 'dark' : 'light'}_${scale}_$stage.png',
                ).writeAsBytes(data!.buffer.asUint8List());
                image.dispose();
              });
            }

            await snap('top');
            if (screen == 'search') {
              await t.enterText(find.byType(TextField), 'rice');
              await t.pump(const Duration(milliseconds: 350));
              await t.runAsync(() async {
                await Future<void>.delayed(const Duration(milliseconds: 50));
              });
              await t.pump();
              final state = t
                  .element(find.byType(TextField))
                  .read<FoodSearchCubit>()
                  .state;
              expect(state.query, 'rice');
              expect(state.foods, isNotEmpty);
              await snap('query');
              final egypt = find.byKey(
                const ValueKey('food-category-egyptian'),
              );
              await Scrollable.ensureVisible(
                t.element(egypt),
                alignment: .5,
                duration: Duration.zero,
              );
              await t.pump();
              expect(egypt.hitTestable(), findsOneWidget);
              await snap('category-scroll');
              final grains = find.byKey(const ValueKey('food-category-grains'));
              await t.ensureVisible(grains);
              await t.tap(grains);
              await t.pump(const Duration(milliseconds: 350));
              await t.runAsync(() async {
                await Future<void>.delayed(const Duration(milliseconds: 40));
              });
              await t.pump();
              final filtered = t
                  .element(find.byType(TextField))
                  .read<FoodSearchCubit>()
                  .state;
              expect(filtered.query, 'rice');
              expect(filtered.foods, isNotEmpty);
              expect(
                filtered.foods.every((f) => f.category == 'grains'),
                isTrue,
              );
              expect(
                t.widget<TextField>(find.byType(TextField)).controller!.text,
                'rice',
              );
              await t.tap(find.byKey(const ValueKey('clear-food-query')));
              await t.pump();
              await t.runAsync(() async {
                await Future<void>.delayed(const Duration(milliseconds: 30));
              });
              await t.pump();
              expect(
                t.widget<TextField>(find.byType(TextField)).controller!.text,
                isEmpty,
              );
              expect(
                t
                    .element(find.byType(TextField))
                    .read<FoodSearchCubit>()
                    .state
                    .query,
                isEmpty,
              );
            }
            if (screen == 'hub' && lang == 'ar' && dark && scale == 1.0) {
              final target = find.text('بالصوت أو الكتابة');
              final gesture = await t.startGesture(t.getCenter(target));
              for (var frame = 0; frame < 8; frame++) {
                await t.pump(const Duration(milliseconds: 35));
                await snap('press$frame');
              }
              await gesture.cancel();
              for (var frame = 8; frame < 16; frame++) {
                await t.pump(const Duration(milliseconds: 35));
                await snap('press$frame');
              }
            }
            final vertical = find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .first;
            if (screen != 'search') {
              await t.drag(vertical, const Offset(0, -480));
              await t.pump(const Duration(seconds: 1));
              await snap('scroll');
            }
            await t.pumpWidget(const SizedBox.shrink());
            await h.dispose();
          });
        }
      }
    }
  }
}
