import 'package:sufradepi/core/widgets/catalog_food_art.dart';
import 'package:sufradepi/data/repositories/food_repository.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/food_catalog/data/local_food_repository.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/manual_food_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/food_search_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/cubit/food_search_cubit.dart';
import 'package:sufradepi/features/progress/presentation/screens/weight_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/stats_screen.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import '../features/progress/progress_test.dart' as f;
import '../features/progress/weight_edit_test.dart' show EditableWeights;
import 'package:sufradepi/data/models/weight_log_model.dart';

Future<void> shot(WidgetTester t, GlobalKey k, String file) async {
  await t.runAsync(() async {
    final image =
        await (k.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage();
    final b = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '/downloads/sufra/verification/$file.png',
    ).writeAsBytes(b!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(loadRealFonts);
  test(
    'actual catalog categories and staples have source-backed entries and stale-safe search',
    () async {
      final r = LocalFoodRepository();
      final all = await r.browseFoods();
      expect(all.length, 101);
      final grains = await r.browseFoods(category: 'grains');
      expect(grains, isNotEmpty);
      expect(grains.every((f) => f.category == 'grains'), isTrue);
      final staples = await r.browseFoods(egyptianStaples: true);
      expect(staples, isNotEmpty);
      expect(staples.length, lessThan(all.length));
      final c = FoodSearchCubit(r, debounce: Duration.zero);
      await c.browse(category: 'legumes');
      expect(c.state.foods.every((f) => f.category == 'legumes'), isTrue);
      c.search('فول');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(c.state.foods, isNotEmpty);
      await c.close();
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets('food search categories and manual provenance at scale$scale', (
      t,
    ) async {
      t.view.physicalSize = const Size(320, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final key = GlobalKey();
      FoodCatalogModel? picked;
      final repository = LocalFoodRepository();
      await t.runAsync(() => repository.browseFoods());
      final c = FoodSearchCubit(repository);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (ctx, _) => RepositoryProvider<FoodRepository>.value(
              value: c.repository,
              child: RepaintBoundary(
                key: key,
                child: const FoodSearchScreen(selectOnly: true),
              ),
            ),
          ),
        ],
      );
      await t.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.dark(),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (ctx, ch) => MediaQuery(
            data: MediaQuery.of(
              ctx,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: ch!,
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(
        () => (c.repository as LocalFoodRepository).browseFoods(),
      );
      await t.tap(find.text('كل الأصناف'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(find.byType(CatalogFoodArt), findsWidgets);
      expect(t.takeException(), isNull);
      await shot(t, key, 'search_categories_${scale.toInt()}');
      await t.scrollUntilVisible(
        find.text('أضف صنف يدوي'),
        600,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
        maxScrolls: 30,
      );
      await t.ensureVisible(find.text('أضف صنف يدوي'));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('أضف صنف يدوي'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(find.byType(ManualFoodScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      // A standalone picker verifies that missing nutrients stay null and no write occurs.
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () async {
                picked = await Navigator.of(ctx).push<FoodCatalogModel>(
                  MaterialPageRoute(
                    builder: (_) => const ManualFoodScreen(selectOnly: true),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.tap(find.text('open'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.enterText(find.byType(TextField).at(0), 'My label');
      await t.enterText(find.byType(TextField).at(1), 'Package test only');
      await t.enterText(find.byType(TextField).at(2), '150');
      await t.scrollUntilVisible(
        find.byType(Checkbox),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.byType(Checkbox));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.ensureVisible(find.byType(FilledButton));
      await t.tap(find.byType(FilledButton));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(picked, isNotNull);
      expect(picked!.nutritionPer100g!['calories'], 150);
      expect(picked!.nutritionPer100g!['protein'], isNull);
      expect(picked!.verificationStatus, 'user_entered_unverified');
      await c.close();
      await t.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('Weight expanded history and real date picker scale$scale', (
      t,
    ) async {
      t.view.physicalSize = const Size(320, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final key = GlobalKey();
      final r = EditableWeights()
        ..weight = [
          WeightLogModel(
            weightId: 'w',
            weightKg: 90,
            recordedAt: DateTime(2026, 11, 22),
            dateKey: '2026-11-22',
          ),
        ];
      await f.pumpScreen(
        t,
        RepaintBoundary(
          key: key,
          child: WeightScreen(waterWeightRepository: r),
        ),
        f.FakeNutritionRepository(),
      );
      await t.ensureVisible(find.byType(ExpansionTile));
      await t.tap(find.byType(ExpansionTile));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.ensureVisible(find.byIcon(Icons.edit_outlined));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await shot(t, key, 'weight_history_${scale.toInt()}');
      await t.tap(find.byIcon(Icons.edit_outlined));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.tap(find.byIcon(Icons.calendar_today));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(t.takeException(), isNull);
      await shot(t, key, 'weight_date_${scale.toInt()}');
      await t.tap(find.text('21').last);
      await t.tap(find.text('حسنًا'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(find.text('2026-11-21'), findsWidgets);
      await t.enterText(find.byType(TextField), '88');
      await t.tap(find.text('احفظ'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(r.weight.single.dateKey, '2026-11-21');
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('Stats source macro coverage responsive scale$scale', (
      t,
    ) async {
      t.view.physicalSize = const Size(320, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final k = GlobalKey();
      final n = f.FakeNutritionRepository()..logs = [f.log('2026-11-22')];
      await f.pumpScreen(
        t,
        RepaintBoundary(
          key: k,
          child: StatsScreen(
            waterWeightRepository: f.FakeWaterWeightRepository(),
          ),
        ),
        n,
      );
      await t.pump(const Duration(seconds: 1));
      for (
        var attempt = 0;
        find.text('متوسط أداء الماكروز').evaluate().isEmpty && attempt < 10;
        attempt++
      ) {
        await t.drag(find.byType(ListView).first, const Offset(0, -250));
        await t.pump(const Duration(milliseconds: 350));
      }
      expect(find.text('متوسط أداء الماكروز'), findsOneWidget);
      await t.ensureVisible(find.byType(ExpansionTile));
      await t.drag(find.byType(ListView).first, const Offset(0, -250));
      await t.pump();
      await t.tap(find.text('متوسط أداء الماكروز'));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('متوسط الهدف:'), findsNWidgets(3));
      for (var i = 0; i < 5; i++) {
        final state = t.state<ScrollableState>(find.byType(Scrollable).first);
        state.position.jumpTo(state.position.maxScrollExtent);
        await t.pump(const Duration(milliseconds: 100));
      }

      expect(t.takeException(), isNull);
      await shot(t, k, 'stats_macros_${scale.toInt()}');
      await t.pumpWidget(const SizedBox.shrink());
    });
  }
}
