import 'package:sufradepi/features/health_coach/coach_access_host.dart';
import '../support/optional_fonts.dart';
// Visual baselines for the four planning screens: AR empty/setup states at
// phone size. Generate with: flutter test test/planning/visual_baselines_test.dart --update
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:sufradepi/data/models/shopping_list_model.dart';
import 'package:sufradepi/features/ramadan/domain/ramadan_logic.dart';
import 'plan_generator_test.dart' show catalog;

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

class VisualPlannerCubit extends PlannerCubit {
  VisualPlannerCubit({
    required super.userId,
    required super.repository,
    required super.nutrition,
    required super.generator,
    required super.today,
  });
  void show(PlannerState value) => emit(value);
  @override
  Future<void> load() async {}
}

class VisualShoppingCubit extends ShoppingCubit {
  VisualShoppingCubit({
    required super.userId,
    required super.repository,
    required super.foods,
  });
  void show(ShoppingState value) => emit(value);
  @override
  Future<void> load() async {}
}

class VisualCoachCubit extends CoachCubit {
  VisualCoachCubit({
    required super.userId,
    required super.store,
    required super.nutrition,
    required super.locale,
  });
  void show(CoachState value) => emit(value);
  @override
  Future<void> load() async {}
}

class VisualRamadanCubit extends RamadanCubit {
  VisualRamadanCubit({
    super.clock,
    required super.userId,
    required super.settings,
    required super.nutrition,
    required super.foods,
  });
  void show(RamadanState value) => emit(value);
  @override
  Future<void> load() async {}
}

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
    String language = 'ar',
    bool light = false,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(
      double.parse(Platform.environment['SUFRA_REVIEW_WIDTH'] ?? '320'),
      double.parse(Platform.environment['SUFRA_REVIEW_HEIGHT'] ?? '640'),
    );
    tester.view.devicePixelRatio = 1;
    final keyboardInset = double.parse(
      Platform.environment['SUFRA_REVIEW_KEYBOARD'] ?? '0',
    );
    if (keyboardInset > 0) {
      tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
    }
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
        theme: light ? AppTheme.light() : AppTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: RepaintBoundary(
            key: const ValueKey('nav-shot'),
            child: CoachAccessHost(
              router: router,
              enabled: true,
              child: child!,
            ),
          ),
        ),
        locale: Locale(language),
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
    await tester.pump(const Duration(milliseconds: 350));
    Future<void> capture(String suffix) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('nav-shot')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          'build/test_evidence/nav_${name}_$suffix.png',
        ).writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    if (name.startsWith('ramadan')) {
      final label = find.text(
        (await AppLocalizations.delegate.load(Locale(language))).ramadanSeconds,
      );
      if (label.evaluate().isNotEmpty) {
        final scroll = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        final navTop = tester.getRect(find.byType(FloatingGlassNavBar)).top;
        final rect = tester.getRect(label);
        scroll.jumpTo(
          (scroll.pixels + rect.bottom - navTop + 24).clamp(
            0,
            scroll.maxScrollExtent,
          ),
        );
        await tester.pump();
        expect(
          tester.getRect(label).bottom,
          lessThan(tester.getRect(find.byType(FloatingGlassNavBar)).top),
        );
        await capture('countdown_unobscured');
      }
    }
    if (scale > 1.5 &&
        name.startsWith('shopping') &&
        find
            .text(
              AppLocalizations.of(
                tester.element(find.byType(Scaffold).first),
              ).shoppingGroupProduce,
            )
            .evaluate()
            .isNotEmpty) {
      final label = tester.widget<Text>(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(Scaffold).first),
          ).shoppingGroupProduce,
        ),
      );
      expect(
        label.maxLines,
        isNull,
        reason: 'large category labels must not be ellipsized',
      );
    }
    if (name.startsWith('planner')) {
      final mealLabels = tester
          .widgetList<Text>(find.byType(Text))
          .where(
            (text) =>
                (text.data?.contains(' · ') ?? false) ||
                (text.data?.contains('\n') ?? false),
          );
      expect(mealLabels, isNotEmpty);
      expect(
        mealLabels.every((text) => text.maxLines == null),
        isTrue,
        reason: 'large meal names must remain fully readable',
      );
    }
    await capture('top');
    final scrolls = find.byType(Scrollable);
    if (scrolls.evaluate().isNotEmpty) {
      for (var i = 0; i < 12; i++) {
        final state = tester.state<ScrollableState>(scrolls.first);
        state.position.jumpTo(state.position.maxScrollExtent);
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    expect(tester.takeException(), isNull);
    if (keyboardInset > 0 &&
        (name.startsWith('coach') || name.startsWith('shopping'))) {
      final input = find.byType(TextField).first;
      await tester.ensureVisible(input);
      await tester.tap(input);
      await tester.enterText(input, 'Review keyboard entry');
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.testTextInput.isVisible, isTrue);
      final inputRect = tester.getRect(input);
      expect(inputRect.top, greaterThanOrEqualTo(0));
      expect(
        inputRect.bottom,
        lessThan(tester.view.physicalSize.height - keyboardInset),
      );
    }
    final l = await AppLocalizations.delegate.load(Locale(language));
    final endTarget = name.startsWith('planner')
        ? find.text(l.plannerShoppingCta)
        : name.startsWith('shopping')
        ? find.text(l.shoppingGenerateFromPlan)
        : name.startsWith('coach')
        ? find.byType(TextField)
        : find.text(l.ramadanDisclaimer);
    expect(endTarget, findsOneWidget);
    expect(
      endTarget.hitTestable(),
      findsOneWidget,
      reason: 'final action must accept a tap above the navigation',
    );
    final endRect = tester.getRect(endTarget);
    expect(endRect.top, greaterThanOrEqualTo(0));
    expect(
      endRect.bottom,
      lessThan(tester.getRect(find.byType(FloatingGlassNavBar)).top),
    );
    await capture('end');
    expect(find.byType(FloatingGlassNavBar), findsOneWidget);
  }

  for (final variant in ['ar_large', 'en_large', 'ar_light', 'en_light']) {
    for (final mode in ['loaded']) {
      for (final feature in ['planner', 'shopping', 'coach', 'ramadan']) {
        testWidgets('$feature $mode $variant', (tester) async {
          final nutrition = SmokeNutritionRepository();
          final foods = LocalFoodDataSource();
          final prefs = await SharedPreferences.getInstance();
          final plan = WeeklyPlanGenerator(catalog: catalog()).generate(
            weekStart: DateTime(2026, 11, 21),
            dailyCalorieTarget: 2000,
            seed: 7,
          );
          final language = variant.startsWith('en') ? 'en' : 'ar';
          late Widget screen;
          switch (feature) {
            case 'planner':
              final cubit = VisualPlannerCubit(
                userId: 'u1',
                repository: FirestorePlannerRepository(store),
                nutrition: nutrition,
                generator: WeeklyPlanGenerator(catalog: catalog()),
                today: DateTime(2026, 11, 22),
              );
              cubit.show(
                PlannerState(
                  status: mode == 'error'
                      ? PlannerStatus.error
                      : mode == 'loading'
                      ? PlannerStatus.loading
                      : PlannerStatus.ready,
                  weekStart: DateTime(2026, 11, 21),
                  plan: mode == 'loaded' ? plan : null,
                ),
              );
              screen = PlannerScreen(cubit: cubit);
              addTearDown(cubit.close);
            case 'shopping':
              final cubit = VisualShoppingCubit(
                userId: 'u1',
                repository: FirestoreShoppingRepository(store),
                foods: foods,
              );
              cubit.show(
                ShoppingState(
                  status: mode == 'error'
                      ? ShoppingStatus.error
                      : mode == 'loading'
                      ? ShoppingStatus.loading
                      : ShoppingStatus.ready,
                  items: mode == 'loaded'
                      ? [
                          ShoppingListItemModel(
                            itemId: 'a',
                            name: language == 'ar' ? 'طماطم' : 'Tomato',
                            linkedFoodId: 'usda_foundation_1999634',
                            quantity: 500,
                            unit: 'g',
                            category: 'produce',
                            isPurchased: true,
                          ),
                          ShoppingListItemModel(
                            itemId: 'b',
                            name: language == 'ar' ? 'حليب' : 'Milk',
                            linkedFoodId: 'usda_foundation_746782',
                            quantity: 1000,
                            unit: 'g',
                            category: 'dairy',
                            isPurchased: false,
                          ),
                        ]
                      : const [],
                ),
              );
              screen = ShoppingScreen(cubit: cubit, currentPlan: plan);
              addTearDown(cubit.close);
            case 'coach':
              final cubit = VisualCoachCubit(
                userId: 'u1',
                store: FirestoreCoachStore(store),
                nutrition: nutrition,
                locale: language,
              );
              cubit.show(
                CoachState(
                  status: mode == 'error'
                      ? CoachStatus.error
                      : mode == 'loading'
                      ? CoachStatus.loading
                      : CoachStatus.ready,
                  hasRecords: true,
                  entries: mode == 'loaded'
                      ? [
                          CoachEntry(
                            id: 'q',
                            isUser: true,
                            text: language == 'ar'
                                ? 'حلل أسبوعي'
                                : 'Analyze my week',
                          ),
                          CoachEntry(
                            id: 'a',
                            isUser: false,
                            text: language == 'ar'
                                ? 'عندك يومين مسجلين. الأيام الناقصة مش صفر أكل.'
                                : 'You logged two days. Missing days are not zero food.',
                          ),
                        ]
                      : const [],
                ),
              );
              screen = CoachScreen(
                cubit: cubit,
                dictation: FakeCoachDictation(),
              );
              addTearDown(cubit.close);
            case 'ramadan':
              final cubit = VisualRamadanCubit(
                clock: () => DateTime(2026, 3, 1, 12),
                userId: 'u1',
                settings: PrefsRamadanSettingsStore(
                  preferences: prefs,
                  userId: 'u1',
                ),
                nutrition: nutrition,
                foods: foods,
              );
              cubit.show(
                RamadanState(
                  status: mode == 'error'
                      ? RamadanStatus.error
                      : mode == 'loading'
                      ? RamadanStatus.loading
                      : RamadanStatus.ready,
                  times: mode == 'empty'
                      ? null
                      : const RamadanTimes(
                          iftarMinutes: 1050,
                          suhoorEndMinutes: 240,
                          taraweehMinutes: 1200,
                        ),
                  suggestions: mode == 'loaded'
                      ? RamadanSuggester(
                          catalog: catalog(),
                        ).suggest(dailyCalorieTarget: 2000)
                      : const [],
                  waterMl: 750,
                  cupsFromUser: true,
                ),
              );
              screen = RamadanScreen(cubit: cubit);
              addTearDown(cubit.close);
          }
          await golden(
            tester,
            '/$feature',
            screen,
            '${feature}_${mode}_$variant',
            ready: () => true,
            language: language,
            light: variant.endsWith('_light'),
            scale: double.parse(
              Platform.environment['SUFRA_REVIEW_SCALE'] ?? '2',
            ),
          );
        });
      }
    }
  }
}
