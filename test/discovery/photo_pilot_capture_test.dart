import 'dart:convert';
import '../features/home/home_design_capture_test.dart'
    show SourceImageOverrides;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/egyptian_dish_art.dart';
import 'package:sufradepi/features/recipes/presentation/screens/recipe_detail_screen.dart';
import 'package:sufradepi/features/recipes/domain/recipe_catalog_repository.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(() async {
    await loadRealFonts();
    final path = Platform.environment['SUFRA_RECIPE_IMAGE_MANIFEST'];
    if (path != null) {
      HttpOverrides.global = SourceImageOverrides(
        (jsonDecode(File(path).readAsStringSync()) as Map)
            .cast<String, String>(),
      );
    }
  });
  tearDownAll(() => HttpOverrides.global = null);
  testWidgets(
    'Supplied HTML koshari cutout and reference motion in actual detail screen',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      if (Platform.environment['SUFRA_RECIPE_IMAGE_MANIFEST'] == null) {
        return;
      }
      final h = await Harness.signedIn();
      final repo = RecipeCatalogRepository();
      final recipes = await t.runAsync(repo.getAll);
      expect(recipes!.map((r) => r.id).toSet(), EgyptianDishArt.ids);
      final dir = Platform.environment['SUFRA_DISH_CAPTURE'];
      for (final recipe in recipes.where((r) => r.id == 'themealdb_53027')) {
        final key = GlobalKey();
        await t.pumpWidget(h.wrap(const SizedBox()));
        await t.runAsync(() async {
          await precacheImage(
            const AssetImage('assets/images/reference_food/koshari.png'),
            t.element(find.byType(MaterialApp)),
          );
        });

        await t.runAsync(() async {
          await t.pumpWidget(
            RepaintBoundary(
              key: key,
              child: h.wrap(
                Builder(
                  builder: (c) => MediaQuery(
                    data: MediaQuery.of(c).copyWith(
                      disableAnimations:
                          Platform.environment['SUFRA_CUTOUT_MOTION'] == null,
                    ),
                    child: RecipeDetailScreen(
                      key: ValueKey(recipe.id),
                      recipeId: recipe.id,
                      repository: repo,
                    ),
                  ),
                ),
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 250));
        });
        await t.pump(const Duration(seconds: 1));
        expect(find.byType(EgyptianDishArt), findsNothing);
        expect(t.takeException(), isNull);
        final motionDirectory = Platform.environment['SUFRA_CUTOUT_MOTION'];
        if (motionDirectory != null) {
          // Capture a complete reference3.6secondcycle plus endpoints.
          for (var i = 0; i <= 24; i++) {
            await t.pump(const Duration(milliseconds: 150));
            await t.runAsync(() async {
              final image =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File(
                '$motionDirectory/frame_${i.toString().padLeft(3, '0')}.png',
              ).writeAsBytesSync(data!.buffer.asUint8List());
              image.dispose();
            });
          }
        }

        if (dir != null) {
          await t.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            File(
              '$dir/${recipe.id}.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      await t.pumpWidget(const SizedBox.shrink());
      await h.dispose();
    },
  );
}
