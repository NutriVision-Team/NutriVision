import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/features/alternatives/presentation/screens/alternatives_screen.dart';
import 'package:sufradepi/features/auth/presentation/screens/welcome_screen.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_screen.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_log_hub_screen.dart';
import 'package:sufradepi/features/planner/data/planner_repository.dart';
import 'package:sufradepi/features/planner/domain/weekly_plan_generator.dart';
import 'package:sufradepi/features/planner/presentation/cubit/planner_cubit.dart';
import 'package:sufradepi/features/planner/presentation/screens/planner_screen.dart';
import 'package:sufradepi/features/premium/presentation/screens/premium_screen.dart';
import 'package:sufradepi/features/profile_setup/presentation/screens/profile_setup_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/report_screen.dart';
import 'package:sufradepi/features/ramadan/data/ramadan_settings_store.dart';
import 'package:sufradepi/features/ramadan/presentation/cubit/ramadan_cubit.dart';
import 'package:sufradepi/features/ramadan/presentation/screens/ramadan_screen.dart';
import 'package:sufradepi/features/recipes/presentation/screens/recipe_suggestion_screen.dart';
import 'package:sufradepi/features/shared/coming_soon_screen.dart';
import 'package:sufradepi/features/shopping/data/shopping_repository.dart';
import 'package:sufradepi/features/shopping/presentation/cubit/shopping_cubit.dart';
import 'package:sufradepi/features/shopping/presentation/screens/shopping_screen.dart';
import 'package:sufradepi/features/dashboard/presentation/destination_hubs.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import 'package:sufradepi/features/diary/presentation/screens/diary_screen.dart';

import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;
import '../planning/screens_smoke_test.dart'
    show SmokeNutritionRepository, FakeCoachDictation;
import '../planning/support/planning_memory_firestore.dart';

const _sizes = <String, Size>{
  'phone360': Size(360, 800),
  'phone390': Size(390, 844),
  'tabletP': Size(800, 1280),
  'tabletL': Size(1280, 800),
  'desktop': Size(1440, 900),
};
const _variants = <String, (String, bool)>{
  'ar-dark': ('ar', false),
  'en-light': ('en', true),
};

void main() {
  setUpAll(loadRealFonts);
  final only = Platform.environment['ONLY'];
  final screens = <String, Widget Function(Harness)>{
    'home': (_) => HomeScreen(clock: () => DateTime(2026, 11, 22, 18)),
    'diary': (_) => DiaryScreen(initialDate: DateTime(2026, 11, 22)),
    'profile': (_) => const ProfileHubScreen(),
    'meals': (_) => const MealsHubScreen(),
    'log': (_) => const MealLogHubScreen(),
    'welcome': (_) => const WelcomeScreen(),
    'setup': (_) => const ProfileSetupScreen(),
    'premium': (_) => const PremiumScreen(),
    'comingsoon': (_) => const ComingSoonScreen(),
    'report': (_) => const ReportScreen(),
    'recipes': (_) => const RecipeSuggestionScreen(),
    'alternatives': (_) => const AlternativesScreen(),
  };

  for (final e in screens.entries) {
    if (only != null && !only.split(',').contains(e.key)) continue;
    testWidgets('matrix ${e.key}', (t) async {
      final h = await Harness.signedIn();
      await _run(t, e.key, h, (_) => e.value(h), () => true);
      await h.dispose();
    });
  }

  Future<void> planning(
    String name,
    WidgetTester t,
    Widget Function(PlanningMemoryFirestore) build,
  ) async {
    final h = await Harness.signedIn();
    final store = PlanningMemoryFirestore();
    SharedPreferences.setMockInitialValues({});
    await _run(t, name, h, (_) => build(store), () => true);
    await h.dispose();
  }

  if (only == null || only.contains('planner')) {
    testWidgets('matrix planner', (t) async {
      await planning('planner', t, (s) {
        final c = PlannerCubit(
          userId: 'u1',
          repository: FirestorePlannerRepository(s),
          nutrition: SmokeNutritionRepository(),
          generator: WeeklyPlanGenerator(catalog: const []),
          today: DateTime(2026, 11, 22),
          seedProvider: () => 1,
        );
        addTearDown(c.close);
        return PlannerScreen(cubit: c);
      });
    });
  }
  if (only == null || only.contains('shopping')) {
    testWidgets('matrix shopping', (t) async {
      await planning('shopping', t, (s) {
        final c = ShoppingCubit(
          userId: 'u1',
          repository: FirestoreShoppingRepository(s),
          foods: LocalFoodDataSource(),
        );
        addTearDown(c.close);
        return ShoppingScreen(cubit: c);
      });
    });
  }
  if (only == null || only.contains('coach')) {
    testWidgets('matrix coach', (t) async {
      await planning('coach', t, (s) {
        final c = CoachCubit(
          userId: 'u1',
          store: FirestoreCoachStore(s),
          nutrition: SmokeNutritionRepository(),
          locale: 'ar',
        );
        addTearDown(c.close);
        return CoachScreen(cubit: c, dictation: FakeCoachDictation());
      });
    });
  }
  if (only == null || only.contains('ramadan')) {
    testWidgets('matrix ramadan', (t) async {
      final h = await Harness.signedIn();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = RamadanCubit(
        userId: 'u1',
        settings: PrefsRamadanSettingsStore(preferences: prefs, userId: 'u1'),
        nutrition: SmokeNutritionRepository(),
        foods: LocalFoodDataSource(),
        clock: () => DateTime(2026, 3, 1, 12),
      );
      addTearDown(c.close);
      await t.runAsync(() => c.load());
      await _run(t, 'ramadan', h, (_) => RamadanScreen(cubit: c), () => true);
      await h.dispose();
    });
  }
}

Future<void> _run(
  WidgetTester t,
  String name,
  Harness h,
  Widget Function(int) build,
  bool Function() ready,
) async {
  addTearDown(t.view.reset);
  final problems = <String>[];
  for (final s in _sizes.entries) {
    for (final v in _variants.entries) {
      t.view.physicalSize = s.value;
      t.view.devicePixelRatio = 1;
      final key = GlobalKey();
      try {
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: h.wrap(
              build(0),
              appShell: true,
              locale: Locale(v.value.$1),
              themeMode: v.value.$2 ? ThemeMode.light : ThemeMode.dark,
            ),
          ),
        );
        await t.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          final ctx = t.element(find.byType(Scaffold).first);
          for (final a in const [
            'assets/images/art/neb.jpg',
            'assets/images/art/spA.webp',
          ]) {
            await precacheImage(AssetImage(a), ctx);
          }
        });
        await t.pump(const Duration(seconds: 1));
        await t.pump(const Duration(seconds: 1));
        final ex = t.takeException();
        if (ex != null) {
          problems.add('${s.key}/${v.key}: ${ex.toString().split('\n').first}');
        }
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/matrix').createSync(recursive: true);
          File(
            'build/matrix/${s.key}__${name}__${v.key}.png',
          ).writeAsBytesSync(b!.buffer.asUint8List());
          im.dispose();
        });
      } catch (err) {
        problems.add(
          '${s.key}/${v.key}: THROW ${err.toString().split('\n').first}',
        );
      }
    }
  }
  await t.pumpWidget(const SizedBox());
  File('build/matrix/problems.txt').writeAsStringSync(
    '$name: ${problems.isEmpty ? 'ok' : problems.join(' | ')}\n',
    mode: FileMode.append,
  );
}
