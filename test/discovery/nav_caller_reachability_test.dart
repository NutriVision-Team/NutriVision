import 'package:sufradepi/features/alternatives/domain/alternatives_repository.dart';
import '../support/optional_fonts.dart';
import '../support/fixture_image_http.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/recipes/data/datasources/local_recipe_data_source.dart';
import 'package:sufradepi/features/recipes/domain/recipe_catalog_repository.dart';
import 'package:sufradepi/features/recipes/presentation/screens/recipe_suggestion_screen.dart';
import 'package:sufradepi/features/recipes/presentation/screens/recipe_detail_screen.dart';
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

class FailingRecipes extends RecipeCatalogRepository {
  @override
  Future<List<LocalRecipeRecord>> getAll() async => throw StateError('offline');
}

Future<void> fonts() async {
  await loadPrivateReviewFonts();
  for (final entry in {
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
      size: Size(
        double.parse(Platform.environment['SUFRA_REVIEW_WIDTH'] ?? '390'),
        double.parse(Platform.environment['SUFRA_REVIEW_HEIGHT'] ?? '844'),
      ),
      disableAnimations: true,
      textScaler: TextScaler.linear(scale),
    ),
    child: child!,
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
  tester.view.physicalSize = Size(
    double.parse(Platform.environment['SUFRA_REVIEW_WIDTH'] ?? '390'),
    double.parse(Platform.environment['SUFRA_REVIEW_HEIGHT'] ?? '844'),
  );
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(app(screen, ar: ar, light: light, scale: scale));
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  });
  await tester.pump(const Duration(milliseconds: 1000));
  await tester.pump(const Duration(milliseconds: 400));
}

class ReadyRecipes extends RecipeCatalogRepository {
  ReadyRecipes(this.records);
  final List<LocalRecipeRecord> records;
  @override
  Future<List<LocalRecipeRecord>> getAll() async => records;
}

class ReadyAchievements extends AchievementCatalog {
  ReadyAchievements(this.rules);
  final List<AchievementRule> rules;
  @override
  Future<List<AchievementRule>> load() async => rules;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(fonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = FixtureImageHttpOverrides();
  });
  tearDown(() => HttpOverrides.global = null);
  for (final lang in ['ar', 'en']) {
    for (final feature in [
      'recipes',
      'detail',
      'alternatives',
      'achievements',
    ]) {
      testWidgets('$feature $lang 320x6402x end', (t) async {
        t.view.physicalSize = Size(
          double.parse(Platform.environment['SUFRA_REVIEW_WIDTH'] ?? '320'),
          double.parse(Platform.environment['SUFRA_REVIEW_HEIGHT'] ?? '640'),
        );
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final records = await t.runAsync(
          () => RecipeCatalogRepository().getAll(),
        );
        final rules = await t.runAsync(() => AchievementCatalog().load());
        final repo = ReadyRecipes(records!);
        final alternatives = AlternativesRepository();
        if (feature == 'alternatives') {
          final loaded = await t.runAsync(alternatives.getAll);
          expect(
            loaded,
            isNotEmpty,
            reason:
                'Real local alternative records loaded before layout review',
          );
        }
        final screen = switch (feature) {
          'recipes' => RecipeSuggestionScreen(repository: repo),
          'detail' => RecipeDetailScreen(
            recipeId: 'themealdb_52963',
            repository: repo,
          ),
          'alternatives' => AlternativesScreen(repository: alternatives),
          _ => AchievementsScreen(
            catalog: ReadyAchievements(rules!),
            userId: 'owner',
            todayKey: '2026-11-22',
            loader: StaticActivityLoader(activity()),
          ),
        };
        await t.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('pixel'),
            child: app(screen, ar: lang == 'ar', scale: 2),
          ),
        );
        await t.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await t.pump(const Duration(seconds: 1));
        await t.pump(const Duration(seconds: 1));
        for (
          var j = 0;
          j < 30 &&
              find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
          j++
        ) {
          await t.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(
          find.byType(CircularProgressIndicator),
          findsNothing,
          reason: 'loaded fixture, not loading-only pixels',
        );
        expect(t.takeException(), isNull);
        if (feature == 'alternatives') {
          final rawKeys = RegExp(r'\b(?:energyKcal|fiberG|proteinG|fatG)\b');
          expect(
            t
                .widgetList<Text>(find.byType(Text))
                .any((text) => rawKeys.hasMatch(text.data ?? '')),
            isFalse,
            reason: 'Visible comparison prose uses localized nutrient labels',
          );
        }
        for (var i = 0; i < 15; i++) {
          final scrolls = find.byType(Scrollable);
          if (scrolls.evaluate().isEmpty) break;
          final states = scrolls
              .evaluate()
              .map((e) => (e as StatefulElement).state as ScrollableState)
              .where(
                (s) =>
                    s.axisDirection == AxisDirection.down ||
                    s.axisDirection == AxisDirection.up,
              );
          if (states.isEmpty) break;
          final p = states.first.position;
          p.jumpTo(p.maxScrollExtent);
          await t.pump(const Duration(milliseconds: 100));
        }
        await t.pump(const Duration(seconds: 2));
        expect(t.takeException(), isNull);
        if (feature != 'detail') {
          final navTop = t.getRect(find.byType(FloatingGlassNavBar)).top;
          final list = find.byType(ListView).first;
          final lastText = find
              .descendant(of: list, matching: find.byType(Text))
              .last;
          // A long final paragraph at 2x text may start above the fold; its end must be visible.
          expect(t.getRect(lastText).bottom, greaterThan(0));
          expect(t.getRect(lastText).bottom, lessThan(navTop));
        }
        final b = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('pixel')),
        );
        await t.runAsync(() async {
          final im = await b.toImage();
          final d = await im.toByteData(format: ui.ImageByteFormat.png);
          File(
            '/downloads/sufra/verification/nav_discovery_${feature}_${lang}_end.png',
          ).writeAsBytesSync(d!.buffer.asUint8List());
          im.dispose();
        });
      });
    }
  }
}
