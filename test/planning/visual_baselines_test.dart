import '../support/optional_fonts.dart';
// Visual baselines for the four planning screens: AR empty/setup states at
// phone size. Generate with: flutter test test/planning/visual_baselines_test.dart --update
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_screen.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/features/planner/data/planner_repository.dart';
import 'package:sufradepi/features/planner/domain/weekly_plan_generator.dart';
import 'package:sufradepi/features/planner/presentation/cubit/planner_cubit.dart';
import 'package:sufradepi/features/planner/presentation/screens/planner_screen.dart';
import 'package:sufradepi/features/ramadan/data/ramadan_settings_store.dart';
import 'package:sufradepi/features/ramadan/presentation/cubit/ramadan_cubit.dart';
import 'package:sufradepi/features/ramadan/presentation/screens/ramadan_screen.dart';
import 'package:sufradepi/features/shopping/data/shopping_repository.dart';
import 'package:sufradepi/features/shopping/presentation/cubit/shopping_cubit.dart';
import 'package:sufradepi/features/shopping/presentation/screens/shopping_screen.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

import 'screens_smoke_test.dart'
    show SmokeNutritionRepository, FakeCoachDictation;
import 'support/planning_memory_firestore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlanningMemoryFirestore store;

  setUpAll(() async {
    await loadPrivateReviewFonts();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    // Load the app's real fonts from disk so baselines show the true
    // design typography (the widget-test default font is a placeholder).
    for (final entry in {
      'Cairo': [
        'Cairo-Regular',
        'Cairo-SemiBold',
        'Cairo-Bold',
        'Cairo-ExtraBold',
      ],
      'Reem Kufi': ['ReemKufi-SemiBold', 'ReemKufi-Bold'],
      'Tajawal': ['Tajawal-Regular', 'Tajawal-Medium', 'Tajawal-Bold'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final file in entry.value) {
        loader.addFont(
          File(
            'assets/fonts/$file.ttf',
          ).readAsBytes().then((bytes) => bytes.buffer.asByteData()),
        );
      }
      await loader.load();
    }
  });

  setUp(() async {
    store = PlanningMemoryFirestore();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> golden(
    WidgetTester tester,
    String location,
    Widget screen,
    String name, {
    required bool Function() ready,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: location, builder: (_, __) => screen),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(Scaffold).first);
      for (final asset in [
        'neb.jpg',
        'ram.jpg',
        'spA.webp',
        'spB.webp',
        'spC.webp',
      ]) {
        await precacheImage(AssetImage('assets/images/art/$asset'), context);
      }
    });
    await tester.pump();
    // The animated nebula background never settles; pump until the cubit
    // leaves its loading state instead.
    for (var i = 0; i < 100 && !ready(); i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(ready(), isTrue, reason: 'screen left its loading state');
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('planner empty AR', (tester) async {
    final cubit = PlannerCubit(
      userId: 'u1',
      repository: FirestorePlannerRepository(store),
      nutrition: SmokeNutritionRepository(),
      generator: WeeklyPlanGenerator(catalog: const []),
      today: DateTime(2026, 11, 22),
      seedProvider: () => 1,
    );
    addTearDown(cubit.close);
    await golden(
      tester,
      '/planner',
      PlannerScreen(cubit: cubit),
      'planner_empty_ar',
      ready: () => cubit.state.status != PlannerStatus.loading,
    );
  });

  testWidgets('shopping empty AR', (tester) async {
    final cubit = ShoppingCubit(
      userId: 'u1',
      repository: FirestoreShoppingRepository(store),
      foods: LocalFoodDataSource(),
    );
    addTearDown(cubit.close);
    await golden(
      tester,
      '/shopping',
      ShoppingScreen(cubit: cubit),
      'shopping_empty_ar',
      ready: () => cubit.state.status != ShoppingStatus.loading,
    );
  });

  testWidgets('coach empty AR', (tester) async {
    final cubit = CoachCubit(
      userId: 'u1',
      store: FirestoreCoachStore(store),
      nutrition: SmokeNutritionRepository(),
      locale: 'ar',
    );
    addTearDown(cubit.close);
    await golden(
      tester,
      '/coach',
      CoachScreen(cubit: cubit, dictation: FakeCoachDictation()),
      'coach_empty_ar',
      ready: () => cubit.state.status != CoachStatus.loading,
    );
  });

  testWidgets('ramadan setup AR', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final cubit = RamadanCubit(
      userId: 'u1',
      settings: PrefsRamadanSettingsStore(preferences: prefs, userId: 'u1'),
      nutrition: SmokeNutritionRepository(),
      foods: LocalFoodDataSource(),
      clock: () => DateTime(2026, 3, 1, 12),
    );
    addTearDown(cubit.close);
    // The catalog read is real file I/O; let it complete outside the
    // fake-async pump loop.
    await tester.runAsync(() => cubit.load());
    await golden(
      tester,
      '/ramadan',
      RamadanScreen(cubit: cubit),
      'ramadan_setup_ar',
      ready: () => cubit.state.status != RamadanStatus.loading,
    );
  });
}
