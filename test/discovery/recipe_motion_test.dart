import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/features/recipes/presentation/screens/recipe_detail_screen.dart';
import 'package:sufradepi/features/recipes/data/datasources/local_recipe_data_source.dart';
import 'discovery_features_test.dart' show CaptureRecipes;

import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final dark in [true, false]) {
    testWidgets('Recipe real interaction motion $dark', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await Harness.signedIn();
      final recipe = (await t.runAsync(
        () => LocalRecipeDataSource().getAll(),
      ))!.first;
      final key = GlobalKey();
      await t.runAsync(() async {
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: h.wrap(
              RecipeDetailScreen(
                recipeId: recipe.id,
                repository: CaptureRecipes(),
              ),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              additionalRoutes: [
                GoRoute(
                  path: '/meal/:id',
                  builder: (c, s) => Scaffold(
                    body: Text(
                      'Detail ${s.pathParameters['id']} ${s.uri.queryParameters['date']}',
                    ),
                  ),
                ),
                GoRoute(
                  path: '/log',
                  builder: (_, _) => const Scaffold(body: Text('Add route')),
                ),
              ],
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await t.pump();
      final row = find.byType(FilterChip).first;
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(2, 2));
      for (var n = 0; n < 52; n++) {
        if (n == 12) await mouse.moveTo(t.getCenter(row));
        if (n == 24) await mouse.down(t.getCenter(row));
        if (n == 46) await mouse.cancel();
        await t.pump(const Duration(milliseconds: 90));
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra-recovered/recipe1733_${dark ? 'dark' : 'light'}_${n.toString().padLeft(3, '0')}.png',
          ).writeAsBytes(b!.buffer.asUint8List());
          im.dispose();
        });
      }
      await mouse.removePointer();
      expect(t.takeException(), isNull);
      await t.tap(row);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(t.widget<FilterChip>(row).selected, isTrue);
      await t.pumpWidget(const SizedBox());
      await h.dispose();
    });
  }
}
