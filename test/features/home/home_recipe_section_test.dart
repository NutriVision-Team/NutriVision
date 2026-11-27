import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/home/presentation/widgets/home_recipe_section.dart';
import 'package:sufradepi/features/recipes/domain/recipe_catalog_repository.dart';
import 'package:sufradepi/features/recipes/data/datasources/local_recipe_data_source.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

class Source extends RecipeCatalogRepository {
  Source(this.records, {this.fail = false});
  final List<LocalRecipeRecord> records;
  final bool fail;
  int calls = 0;
  @override
  Future<List<LocalRecipeRecord>> getAll() async {
    calls++;
    if (fail) throw const RecipeLicenseException();
    return records;
  }
}

const recipe = LocalRecipeRecord(
  id: 'verified-source-7',
  sourceMealId: '7',
  nameAr: 'طبق من المصدر',
  nameEn: 'Source dish',
  tags: [],
  ingredients: [],
  instructions: [],
  nutritionStatus: 'not_calculable_from_source',
  source: LocalRecipeSource(
    provider: 'TheMealDB',
    mealId: '7',
    licenseNote: 'development',
    url: 'https://example.test/recipe',
  ),
);

void main() {
  for (final language in ['ar', 'en']) {
    testWidgets(
      'Home recipe $language uses source names, no fake calories and real details navigation',
      (t) async {
        t.view.physicalSize = const Size(320, 740);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final source = Source([recipe]);
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                body: SingleChildScrollView(
                  child: HomeRecipeSection(repository: source),
                ),
              ),
            ),
            GoRoute(
              path: '/recipe/:id',
              builder: (_, s) =>
                  Scaffold(body: Text('details:${s.pathParameters['id']}')),
            ),
            GoRoute(
              path: '/recipes',
              builder: (_, _) => const Scaffold(body: Text('recipes')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await t.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.dark(),
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        );
        await t.pump(const Duration(seconds: 1));
        await t.pump(const Duration(milliseconds: 500));
        expect(
          find.text(language == 'ar' ? 'طبق من المصدر' : 'Source dish'),
          findsOneWidget,
        );
        expect(find.textContaining('380'), findsNothing);
        expect(t.takeException(), isNull);
        expect(source.calls, 1);
        await t.tap(
          find.text(language == 'ar' ? 'طبق من المصدر' : 'Source dish'),
        );
        await t.pump(const Duration(seconds: 1));
        await t.pump(const Duration(milliseconds: 500));
        expect(find.text('details:verified-source-7'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'Home categories filter actual source metadata and do not classify missing metadata',
    (t) async {
      final chicken = LocalRecipeRecord.fromJson({
        'id': 'chicken',
        'names': {'en': 'Source chicken'},
        'category': 'Chicken',
        'source': {'provider': 'TheMealDB'},
      });
      final source = Source([recipe, chicken]);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeRecipeSection(repository: source),
            ),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Source dish'), findsOneWidget);
      expect(find.text('Source chicken'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('home-category-Chicken')));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Source chicken'), findsOneWidget);
      expect(find.text('Source dish'), findsNothing);
      await t.tap(find.byKey(const ValueKey('home-category-all')));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Source dish'), findsOneWidget);
      expect(source.calls, 1);
      expect(t.takeException(), isNull);
    },
  );
  for (final fail in [false, true]) {
    testWidgets('Home recipe empty/license failure $fail stays honest', (
      t,
    ) async {
      final source = Source([], fail: fail);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HomeRecipeSection(repository: source)),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 500));
      expect(
        find.text('Recipe suggestions are unavailable in this build.'),
        findsOneWidget,
      );
      expect(find.byType(Image), findsNothing);
      expect(t.takeException(), isNull);
    });
  }
}
