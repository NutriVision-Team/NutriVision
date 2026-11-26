import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/features/recipes/data/datasources/local_recipe_data_source.dart';
import 'package:sufradepi/features/recipes/presentation/screens/quantified_recipe_screen.dart';
import 'package:sufradepi/features/meal_log/domain/meal_review_input.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/features/recipes/presentation/widgets/discovery_widgets.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final (lang, scale) in [('en', 1.0), ('ar', 2.0)]) {
    testWidgets(
      'quantified recipe $lang scale$scale matches catalog grams and explicit yield before review',
      (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final recipe = LocalRecipeRecord(
          id: 'r',
          sourceMealId: 'r',
          nameAr: 'وصفة اختبار',
          nameEn: 'fixture recipe',
          tags: const [],
          ingredients: const [
            LocalRecipeIngredient(
              name: 'Rice',
              measure: 'original source measure',
            ),
          ],
          instructions: const ['fixture only'],
          nutritionStatus: 'not_calculable_from_source',
          source: const LocalRecipeSource(
            provider: 'fixture',
            mealId: 'r',
            licenseNote: 'fixture',
            url: 'https://example.invalid/source',
          ),
        );
        MealReviewInput? review;
        final key = GlobalKey();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => RepaintBoundary(
                key: key,
                child: QuantifiedRecipeScreen(recipe: recipe),
              ),
            ),
            GoRoute(
              path: '/food-pick',
              builder: (c, _) => TextButton(
                onPressed: () => c.pop(
                  const FoodCatalogModel(
                    foodId: 'rice',
                    name: 'Catalog rice',
                    source: 'fixture',
                    nutritionPer100g: {'calories': 100, 'protein': 2},
                  ),
                ),
                child: const Text('choose food'),
              ),
            ),
            GoRoute(
              path: '/meal-review',
              builder: (_, s) {
                review = s.extra as MealReviewInput;
                return const Text('review fixture');
              },
            ),
          ],
        );
        await t.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.dark(),
            locale: Locale(lang),
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        );
        await t.pumpAndSettle();
        final l = await AppLocalizations.delegate.load(Locale(lang));
        await t.scrollUntilVisible(
          find.byType(FilledButton),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        await t.scrollUntilVisible(
          find.text(lang == 'ar' ? 'أرز' : 'Rice'),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(
          t.element(find.text(lang == 'ar' ? 'أرز' : 'Rice')),
          alignment: .3,
        );
        await t.pump();
        await t.tap(find.text(lang == 'ar' ? 'أرز' : 'Rice'));
        await t.pumpAndSettle();
        await t.tap(find.text('choose food'));
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField), '400');
        await t.tap(find.text(l.weightLogSave));
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.text('${l.recipeYield}: 1.0'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await t.tap(find.text('${l.recipeYield}: 1.0'));
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField), '4');
        await t.tap(find.text(l.weightLogSave));
        await t.pumpAndSettle();
        expect(
          find.text(
            '${discoveryNumber(t.element(find.byType(QuantifiedRecipeScreen)), 100)} ${l.foodKcal}',
          ),
          findsOneWidget,
        );
        expect(review, isNull);
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await im.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra/verification/quantified_recipe_$lang.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          im.dispose();
        });
        await t.ensureVisible(find.byType(FilledButton));
        await t.tap(find.byType(FilledButton));
        await t.pumpAndSettle();
        expect(review, isNotNull);
        expect(review!.draft.portions.single.grams, 100);
        expect(review!.notes, contains(l.recipeYourVersion));
        expect(review!.draft.canSave, isTrue);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
        router.dispose();
      },
    );
  }
}
