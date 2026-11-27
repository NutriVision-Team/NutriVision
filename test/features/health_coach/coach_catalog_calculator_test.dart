import 'package:flutter/services.dart';
import 'package:sufradepi/features/health_coach/domain/coach_reviewed_explanation.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/data/repositories/food_repository.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_food_calculator_panel.dart';
import 'package:sufradepi/features/health_coach/domain/coach_catalog_tools.dart';
import 'package:sufradepi/features/recipes/domain/recipe_catalog_repository.dart';

class Foods implements FoodRepository {
  final fixture = const FoodCatalogModel(
    foodId: 'synthetic',
    name: 'عدس مطبوخ، اختبار محلي',
    foodState: 'cooked',
    source: 'Synthetic fixture only',
    nutritionPer100g: {'calories': 100, 'protein': null},
  );
  @override
  Future<List<FoodCatalogModel>> searchFood(String query) async => [fixture];
  @override
  Future<FoodCatalogModel?> getFoodById(String id) async =>
      id == fixture.foodId ? fixture : null;
}

void main() {
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final family in ['Cairo', 'Tajawal']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family-Regular.ttf'));
      await loader.load();
    }
  });
  test(
    'typed catalog bridge uses source scaling and preserves missing data',
    () async {
      final tools = CoachCatalogTools(
        foods: Foods(),
        recipes: RecipeCatalogRepository(),
      );
      expect((await tools.searchFoods('عدس')).single.foodId, 'synthetic');
      final draft = await tools.calculate({'synthetic': 150});
      expect(draft.totals!.energyKcal, 150);
      expect(draft.totals!.proteinG, isNull);
      await expectLater(tools.calculate({}), throwsArgumentError);
      await expectLater(tools.calculate({'missing': 100}), throwsStateError);
      await expectLater(
        tools.calculate({'synthetic': double.nan}),
        throwsArgumentError,
      );
    },
  );
  testWidgets(
    'Coach local calculator search select weigh result clear with no AI provider',
    (t) async {
      t.view.physicalSize = const Size(430, 1100);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final key = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Text('اختبار محلي ببيانات وهمية، مش رد من النموذج'),
                    CoachFoodCalculatorPanel(repository: Foods()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('احسب وجبتك بالمقادير'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('coach_food_query')), 'عدس');
      await t.tap(find.text('ابحث في الكتالوج'));
      await t.pumpAndSettle();
      await t.tap(find.text('عدس مطبوخ، اختبار محلي'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('coach_food_grams')), '١٥٠');
      await t.ensureVisible(find.text('أضف للحساب'));
      await t.tap(find.text('أضف للحساب'));
      await t.pumpAndSettle();
      expect(find.text('150.0 kcal'), findsOneWidget);
      expect(find.text('بروتين: غير معروف'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/downloads/sufra-recovered/coach1305-local-calculator-synthetic.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await t.ensureVisible(find.text('امسح الحساب'));
      await t.tap(find.text('امسح الحساب'));
      await t.pumpAndSettle();
      expect(find.text('150.0 kcal'), findsNothing);
    },
  );
  testWidgets(
    'reviewed explanation sends only exact recomputed draft after approval',
    (t) async {
      t.view.physicalSize = const Size(430, 1100);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final key = GlobalKey();
      final requests = <String>[];
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Text('اختبار محلي ببيانات وهمية، مش رد من النموذج'),
                    CoachFoodCalculatorPanel(
                      repository: Foods(),
                      onExplain: (draft) async {
                        requests.add(reviewedCalculationQuestion(draft, 'ar'));
                        expect(draft.totals!.energyKcal, 150);
                        expect(draft.totals!.proteinG, isNull);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('احسب وجبتك بالمقادير'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('coach_food_query')), 'عدس');
      await t.tap(find.text('ابحث في الكتالوج'));
      await t.pumpAndSettle();
      await t.tap(find.text('عدس مطبوخ، اختبار محلي'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('coach_food_grams')), '١٥٠');
      await t.ensureVisible(find.text('أضف للحساب'));
      await t.tap(find.text('أضف للحساب'));
      await t.pumpAndSettle();
      expect(find.text('150.0 kcal'), findsOneWidget);
      expect(find.text('بروتين: غير معروف'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.ensureVisible(
        find.byKey(const ValueKey('coach_explain_calculation')),
      );
      await t.tap(find.byKey(const ValueKey('coach_explain_calculation')));
      await t.pumpAndSettle();
      expect(requests, isEmpty);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('Synthetic fixture only'),
        ),
        findsOneWidget,
      );
      await t.tap(find.text('رجوع'));
      await t.pumpAndSettle();
      expect(requests, isEmpty);
      await t.tap(find.byKey(const ValueKey('coach_explain_calculation')));
      await t.pumpAndSettle();
      await t.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/downloads/sufra-recovered/coach2057-reviewed-explanation.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await t.tap(find.byKey(const ValueKey('coach_confirm_explanation')));
      await t.pumpAndSettle();
      expect(requests, hasLength(1));
      expect(requests.single, contains('بيانات حساب منفصلة'));
      expect(requests.single, isNot(contains('kcal')));

      expect(requests.single.length, lessThanOrEqualTo(1000));
      await t.ensureVisible(find.text('امسح الحساب'));
      await t.tap(find.text('امسح الحساب'));
      await t.pumpAndSettle();
      expect(find.text('150.0 kcal'), findsNothing);
    },
  );
}
