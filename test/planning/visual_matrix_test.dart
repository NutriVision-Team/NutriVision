import 'package:sufradepi/features/coach/presentation/screens/coach_learn_article_screen.dart';
import 'package:sufradepi/features/coach/domain/coach_daily_checkin.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_daily_checkin_screen.dart';
import 'coach_workspace_test.dart' show ReviewRepo;
import '../support/optional_fonts.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
// Visual baselines for the four planning screens: AR empty/setup states at
// phone size. Generate with: flutter test test/planning/visual_baselines_test.dart --update
import 'dart:io';
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
    super.clock,
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
    await loadRealFonts();
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
        theme: light ? AppTheme.light() : AppTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
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
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
    if (name == 'coach_loaded_ar_dark' || name == 'coach_loaded_en_dark') {
      await tester.drag(find.byType(ListView).first, const Offset(0, -180));
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/coach_exchange_scrolled_$language.png'),
      );
    }
    if (name.startsWith('coach_loaded_')) {
      for (final section in [0, 2, 3, 4]) {
        final tab = find.byKey(ValueKey('coach_section_$section'));
        // The section selector is now a dropdown; its items exist only while open.
        if (tab.evaluate().isEmpty) continue;
        await Scrollable.ensureVisible(
          tester.element(tab),
          duration: Duration.zero,
          alignment: .5,
        );
        await tester.pump();
        await tester.tap(tab);
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${name}_section$section.png'),
        );
        if (section == 4) {
          final article = find.text(
            language == 'ar' ? 'اقرأ ملصق الأكل' : 'Read a food label',
          );
          await tester.scrollUntilVisible(
            article,
            200,
            scrollable: find
                .descendant(
                  of: find.byType(ListView).first,
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await Scrollable.ensureVisible(
            tester.element(article),
            duration: Duration.zero,
            alignment: .5,
          );
          await tester.pump();
          await tester.tap(article);
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(find.byType(CoachLearnArticleScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/${name}_learn_labels.png'),
          );
          final last = find.text(
            language == 'ar' ? 'ابحث عن الأكل' : 'Search foods',
          );
          await tester.scrollUntilVisible(
            last,
            250,
            scrollable: find
                .descendant(
                  of: find.byType(ListView).last,
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await Scrollable.ensureVisible(
            tester.element(last),
            duration: Duration.zero,
            alignment: .8,
          );
          await tester.pump();
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/${name}_learn_labels_bottom.png'),
          );
          Navigator.of(
            tester.element(find.byType(CoachLearnArticleScreen)),
          ).pop();
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
        }
        if (section == 0) {
          final notes = find.text(
            language == 'ar'
                ? 'سجّل أو عدّل ملاحظاتك'
                : 'Add or edit your notes',
          );
          await tester.scrollUntilVisible(
            notes,
            250,
            scrollable: find
                .descendant(
                  of: find.byType(ListView).first,
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await Scrollable.ensureVisible(
            tester.element(notes),
            duration: Duration.zero,
            alignment: .5,
          );
          await tester.pump();
          await tester.tap(notes);
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(find.byType(CoachDailyCheckinScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/${name}_daily_checkin.png'),
          );
          if (scale > 1) {
            await tester.drag(
              find.byType(ListView).last,
              const Offset(0, -900),
            );
            await tester.pump();
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('goldens/${name}_daily_checkin_bottom.png'),
            );
          }
          Navigator.of(
            tester.element(find.byType(CoachDailyCheckinScreen)),
          ).pop();
          await tester.pump(const Duration(seconds: 1));
        }
        if (section == 3) {
          final heading = find.text(
            language == 'ar'
                ? 'المسجل عبر فترتين'
                : 'Records across two periods',
          );
          await tester.scrollUntilVisible(
            heading,
            220,
            scrollable: find
                .descendant(
                  of: find.byType(ListView).first,
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await Scrollable.ensureVisible(
            tester.element(heading),
            duration: Duration.zero,
            alignment: 0,
          );
          await tester.pump(const Duration(milliseconds: 300));
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/${name}_comparison.png'),
          );
        }
        if (scale > 1) {
          final body = find.byType(ListView).first;
          for (var i = 0; i < 3; i++) {
            await tester.drag(body, const Offset(0, -450));
            await tester.pump(const Duration(milliseconds: 300));
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/${name}_section${section}_bottom.png'),
          );
        }
      }
    }
    if (name == 'ramadan_loaded_ar_dark' &&
        Platform.environment['SUFRA_RAMADAN_MOTION'] != null) {
      final capture = Platform.environment['SUFRA_RAMADAN_MOTION']!;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: screen,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 200));
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            '$capture/frame_${frame.toString().padLeft(3, '0')}.png',
          ),
        );
      }
      expect(tester.hasRunningAnimations, isTrue);
    }
    if (scale > 1 && name.contains('_loaded_')) {
      final scroll = find.byType(Scrollable).first;
      if (name.startsWith('ramadan_')) {
        final l = AppLocalizations.of(
          tester.element(find.byType(RamadanScreen)),
        );
        await tester.scrollUntilVisible(
          find.text(l.ramadanEditTimes),
          250,
          scrollable: scroll,
        );
        await Scrollable.ensureVisible(
          tester.element(find.text(l.ramadanEditTimes)),
          alignment: .5,
        );
      } else {
        await tester.drag(scroll, const Offset(0, -1200));
      }
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${name}_scrolled.png'),
      );
    }
  }

  for (final variant in ['ar_dark', 'en_dark', 'ar_light', 'ar_large']) {
    for (final mode in ['loaded', 'empty', 'error', 'loading']) {
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
                      ? const [
                          ShoppingListItemModel(
                            itemId: 'a',
                            name: 'طماطم',
                            quantity: 500,
                            unit: 'g',
                            category: 'produce',
                            isPurchased: true,
                          ),
                          ShoppingListItemModel(
                            itemId: 'b',
                            name: 'حليب',
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
                nutrition: mode == 'loaded' ? ReviewRepo() : nutrition,
                clock: () => DateTime(2026, 11, 24),
                locale: language,
              );
              if (mode == 'loaded') {
                cubit.updateDailyCheckin(
                  const CoachDailyCheckin(
                    activityMinutes: 25,
                    sleepHours: 7.5,
                    feeling: 'okay',
                  ),
                );
                cubit.chooseHabit('log_meal', true);
                cubit.markHabit('log_meal', true);
                cubit.chooseHabit('prepare_meal', true);
              }
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
            light: variant == 'ar_light',
            scale: variant == 'ar_large' ? 1.5 : 1,
          );
        });
      }
    }
  }
}
