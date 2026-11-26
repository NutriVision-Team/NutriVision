import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_screen.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'package:sufradepi/features/recipes/presentation/screens/recipe_detail_screen.dart';
import 'package:sufradepi/features/recipes/domain/recipe_catalog_repository.dart';
import 'screens_smoke_test.dart'
    show SmokeNutritionRepository, FakeCoachDictation;
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final config in [
    ('ar', ThemeMode.light, 1.0),
    ('en', ThemeMode.dark, 1.0),
    ('ar', ThemeMode.light, 2.0),
  ]) {
    testWidgets(
      'full coach recipe to actual detail ${config.$1} ${config.$2} ${config.$3}',
      (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        t.platformDispatcher.textScaleFactorTestValue = config.$3;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final repo = RecipeCatalogRepository();
        await t.runAsync(() => repo.getAll());
        final c = CoachCubit(
          userId: 'qa',
          store: SessionCoachStore(ownerUid: 'qa', currentUid: () => 'qa'),
          nutrition: SmokeNutritionRepository(),
          locale: config.$1,
        );
        await c.load();
        final key = GlobalKey();
        final router = GoRouter(
          initialLocation: '/coach',
          routes: [
            GoRoute(
              path: '/coach',
              builder: (_, __) => Scaffold(
                body: CoachScreen(cubit: c, dictation: FakeCoachDictation()),
              ),
            ),
            GoRoute(
              path: '/recipe/:id',
              builder: (_, s) => RecipeDetailScreen(
                recipeId: s.pathParameters['id']!,
                repository: repo,
              ),
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
              darkTheme: AppTheme.dark(),
              themeMode: config.$2,
              locale: Locale(config.$1),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
            ),
          ),
        );
        await t.pump(const Duration(seconds: 1));
        await t.ensureVisible(
          find.byKey(const ValueKey('coach_expand_actions')),
        );
        await t.pump(const Duration(milliseconds: 400));
        await t.tap(find.byKey(const ValueKey('coach_expand_actions')));
        await t.pump(const Duration(milliseconds: 300));
        expect(find.byIcon(Icons.water_drop_outlined), findsWidgets);
        await t.ensureVisible(
          find.byKey(const ValueKey('coach_expand_actions')),
        );
        await t.pump(const Duration(milliseconds: 400));
        await t.tap(find.byKey(const ValueKey('coach_expand_actions')));
        await t.pump(const Duration(milliseconds: 300));
        Future<void> settleAssets() async {
          await t.runAsync(() async {
            for (final e in find.byType(Image).evaluate()) {
              await precacheImage((e.widget as Image).image, e);
            }
          });
          await t.pump(const Duration(milliseconds: 350));
        }

        Future<void> capture(String position) async {
          await settleAssets();
          await t.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            Directory('/downloads/sufra').createSync(recursive: true);
            File(
              '/downloads/sufra/coach_recipe_full_${config.$1}_${config.$2.name}_${config.$3.toInt()}_$position.png',
            ).writeAsBytesSync(data!.buffer.asUint8List());
            image.dispose();
          });
        }

        await t.ensureVisible(
          find.byKey(const ValueKey('coach_recipe_lookup')),
        );
        await t.tap(find.byKey(const ValueKey('coach_recipe_lookup')));
        await t.pump(const Duration(milliseconds: 350));
        await t.enterText(
          find.byKey(const ValueKey('coach_recipe_ingredients')),
          config.$1 == 'ar' ? 'رز، عدس' : 'rice, lentils',
        );
        await t.pump();
        await t.ensureVisible(
          find.byKey(const ValueKey('coach_recipe_search')),
        );
        await t.pump(const Duration(milliseconds: 500));
        await t.dragUntilVisible(
          find.byKey(const ValueKey('coach_recipe_search')),
          find.byType(Scrollable).first,
          const Offset(0, -80),
        );
        await t.pump(const Duration(milliseconds: 300));
        await t.tap(find.byKey(const ValueKey('coach_recipe_search')));
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await t.pump(const Duration(milliseconds: 350));
        await t.ensureVisible(
          find.byKey(const ValueKey('coach_recipe_card_themealdb_53027')),
        );
        await capture('card');
        expect(t.takeException(), isNull);
        await t.ensureVisible(
          find.byKey(const ValueKey('coach_recipe_open_themealdb_53027')),
        );
        await t.pump(const Duration(milliseconds: 500));
        await Scrollable.ensureVisible(
          t.element(
            find.byKey(const ValueKey('coach_recipe_open_themealdb_53027')),
          ),
          alignment: .85,
        );
        await t.pump(const Duration(milliseconds: 300));
        await capture('card_action');
        await t.tap(
          find.byKey(const ValueKey('coach_recipe_open_themealdb_53027')),
        );
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)),
        );
        await t.pump(const Duration(seconds: 1));
        await t.pump(const Duration(milliseconds: 500));
        expect(find.byType(RecipeDetailScreen), findsOneWidget);
        await capture('detail');
        expect(t.takeException(), isNull);
        final chips = find.byType(FilterChip);
        for (
          var attempt = 0;
          chips.evaluate().isEmpty && attempt < 8;
          attempt++
        ) {
          await t.drag(find.byType(Scrollable).first, const Offset(0, -250));
          await t.pump(const Duration(milliseconds: 350));
        }
        await t.ensureVisible(chips.first);
        await t.pump(const Duration(milliseconds: 350));
        await t.tap(chips.first);
        await t.pump(const Duration(milliseconds: 300));
        expect((t.widget(chips.first) as FilterChip).selected, true);
        await capture('ingredient_checked');
        await t.pumpWidget(const SizedBox());
        router.dispose();
        await c.close();
      },
    );
  }
}
