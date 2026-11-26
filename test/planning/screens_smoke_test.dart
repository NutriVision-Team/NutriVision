// Smoke tests: each planning screen renders RTL at phone size without
// overflow or exceptions. Golden pixel tests remain a follow-up after the
// routes are wired into the merged tree.
import 'dart:io';
import 'dart:convert';
import 'package:sufradepi/features/voice_logging/data/dictation_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_screen.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
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
import 'package:sufradepi/l10n/app_localizations.dart';

import 'support/planning_memory_firestore.dart';

class FakeCoachDictation extends DictationService {
  DictationStatus currentStatus = DictationStatus.idle;
  String currentText = '';
  int starts = 0;
  int releases = 0;
  @override
  DictationStatus get status => currentStatus;
  @override
  String get text => currentText;
  @override
  int acquire() => 1;
  @override
  Future<void> start(int lease, String language) async {
    starts++;
    currentStatus = DictationStatus.listening;
    notifyListeners();
  }

  @override
  Future<void> stop(int lease) async {
    currentStatus = DictationStatus.idle;
    notifyListeners();
  }

  @override
  void release(int lease) {
    releases++;
  }

  void transcript(String value) {
    currentText = value;
    notifyListeners();
  }
}

class SmokeNutritionRepository implements NutritionRepository {
  @override
  Future<void> saveNutritionProfile(
    String uid,
    NutritionProfileModel profile,
  ) async {}

  @override
  Future<List<NutritionProfileModel>> getNutritionProfiles(String uid) async =>
      const [];

  @override
  Future<void> saveMealEntry(String uid, MealEntryModel meal) async {}

  @override
  Future<void> deleteMealEntry(String uid, String mealId) async {}

  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async => const [];

  @override
  Future<void> upsertDailyLog(String uid, DailyLogModel dailyLog) async {}

  @override
  Future<DailyLogModel?> getDailyLog(String uid, String dateKey) async => null;

  @override
  Future<List<DailyLogModel>> getDailyLogs(
    String uid, {
    int limit = 30,
  }) async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlanningMemoryFirestore store;

  setUpAll(() async {
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
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

  Future<void> pump(
    WidgetTester tester,
    String location,
    Widget screen, {
    required bool Function() ready,
    double textScale = 1,
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    );
    await tester.pump();
    for (var i = 0; i < 100 && !ready(); i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(ready(), isTrue, reason: 'screen left its loading state');
    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)).toString(),
      contains('rtl'),
    );
  }

  testWidgets('planner screen renders its empty state', (tester) async {
    final cubit = PlannerCubit(
      userId: 'u1',
      repository: FirestorePlannerRepository(store),
      nutrition: SmokeNutritionRepository(),
      generator: WeeklyPlanGenerator(catalog: const []),
      today: DateTime(2026, 11, 22),
      seedProvider: () => 1,
    );
    addTearDown(cubit.close);
    await pump(
      tester,
      '/planner',
      PlannerScreen(cubit: cubit),
      ready: () => cubit.state.status != PlannerStatus.loading,
    );
    expect(find.byType(PlannerScreen), findsOneWidget);
  });

  testWidgets(
    'populated planner at2x wraps complete names and gram quantities',
    (tester) async {
      final data =
          jsonDecode(File('assets/data/foods.json').readAsStringSync()) as Map;
      final foods = (data['foods'] as List)
          .map((f) => LocalFoodRecord.fromJson(Map<String, dynamic>.from(f)))
          .toList();
      final g = WeeklyPlanGenerator(catalog: foods);
      final repo = FirestorePlannerRepository(store);
      final start = DateTime(2026, 11, 21);
      await repo.savePlan(
        'u1',
        g.generate(weekStart: start, dailyCalorieTarget: 2100, seed: 12),
      );
      final cubit = PlannerCubit(
        userId: 'u1',
        repository: repo,
        nutrition: SmokeNutritionRepository(),
        generator: g,
        today: start,
        seedProvider: () => 12,
      );
      addTearDown(cubit.close);
      await pump(
        tester,
        '/planner',
        PlannerScreen(cubit: cubit),
        ready: () => cubit.state.status != PlannerStatus.loading,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('جم'), findsWidgets);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2500));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('قائمة التسوق'), findsOneWidget);
    },
  );

  testWidgets('shopping screen renders its empty state', (tester) async {
    final cubit = ShoppingCubit(
      userId: 'u1',
      repository: FirestoreShoppingRepository(store),
      foods: LocalFoodDataSource(),
    );
    addTearDown(cubit.close);
    await pump(
      tester,
      '/shopping',
      ShoppingScreen(cubit: cubit),
      ready: () => cubit.state.status != ShoppingStatus.loading,
    );
    expect(find.byType(ShoppingScreen), findsOneWidget);
  });

  testWidgets(
    'coach screen shows record-grounded guidance without implementation labels',
    (tester) async {
      final cubit = CoachCubit(
        userId: 'u1',
        store: FirestoreCoachStore(store),
        nutrition: SmokeNutritionRepository(),
        locale: 'ar',
      );
      addTearDown(cubit.close);
      await pump(
        tester,
        '/coach',
        CoachScreen(cubit: cubit, dictation: FakeCoachDictation()),
        ready: () => cubit.state.status != CoachStatus.loading,
      );
      expect(find.byType(CoachScreen), findsOneWidget);
      expect(find.textContaining('قواعد'), findsNothing);
      expect(find.textContaining('لو معلومة ناقصة هقولك'), findsOneWidget);
      expect(find.textContaining('المدرب مش بديل للطبيب'), findsOneWidget);
    },
  );

  testWidgets('ramadan screen renders the setup state without times', (
    tester,
  ) async {
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
    await pump(
      tester,
      '/ramadan',
      RamadanScreen(cubit: cubit),
      ready: () => cubit.state.status != RamadanStatus.loading,
    );
    expect(find.byType(RamadanScreen), findsOneWidget);
    final l = AppLocalizations.of(tester.element(find.byType(RamadanScreen)));
    await tester.tap(find.text(l.ramadanSetupCta));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(l.ramadanChooseTime), findsNWidgets(3));
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, l.actionSave),
    );
    expect(save.onPressed, isNull);
    expect(cubit.state.times, isNull);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(l.ramadanChooseTime).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final pickerContext = tester.element(find.byType(TimePickerDialog));
      final ok = MaterialLocalizations.of(pickerContext).okButtonLabel;
      await tester.tap(find.text(ok));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }
    expect(find.text(l.ramadanChooseTime), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, l.actionSave))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text(l.actionSave));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(cubit.state.times, isNotNull);
    expect(find.text(l.ramadanTimesTitle), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'voice requires tap and review, preserves edits and releases lease',
    (tester) async {
      final voice = FakeCoachDictation();
      final cubit = CoachCubit(
        userId: 'u1',
        store: FirestoreCoachStore(store),
        nutrition: SmokeNutritionRepository(),
        locale: 'ar',
      );
      addTearDown(cubit.close);
      await pump(
        tester,
        '/coach',
        CoachScreen(cubit: cubit, dictation: voice),
        ready: () => cubit.state.status != CoachStatus.loading,
      );
      expect(voice.starts, 0);
      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pump();
      expect(voice.starts, 0);
      expect(find.byWidgetPredicate((w) => w is AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'إملاء صوتي'));
      await tester.pump();
      expect(voice.starts, 1);
      voice.transcript('سؤال صوتي');
      await tester.pump();
      expect(find.widgetWithText(TextField, 'سؤال صوتي'), findsOneWidget);
      expect(
        cubit.state.entries,
        isEmpty,
        reason: 'dictation never auto-sends',
      );
      await tester.enterText(find.byType(TextField), 'تعديل يدوي');
      voice.transcript('نتيجة متأخرة');
      await tester.pump();
      expect(find.widgetWithText(TextField, 'تعديل يدوي'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(voice.releases, 1);
    },
  );
}
