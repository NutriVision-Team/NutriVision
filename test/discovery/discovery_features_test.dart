import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../support/fixture_image_http.dart';
import 'support/persistence_fixtures.dart';
import 'package:sufradepi/features/achievements/data/persistence/achievement_progress_store.dart';
import 'package:sufradepi/features/recipes/data/persistence/cloud_recipe_favorites.dart';
import 'dart:async';
import 'dart:io';
import '../support/optional_fonts.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:sufradepi/features/recipes/presentation/widgets/discovery_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/recipes/data/datasources/local_recipe_data_source.dart';
import 'package:sufradepi/features/recipes/domain/recipe_catalog_repository.dart';
import 'package:sufradepi/features/recipes/domain/ingredient_recipe_matcher.dart';
import 'package:sufradepi/features/recipes/presentation/screens/recipe_suggestion_screen.dart';
import 'package:sufradepi/features/recipes/presentation/screens/recipe_detail_screen.dart';
import 'package:sufradepi/features/alternatives/domain/alternatives_repository.dart';
import 'package:sufradepi/features/alternatives/presentation/screens/alternatives_screen.dart';
import 'package:sufradepi/features/achievements/domain/achievement_activity.dart';
import 'package:sufradepi/features/achievements/presentation/screens/achievements_screen.dart';

AchievementActivity activity({
  String uid = 'owner',
  Set<String> days = const {},
  bool complete = true,
}) => AchievementActivity(
  userId: uid,
  loggedDays: days,
  mealCount: days.length + (days.length >= 3 ? 2 : 0),
  distinctFoods: days.isEmpty ? const {} : const {'tomato', 'carrot', 'pea'},
  mealTypesByDay: days.isEmpty
      ? const {}
      : {
          (days.toList()..sort()).last: {
            'lunch',
            if (days.length >= 3) ...['breakfast', 'dinner'],
          },
        },
  categoriesByDay: days.isEmpty
      ? const {}
      : {
          (days.toList()..sort()).last: {
            'vegetables': {'tomato', 'carrot', 'pea'},
          },
        },
  categoryDataComplete: complete,
);

class StaticActivityLoader implements AchievementActivityLoader {
  StaticActivityLoader(this.value);
  final AchievementActivity value;
  @override
  Future<AchievementActivity> load(String userId) async => value;
}

class PendingActivityLoader implements AchievementActivityLoader {
  final values = <String, Completer<AchievementActivity>>{};
  @override
  Future<AchievementActivity> load(String userId) =>
      values.putIfAbsent(userId, Completer.new).future;
}

class CaptureAchievements extends AchievementCatalog {
  @override
  Future<List<AchievementRule>> load() async =>
      ((jsonDecode(File('assets/data/achievements.json').readAsStringSync())
                  as Map<String, dynamic>)['achievements']
              as List)
          .map((r) => AchievementRule.fromJson(r as Map<String, dynamic>))
          .toList();
}

class CaptureRecipes extends RecipeCatalogRepository {
  @override
  Future<List<LocalRecipeRecord>> getAll() async =>
      ((jsonDecode(File('assets/data/recipes.json').readAsStringSync())
                  as Map<String, dynamic>)['recipes']
              as List)
          .map((r) => LocalRecipeRecord.fromJson(r as Map<String, dynamic>))
          .toList();
}

class FailingRecipes extends RecipeCatalogRepository {
  @override
  Future<List<LocalRecipeRecord>> getAll() async => throw StateError('offline');
}

Future<void> fonts() async {
  await loadRealFonts();
  for (final entry in <String, List<String>>{
    'Cairo': [
      'Cairo-Regular.ttf',
      'Cairo-SemiBold.ttf',
      'Cairo-Bold.ttf',
      'Cairo-ExtraBold.ttf',
    ],
    'Reem Kufi': ['ReemKufi-SemiBold.ttf', 'ReemKufi-Bold.ttf'],
  }.entries) {
    final loader = FontLoader(entry.key);
    for (final name in entry.value) {
      final bytes = File('assets/fonts/$name').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
  Directory? dir = File(Platform.resolvedExecutable).parent;
  File? icons;
  for (var i = 0; i < 8 && dir != null; i++) {
    final file = File(
      '${dir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (file.existsSync()) {
      icons = file;
      break;
    }
    dir = dir.parent.path == dir.path ? null : dir.parent;
  }
  if (icons == null) throw StateError('Material font unavailable');
  final iconBytes = icons.readAsBytesSync();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(ByteData.view(iconBytes.buffer)))).load();
}

Widget app(
  Widget screen, {
  bool ar = true,
  bool light = false,
  double scale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: Locale(ar ? 'ar' : 'en'),
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  theme: light ? AppTheme.light() : AppTheme.dark(),
  builder: (_, child) => MediaQuery(
    data: MediaQueryData(
      size: const Size(390, 844),
      disableAnimations: true,
      textScaler: TextScaler.linear(scale),
    ),
    child: RepaintBoundary(
      key: const ValueKey('discovery-review'),
      child: child!,
    ),
  ),
  home: screen,
);
Future<void> open(
  WidgetTester tester,
  Widget screen, {
  bool ar = true,
  bool light = false,
  double scale = 1,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  await tester.runAsync(() async {
    await tester.pumpWidget(app(screen, ar: ar, light: light, scale: scale));
    await Future<void>.delayed(const Duration(milliseconds: 80));
  });
  await tester.pump(const Duration(milliseconds: 1000));
  await tester.pump(const Duration(milliseconds: 400));
  // Asset catalog completion can require an extra frame after the future's
  // microtask. Wait for real content, not only an elapsed frame duration.
  for (
    var attempt = 0;
    attempt < 30 &&
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    attempt++
  ) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 100));
  }
  // A cached decoder can finish a later thumbnail one frame after the data.
  // Await actual image streams before comparing glass/backdrop pixels.
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(fonts);
  HttpOverrides? oldOverrides;
  setUp(() {
    oldOverrides = HttpOverrides.current;
    HttpOverrides.global = FixtureImageHttpOverrides();
  });
  tearDown(() => HttpOverrides.global = oldOverrides);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'recipe catalog preserves unknown nutrition and source measures',
    () async {
      final recipes = await RecipeCatalogRepository().getAll();
      expect(recipes.length, 8);
      expect(
        recipes.every((r) => r.nutritionStatus == 'not_calculable_from_source'),
        isTrue,
      );
      expect(recipes.first.ingredients.first.normalizedQuantityGrams, isNull);
      expect(recipes.first.ingredients.first.measure, '1 tbs');
    },
  );
  test(
    'deterministic matching finds Arabic aliases against actual source ingredients',
    () async {
      final recipes = await RecipeCatalogRepository().getAll();
      final matches = IngredientRecipeMatcher.match(
        recipes,
        const RecipeRequest(mealType: 'lunch', ingredients: ['أرز', 'عدس']),
      );
      expect(matches.first.recipe.nameEn, 'Koshari');
      expect(matches.first.matchedInputs.length, 2);
      expect(
        IngredientRecipeMatcher.match(
          recipes,
          const RecipeRequest(mealType: 'dinner', ingredients: ['unicorn']),
        ),
        isEmpty,
      );
      expect(
        IngredientRecipeMatcher.match(
          recipes,
          const RecipeRequest(mealType: 'lunch', ingredients: []),
        ),
        isEmpty,
      );
    },
  );
  test('recipe source-text search does not invent nutrition', () async {
    final all = await RecipeCatalogRepository().getAll();
    expect(
      RecipeCatalogRepository.filter(all, 'شكشوكة').single.nameEn,
      'Shakshuka',
    );
    expect(
      RecipeCatalogRepository.filter(all, 'Broad Beans').length,
      greaterThan(0),
    );
  });
  test('favorites persist and stay isolated per user', () async {
    final prefs = await SharedPreferences.getInstance();
    final a = RecipeFavorites(preferences: prefs, userId: 'a');
    final b = RecipeFavorites(preferences: prefs, userId: 'b');
    await a.setSaved('recipe', true);
    expect(a.read(), {'recipe'});
    expect(b.read(), isEmpty);
    await a.setSaved('recipe', false);
    expect(a.read(), isEmpty);
    expect(
      () => RecipeFavorites(preferences: prefs, userId: ''),
      throwsArgumentError,
    );
  });
  test(
    'all nine comparisons resolve source foods without fabricated grades',
    () async {
      final records = await AlternativesRepository().getAll();
      expect(records.length, 9);
      expect(records.first.comparisons['energyKcal']?.source, 359);
      expect(records.first.comparisons['energyKcal']?.alternative, 366);
      expect(AlternativesRepository.filter(records, 'never-a-food'), isEmpty);
    },
  );
  test(
    'streak tolerates not logging yet today and does not cross missing dates',
    () {
      final a = activity(days: {'2026-11-19', '2026-11-20', '2026-11-21'});
      expect(a.currentStreak('2026-11-22'), 3);
      expect(a.currentStreak('2026-11-23'), 0);
      expect(a.longestStreak, 3);
      expect(AchievementActivity.day('2026-02-30'), isNull);
      expect(AchievementActivity.day('2026-2-3'), isNull);
    },
  );
  test(
    'water unverified, incomplete categories not counted, historical streak retained',
    () async {
      final rules = await AchievementCatalog().load();
      final a = activity(days: {'2026-11-01', '2026-11-02', '2026-11-03'});
      expect(
        a.progress(rules.firstWhere((r) => r.id == 'water_goal_day')),
        isNull,
      );
      expect(a.progress(rules.firstWhere((r) => r.id == 'log_streak_3')), 3);
      expect(a.progress(rules.firstWhere((r) => r.id == 'balanced_day')), 3);
      expect(
        activity(
          complete: false,
        ).progress(rules.firstWhere((r) => r.id == 'veggie_day')),
        isNull,
      );
    },
  );
  testWidgets('local suggestion requires ingredients, not a configured model', (
    tester,
  ) async {
    await open(tester, const RecipeSuggestionScreen(), ar: false);
    await tester.drag(find.byType(ListView).first, const Offset(0, -130));
    await tester.pump();
    await tester.tap(find.text('Suggest'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Add your ingredients'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('ingredient add and deterministic suggestion work without AI', (
    tester,
  ) async {
    await open(tester, const RecipeSuggestionScreen(), ar: false);
    await tester.tap(find.text('+ Add'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField).last, 'rice');
    await tester.tap(find.widgetWithText(TextButton, 'Add'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.drag(find.byType(ListView).first, const Offset(0, -130));
    await tester.pump();
    await tester.tap(find.text('Suggest'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Show all recipes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('unknown recipe does not log or show fake success', (
    tester,
  ) async {
    var logged = false;
    await open(
      tester,
      RecipeDetailScreen(
        recipeId: 'themealdb_52963',
        onLogRequested: (_) async {
          logged = true;
        },
      ),
      ar: false,
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Review my amounts and log'),
    );
    expect(button.onPressed, isNotNull);
    expect(logged, isFalse);
    expect(find.text('Calories unknown'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('favorite saves only after storage success', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final store = RecipeFavorites(preferences: prefs, userId: 'owner');
    await open(
      tester,
      RecipeDetailScreen(
        recipeId: 'themealdb_52963',
        favorites: store,
        repository: CaptureRecipes(),
      ),
      ar: false,
    );
    await tester.tap(find.text('Save'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.read(), {'themealdb_52963'});
    expect(find.text('Saved'), findsOneWidget);
  });
  testWidgets('retry state appears when recipe catalog fails', (tester) async {
    await open(
      tester,
      RecipeSuggestionScreen(repository: FailingRecipes()),
      ar: false,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
  testWidgets('unmatched alternatives query shows honest empty state', (
    tester,
  ) async {
    await open(tester, const AlternativesScreen(), ar: false);
    await tester.enterText(find.byType(TextField), 'chips');
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('No verified comparison'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('account switch discards old achievement result', (tester) async {
    final loader = PendingActivityLoader();
    await tester.pumpWidget(
      app(
        AchievementsScreen(
          catalog: CaptureAchievements(),
          userId: 'first',
          todayKey: '2026-11-22',
          loader: loader,
        ),
        ar: false,
      ),
    );
    await tester.pump();
    await tester.pumpWidget(
      app(
        AchievementsScreen(
          catalog: CaptureAchievements(),
          userId: 'second',
          todayKey: '2026-11-22',
          loader: loader,
        ),
        ar: false,
      ),
    );
    loader.values['first']!.complete(
      activity(uid: 'first', days: {'2026-11-22'}),
    );
    await tester.pump();
    expect(find.text('Days in a row'), findsNothing);
    loader.values['second']!.complete(activity(uid: 'second'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Days in a row'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Arabic progress pairs isolate current and target LTR', (
    tester,
  ) async {
    await open(
      tester,
      AchievementsScreen(
        catalog: CaptureAchievements(),
        userId: 'owner',
        todayKey: '2026-11-22',
        loader: StaticActivityLoader(activity(days: {'2026-11-22'})),
      ),
    );
    final pairs = find.byType(DiscoveryProgressPair);
    expect(pairs, findsWidgets);
    final texts = find.descendant(of: pairs, matching: find.byType(Text));
    for (final element in texts.evaluate()) {
      expect(Directionality.of(element), TextDirection.ltr);
    }
    final firstPair = find.descendant(
      of: pairs.first,
      matching: find.byType(Text),
    );
    expect(tester.widget<Text>(firstPair.at(0)).data, '١');
    expect(tester.widget<Text>(firstPair.at(2)).data, '١٤');
    expect(
      tester.getRect(firstPair.at(0)).left,
      lessThan(tester.getRect(firstPair.at(2)).left),
    );
  });
  testWidgets(
    'last achievement scrolls above floating nav and remains tappable at large text',
    (tester) async {
      await open(
        tester,
        AchievementsScreen(
          catalog: CaptureAchievements(),
          userId: 'owner',
          todayKey: '2026-11-22',
          loader: StaticActivityLoader(activity()),
        ),
        ar: false,
        scale: 1.6,
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -4000));
      await tester.pump(const Duration(seconds: 1));
      final last = find.text('Water Goal');
      expect(last, findsOneWidget);
      expect(
        tester.getRect(last).bottom,
        lessThan(tester.getRect(find.byType(FloatingGlassNavBar)).top),
      );
      await tester.tap(last);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byWidgetPredicate((w) => w is AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('last recipe route is tappable above nav at large text', (
    tester,
  ) async {
    final recipes = await tester.runAsync(
      () => RecipeCatalogRepository().getAll(),
    );
    final last = recipes!.last;
    final router = GoRouter(
      initialLocation: '/recipes',
      routes: [
        GoRoute(
          path: '/recipes',
          builder: (_, _) => const RecipeSuggestionScreen(),
        ),
        GoRoute(
          path: '/recipe/:id',
          builder: (_, state) =>
              RecipeDetailScreen(recipeId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        theme: AppTheme.dark(),
        builder: (_, child) => MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
            textScaler: TextScaler.linear(1.6),
          ),
          child: child!,
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(seconds: 1));
    for (var i = 0; i < 12; i++) {
      final state = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      state.position.jumpTo(state.position.maxScrollExtent);
      await tester.pump(const Duration(milliseconds: 100));
    }
    final name = find.text(last.nameEn);
    expect(name, findsOneWidget);
    expect(
      tester.getRect(name).bottom,
      lessThan(tester.getRect(find.byType(FloatingGlassNavBar)).top),
    );
    await tester.tap(name);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RecipeDetailScreen), findsOneWidget);
    expect(
      GoRouterState.of(
        tester.element(find.byType(RecipeDetailScreen)),
      ).pathParameters['id'],
      last.id,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'cloud favorite control awaits persistence and displays account sync wording',
    (tester) async {
      final backend = MemoryFavoritesBackend();
      final store = CloudRecipeFavorites(
        userId: 'owner',
        activeUserId: () => 'owner',
        backend: backend,
        catalog: CaptureRecipes(),
      );
      await open(
        tester,
        RecipeDetailScreen(
          recipeId: 'themealdb_52963',
          favorites: store,
          repository: CaptureRecipes(),
        ),
        ar: false,
      );
      await tester.tap(find.text('Save'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Saved'), findsOneWidget);
      expect(backend.operations.length, 1);
      await tester.drag(find.byType(ListView).first, const Offset(0, -4000));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text('Favorites sync with your account.', skipOffstage: false),
        findsOneWidget,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/cloud_recipe_saved_en.png'),
      );
    },
  );
  testWidgets(
    'only a new observed achievement transition receives reveal animation',
    (tester) async {
      final backend = MemoryAchievementsBackend();
      final store = AchievementProgressStore(
        userId: 'owner',
        activeUserId: () => 'owner',
        backend: backend,
      );
      final rules = await tester.runAsync(() => AchievementCatalog().load());
      await store.synchronize(activity(), rules!);
      await open(
        tester,
        AchievementsScreen(
          catalog: CaptureAchievements(),
          key: UniqueKey(),
          userId: 'owner',
          todayKey: '2026-11-22',
          loader: StaticActivityLoader(activity(days: {'2026-11-22'})),
          progressStore: store,
        ),
        ar: false,
      );
      final reveals = tester.widgetList<DiscoveryUnlockReveal>(
        find.byType(DiscoveryUnlockReveal),
      );
      expect(reveals.any((r) => r.animate), isTrue);
      await tester.tap(find.text('First Meal'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('First recorded by Sufra'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/cloud_achievement_observed_en.png'),
      );
      await tester.tap(find.text('OK'));
      await tester.pump(const Duration(milliseconds: 500));
      await open(
        tester,
        AchievementsScreen(
          catalog: CaptureAchievements(),
          key: UniqueKey(),
          userId: 'owner',
          todayKey: '2026-11-22',
          loader: StaticActivityLoader(activity(days: {'2026-11-22'})),
          progressStore: store,
        ),
        ar: false,
      );
      expect(
        tester
            .widgetList<DiscoveryUnlockReveal>(
              find.byType(DiscoveryUnlockReveal),
            )
            .every((r) => !r.animate),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
  final screens = <String, Widget>{
    'recipes': const RecipeSuggestionScreen(),
    'detail': RecipeDetailScreen(
      recipeId: 'themealdb_52963',
      repository: CaptureRecipes(),
    ),
    'alternatives': const AlternativesScreen(),
    'achievements': AchievementsScreen(
      catalog: CaptureAchievements(),
      userId: 'owner',
      todayKey: '2026-11-22',
      loader: StaticActivityLoader(activity()),
    ),
  };
  for (final entry in screens.entries) {
    testWidgets('${entry.key} Arabic dark golden', (tester) async {
      await open(tester, entry.value);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${entry.key}_ar.png'),
      );
      expect(tester.takeException(), isNull);
    });
    for (final config in [
      (false, true, 1.6, 'en_light_large'),
      (true, true, 1.6, 'ar_light_large'),
      (true, false, 1.0, 'ar_dark'),
      (false, false, 1.6, 'en_dark_large'),
    ]) {
      testWidgets('${entry.key} controlled ${config.$4} has loaded content', (
        tester,
      ) async {
        await open(
          tester,
          entry.value,
          ar: config.$1,
          light: config.$2,
          scale: config.$3,
        );
        if (entry.key == 'detail') {
          for (
            var attempt = 0;
            attempt < 20 &&
                find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
            attempt++
          ) {
            await tester.runAsync(() async {
              await Future<void>.delayed(const Duration(milliseconds: 100));
            });
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.byType(DiscoveryList), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        if (entry.key == 'alternatives') {
          final scroll = tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position;
          scroll.jumpTo((scroll.pixels + 600).clamp(0, scroll.maxScrollExtent));
          await tester.pump();
        }
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('discovery-review')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra/verification/discovery_${entry.key}_${config.$4}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
