import 'dart:io';
import 'package:sufradepi/features/alternatives/domain/alternatives_repository.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/recipes/data/datasources/local_recipe_data_source.dart';
import 'package:sufradepi/features/recipes/presentation/screens/recipe_detail_screen.dart';
import 'package:sufradepi/features/recipes/presentation/screens/quantified_recipe_screen.dart';
import 'package:sufradepi/features/alternatives/presentation/screens/alternatives_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'discovery_features_test.dart' show CaptureRecipes;

class ReadyAlternatives extends AlternativesRepository {
  ReadyAlternatives(this.records);
  final List<FoodAlternative> records;
  @override
  Future<List<FoodAlternative>> getAll() async => records;
}

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('recipe design $lang $dark $scale', (t) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          final r = (await t.runAsync(
            () => LocalRecipeDataSource().getAll(),
          ))!.first;
          final key = GlobalKey();
          final alternatives = await t.runAsync(
            () => AlternativesRepository().getAll(),
          );
          for (final name in ['detail', 'quantity', 'alternatives']) {
            await t.pumpWidget(
              RepaintBoundary(
                key: key,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                  locale: Locale(lang),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (c, ch) => MediaQuery(
                    data: MediaQuery.of(c).copyWith(
                      disableAnimations: true,
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: ch!,
                  ),
                  home: switch (name) {
                    'detail' => RecipeDetailScreen(
                      recipeId: r.id,
                      repository: CaptureRecipes(),
                    ),
                    'quantity' => QuantifiedRecipeScreen(recipe: r),
                    _ => AlternativesScreen(
                      repository: ReadyAlternatives(alternatives!),
                    ),
                  },
                ),
              ),
            );
            await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 120)),
            );
            await t.pump();
            await t.pump(const Duration(seconds: 1));
            await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 250)),
            );
            await t.pump(const Duration(milliseconds: 100));
            Future<void> shot(String part) async {
              expect(t.takeException(), isNull);
              await t.runAsync(() async {
                for (final e in find.byType(Image).evaluate()) {
                  await precacheImage((e.widget as Image).image, e);
                }
                final im =
                    await (key.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage();
                final b = await im.toByteData(format: ui.ImageByteFormat.png);
                await File(
                  '/downloads/sufra-recovered/recipe1725_${name}_${lang}_${dark ? 'dark' : 'light'}_${scale}_$part.png',
                ).writeAsBytes(b!.buffer.asUint8List());
                im.dispose();
              });
            }

            await t.runAsync(() async {
              for (final e in find.byType(Image).evaluate()) {
                await precacheImage((e.widget as Image).image, e);
              }
            });
            await t.pump();
            await shot('top');
            await t.drag(find.byType(ListView).first, const Offset(0, -650));
            await t.pump(const Duration(milliseconds: 400));
            await shot('scroll');
            await t.pumpWidget(const SizedBox());
          }
        });
      }
    }
  }
}
