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
  setUpAll(loadRealFonts);
  testWidgets(
    'Eight Egyptian source detail screens retain identity after photo pilot',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await Harness.signedIn();
      final repo = RecipeCatalogRepository();
      final recipes = await t.runAsync(repo.getAll);
      expect(recipes!.map((r) => r.id).toSet(), EgyptianDishArt.ids);
      final dir = Platform.environment['SUFRA_DISH_CAPTURE'];
      for (final recipe in recipes) {
        final key = GlobalKey();
        await t.runAsync(() async {
          await t.pumpWidget(
            RepaintBoundary(
              key: key,
              child: h.wrap(
                RecipeDetailScreen(
                  key: ValueKey(recipe.id),
                  recipeId: recipe.id,
                  repository: repo,
                ),
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 250));
        });
        await t.pump(const Duration(seconds: 1));
        expect(find.byType(RecipeSourceImage), findsOneWidget);
        expect(find.byType(EgyptianDishArt), findsNothing);
        final assets = t
            .widgetList<Image>(find.byType(Image))
            .map((i) => i.image)
            .whereType<AssetImage>()
            .map((a) => a.assetName);
        expect(
          assets.any(
            (a) =>
                a.contains('reference_food/') || a.contains('generated_food/'),
          ),
          isTrue,
        );
        expect(t.takeException(), isNull);
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
