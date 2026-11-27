import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/recipes/presentation/screens/recipe_detail_screen.dart';
import 'package:sufradepi/features/food_catalog/data/local_food_repository.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/food_detail_screen.dart';
import '../discovery/discovery_features_test.dart' show fonts, app;
import '../goldens/milestone1_screens_test.dart' show Harness;

void main() {
  setUpAll(fonts);
  testWidgets(
    'generated illustrations on actual recipe and catalog detail screens',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await Harness.signedIn();
      final screens = <String, Widget>{
        for (final id in ['52963', '53028', '53029', '53030', '53031'])
          'recipe_$id': RecipeDetailScreen(recipeId: 'themealdb_$id'),
      };
      for (final id in [
        '2259796',
        '790018',
        '2346400',
        '2684441',
        '746782',
        '1750341',
      ]) {
        final f = await t.runAsync(
          () => LocalFoodRepository().getFoodById('usda_foundation_$id'),
        );
        screens['food_$id'] = h.wrap(FoodDetailScreen(food: f!));
      }
      for (final e in screens.entries) {
        final k = GlobalKey();
        await t.pumpWidget(
          RepaintBoundary(
            key: k,
            child: e.key.startsWith('recipe') ? app(e.value) : e.value,
          ),
        );
        await t.pump();
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 600)),
        );
        await t.pump(const Duration(seconds: 1));
        expect(t.takeException(), isNull);
        final dir = Platform.environment['SUFRA_FOOD_CAPTURE'];
        if (dir != null) {
          await t.runAsync(() async {
            final im =
                await (k.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final b = await im.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '$dir/${e.key}.png',
            ).writeAsBytes(b!.buffer.asUint8List());
            im.dispose();
          });
        }
        if (e.key == 'recipe_52963' && dir != null) {
          // At 1s above; next samples cover the rest of the 3.6s float cycle.
          for (final ms in [800, 900, 900]) {
            await t.pump(Duration(milliseconds: ms));
            await t.runAsync(() async {
              final im =
                  await (k.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final b = await im.toByteData(format: ui.ImageByteFormat.png);
              await File(
                '$dir/motion_$ms${t.binding.clock.now().microsecondsSinceEpoch}.png',
              ).writeAsBytes(b!.buffer.asUint8List());
              im.dispose();
            });
            expect(t.takeException(), isNull);
          }
        }
        await t.pumpWidget(const SizedBox());
      }
      await h.dispose();
    },
  );
}
