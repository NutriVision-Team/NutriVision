import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_recipe_panel.dart';
import 'package:sufradepi/features/recipes/domain/recipe_catalog_repository.dart';
import 'package:sufradepi/features/recipes/data/datasources/local_recipe_data_source.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;

class BlockedRecipes extends RecipeCatalogRepository {
  @override
  Future<List<LocalRecipeRecord>> getAll() async =>
      throw const RecipeLicenseException();
}

class FailedRecipes extends RecipeCatalogRepository {
  @override
  Future<List<LocalRecipeRecord>> getAll() async => throw StateError('offline');
}

void main() {
  setUpAll(loadRealFonts);
  for (final locale in ['ar', 'en']) {
    testWidgets(
      'local ingredient cards $locale are bounded and open verified recipe',
      (t) async {
        t.view.physicalSize = const Size(320, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final repository = RecipeCatalogRepository();
        await t.runAsync(() => repository.getAll());
        final key = GlobalKey();
        String? opened;
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => Scaffold(
                body: SingleChildScrollView(
                  child: CoachRecipePanel(repository: repository),
                ),
              ),
            ),
            GoRoute(
              path: '/recipe/:id',
              builder: (_, s) {
                opened = s.pathParameters['id'];
                return const Scaffold(body: Text('recipe detail'));
              },
            ),
          ],
        );
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: router,
              theme: AppTheme.light(),
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
            ),
          ),
        );
        await t.tap(find.byKey(const ValueKey('coach_recipe_lookup')));
        await t.pumpAndSettle();
        await t.enterText(
          find.byKey(const ValueKey('coach_recipe_ingredients')),
          locale == 'ar' ? 'رز، عدس، xyzunknown' : 'rice, lentils, xyzunknown',
        );
        await t.pump();
        await t.ensureVisible(
          find.byKey(const ValueKey('coach_recipe_search')),
        );
        await t.tap(find.byKey(const ValueKey('coach_recipe_search')));
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 600)),
        );
        await t.pumpAndSettle();
        expect(find.textContaining('xyzunknown'), findsWidgets);
        expect(find.byType(Chip), findsWidgets);
        expect(
          find.byIcon(Icons.menu_book_outlined).evaluate().length,
          lessThanOrEqualTo(3),
        );
        expect(t.takeException(), isNull);
        await t.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('/downloads/sufra').createSync(recursive: true);
          File(
            '/downloads/sufra/coach_recipes_${locale}_0830.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
        await t.ensureVisible(find.byIcon(Icons.menu_book_outlined).first);
        await t.tap(find.byIcon(Icons.menu_book_outlined).first);
        await t.pumpAndSettle();
        expect(opened, isNotNull);
        expect(find.text('recipe detail'), findsOneWidget);
        router.dispose();
      },
    );
  }
  testWidgets('sourced total time enables only known-time recipes', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    final repository = RecipeCatalogRepository();
    await t.runAsync(() => repository.getAll());
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CoachRecipePanel(repository: repository),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.byKey(const ValueKey('coach_recipe_lookup')));
    await t.pumpAndSettle();
    await t.tap(find.text('60 min'));
    await t.pump();
    await t.ensureVisible(find.byKey(const ValueKey('coach_recipe_search')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('coach_recipe_search')));
    await t.pumpAndSettle();
    expect(find.textContaining('No matching ingredients'), findsOneWidget);
    await t.ensureVisible(find.text('90 min'));
    await t.pumpAndSettle();
    await t.tap(find.text('90 min'));
    await t.pump();
    await t.ensureVisible(find.byKey(const ValueKey('coach_recipe_search')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('coach_recipe_search')));
    await t.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('coach_recipe_card_themealdb_53030')),
      findsOneWidget,
    );
    expect(find.textContaining('Source total: 70 minutes'), findsOneWidget);
    await t.ensureVisible(find.textContaining('Source total: 70 minutes'));
    await t.pumpAndSettle();
    await t.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await t.pump();
    await t.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        '/downloads/sufra/coach_feteer_time_0856.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });

    await t.ensureVisible(
      find.byKey(const ValueKey('coach_recipe_card_themealdb_53030')),
    );
    await t.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('coach_recipe_card_themealdb_53028')),
      findsNothing,
    );
  });
  for (final blocked in [true, false]) {
    testWidgets('catalog ${blocked ? 'license' : 'read'} failure is honest', (
      t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CoachRecipePanel(
                repository: blocked ? BlockedRecipes() : FailedRecipes(),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.byKey(const ValueKey('coach_recipe_lookup')));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey('coach_recipe_ingredients')),
        'rice',
      );
      await t.pump();
      await t.ensureVisible(find.byKey(const ValueKey('coach_recipe_search')));
      await t.tap(find.byKey(const ValueKey('coach_recipe_search')));
      await t.pumpAndSettle();
      expect(
        find.textContaining(
          blocked ? 'development-only' : 'Could not load recipes',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.menu_book_outlined), findsNothing);
    });
  }
}
