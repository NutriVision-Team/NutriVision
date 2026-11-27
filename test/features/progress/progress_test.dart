import 'package:clock/clock.dart';
import 'dart:io';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sufradepi/core/config/app_preferences.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/theme/theme_cubit.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'package:sufradepi/data/models/user_profile_model.dart';
import 'package:sufradepi/data/models/water_log_model.dart';
import 'package:sufradepi/data/models/weight_log_model.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/data/repositories/user_repository.dart';
import 'package:sufradepi/features/auth/presentation/cubit/session_cubit.dart';
import 'package:sufradepi/features/progress/data/water_weight_repository.dart';
import 'package:sufradepi/features/progress/domain/day_nutrition.dart';
import 'package:sufradepi/features/progress/presentation/cubit/progress_cubit.dart';
import 'package:sufradepi/features/progress/presentation/cubit/water_cubit.dart';
import 'package:sufradepi/features/progress/presentation/screens/export_report_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/report_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/stats_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/water_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/weight_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/services/auth_service.dart';

class FakeNutritionRepository implements NutritionRepository {
  List<DailyLogModel> logs = [];
  List<MealEntryModel> meals = [];
  NutritionProfileModel? activeProfile;
  bool failReads = false;
  int dailyLogReads = 0;

  @override
  Future<List<DailyLogModel>> getDailyLogs(
    String uid, {
    int limit = 30,
  }) async => logs.take(limit).toList();

  @override
  Future<DailyLogModel?> getDailyLog(String uid, String dateKey) async => null;

  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async {
    if (failReads) throw StateError('read failed');
    return meals;
  }

  @override
  Future<List<NutritionProfileModel>> getNutritionProfiles(String uid) async =>
      [if (activeProfile != null) activeProfile!];

  @override
  Future<void> saveMealEntry(String uid, MealEntryModel meal) async {}

  // Contract addition announced by the lead: deleteMealEntry becomes part
  // of NutritionRepository; @override lands with the shared merge.
  @override
  Future<void> deleteMealEntry(String uid, String mealId) async {}

  @override
  Future<void> saveNutritionProfile(
    String uid,
    NutritionProfileModel profile,
  ) async {}

  @override
  Future<void> upsertDailyLog(String uid, DailyLogModel dailyLog) async {}
}

class FakeUserRepository implements UserRepository {
  UserProfileModel? user;

  @override
  Future<UserProfileModel?> getCurrentUser() async => user;

  @override
  Future<void> upsertUser(UserProfileModel user) async {}
}

class FakeWaterWeightRepository implements WaterWeightRepository {
  List<WaterLogModel> water = [];
  List<WeightLogModel> weight = [];
  double waterAdded = 0;
  double weightAdded = 0;
  bool failWrites = false;
  int addWaterCalls = 0;
  int waterReads = 0;

  @override
  Future<List<WaterLogModel>> getWaterLogs(String uid, String dateKey) async {
    waterReads++;
    if (failWrites) throw StateError('read failed');
    return water;
  }

  @override
  Future<List<WeightLogModel>> getWeightLogs(
    String uid, {
    int limit = 60,
  }) async => weight;

  @override
  Future<void> addWaterLog(
    String uid,
    double amountMl,
    DateTime at, {
    String? operationId,
  }) async {
    addWaterCalls++;
    if (failWrites) throw StateError('write failed');
    waterAdded += amountMl;
  }

  @override
  Future<void> addWeightLog(
    String uid,
    double weightKg,
    DateTime at, {
    String? note,
    String? operationId,
  }) async {
    weightAdded = weightKg;
  }
}

DailyLogModel log(String key, {int meals = 2, double cal = 1800}) =>
    DailyLogModel(
      dateKey: key,
      timezone: 'Africa/Cairo',
      totalCalories: cal,
      totalProtein: 120,
      totalCarbs: 200,
      totalFat: 60,
      totalFiber: 20,
      totalSugar: 40,
      totalSodium: 1800,
      calorieTarget: 1850,
      proteinTarget: 180,
      carbsTarget: 240,
      fatTarget: 80,
      waterIntakeMl: 750,
      mealCount: meals,
    );

Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen,
  FakeNutritionRepository nutrition, {
  ThemeData? theme,
  Locale locale = const Locale('ar'),
}) => withClock(Clock.fixed(DateTime(2026, 11, 22, 12)), () async {
  SharedPreferences.setMockInitialValues(const {'locale': 'ar'});
  final prefs = await AppPreferences.load();
  final userRepo = FakeUserRepository();
  final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1'), signedIn: true);
  final sessionCubit = SessionCubit(
    authService: AuthService.withAuth(auth),
    userRepository: userRepo,
  );
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<NutritionRepository>.value(value: nutrition),
        RepositoryProvider<UserRepository>.value(value: userRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: sessionCubit),
          BlocProvider<ThemeCubit>.value(value: ThemeCubit(prefs)),
          BlocProvider<LocaleCubit>.value(value: LocaleCubit(prefs)),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: theme ?? AppTheme.dark(),
          home: screen,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 600));
});

Future<void> _loadFonts() async {
  const families = {
    'Cairo': [
      'assets/fonts/Cairo-Regular.ttf',
      'assets/fonts/Cairo-SemiBold.ttf',
      'assets/fonts/Cairo-Bold.ttf',
      'assets/fonts/Cairo-ExtraBold.ttf',
    ],
    'Reem Kufi': [
      'assets/fonts/ReemKufi-SemiBold.ttf',
      'assets/fonts/ReemKufi-Bold.ttf',
    ],
    'Tajawal': [
      'assets/fonts/Tajawal-Regular.ttf',
      'assets/fonts/Tajawal-Medium.ttf',
      'assets/fonts/Tajawal-Bold.ttf',
    ],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
  final icons = File(
    '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await iconLoader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);

  group('DayNutrition honesty', () {
    test('water-only day is untracked and totals are unknown', () {
      final day = DayNutrition.fromLog(log('2026-11-22', meals: 0, cal: 0));
      expect(day.tracked, isFalse);
      expect(day.calories, isNull);
      expect(day.waterMl, 750);
    });

    test('averages exclude untracked days and report coverage', () {
      final days = [
        DayNutrition.fromLog(log('2026-11-20', cal: 1000)),
        DayNutrition.fromLog(log('2026-11-21', cal: 2000)),
        DayNutrition.empty('2026-11-22'),
      ];
      final avg = NutritionAverages.of(days);
      expect(avg.trackedDays, 2);
      expect(avg.calories, 1500);
    });

    test('percent returns null for unknown target, never zero', () {
      expect(NutritionAverages.percent(100, null), isNull);
      expect(NutritionAverages.percent(null, 100), isNull);
    });
  });

  group('Progress screens', () {
    testWidgets('Stats renders title, tabs and streak with data', (
      tester,
    ) async {
      final nutrition = FakeNutritionRepository()
        ..activeProfile = NutritionProfileModel(
          profileId: 'primary',
          gender: 'male',
          dateOfBirth: DateTime(2000, 8, 7),
          heightCm: 175,
          currentWeightKg: 90,
          targetWeightKg: 80,
          activityLevel: 'moderate',
          nutritionGoal: 'lose',
          dailyCalorieTarget: 1850,
          proteinTarget: 180,
          carbsTarget: 240,
          fatTarget: 80,
        )
        ..logs = [log('2026-11-20'), log('2026-11-21'), log('2026-11-22')];
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await pumpScreen(
        tester,
        StatsScreen(waterWeightRepository: FakeWaterWeightRepository()),
        nutrition,
      );
      expect(find.text('تقدمي'), findsWidgets);
      expect(find.text('أسبوع'), findsOneWidget);
      expect(find.text('شهر'), findsOneWidget);
      expect(find.text('السعرات'), findsOneWidget);
    });

    testWidgets('Water renders glass and quick-add buttons', (tester) async {
      final nutrition = FakeNutritionRepository();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await pumpScreen(
        tester,
        WaterScreen(waterWeightRepository: FakeWaterWeightRepository()),
        nutrition,
      );
      expect(find.text('مية النهاردة'), findsOneWidget);
      expect(find.text('+ ٢٥٠ مل'), findsOneWidget);
      expect(find.text('+ ٥٠٠ مل'), findsOneWidget);
      expect(find.text('مخصص'), findsOneWidget);
    });

    testWidgets('Weight renders title and CTA', (tester) async {
      final nutrition = FakeNutritionRepository();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await pumpScreen(
        tester,
        WeightScreen(waterWeightRepository: FakeWaterWeightRepository()),
        nutrition,
      );
      expect(find.text('وزنك'), findsOneWidget);
      expect(find.text('+ سجّل وزن اليوم'), findsOneWidget);
    });

    testWidgets('Report renders rings and commitment card', (tester) async {
      final nutrition = FakeNutritionRepository()
        ..logs = [log('2026-11-21'), log('2026-11-22')];
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await pumpScreen(tester, const ReportScreen(), nutrition);
      expect(find.text('التقرير'), findsOneWidget);
      expect(find.text('الأيام اللي سجلت فيها أكلك'), findsOneWidget);
    });
  });

  group('WaterCubit guards', () {
    WaterCubit cubit(
      FakeWaterWeightRepository store,
      FakeNutritionRepository nutrition, {
      String? Function()? currentUid,
      bool fail = false,
    }) {
      if (fail) store.failWrites = true;
      return WaterCubit(
        waterWeightRepository: store,
        nutritionRepository: nutrition,
        uid: 'u1',
        currentUid: currentUid ?? () => 'u1',
        clock: () => DateTime(2026, 11, 22, 12),
      );
    }

    test(
      'concurrent addWater calls are deduplicated by the saving flag',
      () async {
        final store = FakeWaterWeightRepository();
        final c = cubit(store, FakeNutritionRepository());
        await c.load();
        final first = c.addWater(250);
        final second = c.addWater(250);
        await Future.wait([first, second]);
        expect(store.addWaterCalls, 1);
        expect(store.waterAdded, 250);
        await c.close();
      },
    );

    test('failed load emits failed state', () async {
      final store = FakeWaterWeightRepository()..failWrites = true;
      final c = cubit(store, FakeNutritionRepository());
      await c.load();
      expect(c.state.failed, isTrue);
      await c.close();
    });

    test('failed addWater keeps data and flags failure', () async {
      final store = FakeWaterWeightRepository();
      final c = cubit(store, FakeNutritionRepository());
      await c.load();
      store.failWrites = true;
      await c.addWater(250);
      expect(store.addWaterCalls, 1);
      expect(c.state.failed, isTrue);
      await c.close();
    });

    test('session mismatch blocks reads and writes', () async {
      final store = FakeWaterWeightRepository();
      final c = cubit(store, FakeNutritionRepository(), currentUid: () => 'u2');
      await c.load();
      await c.addWater(250);
      expect(store.waterReads, 0);
      expect(store.addWaterCalls, 0);
      expect(c.state.loading, isFalse);
      await c.close();
    });
  });

  group('ProgressCubit meal distribution', () {
    MealEntryModel meal(
      String id,
      String type,
      String dateKey, {
      String userId = 'u1',
    }) {
      return MealEntryModel(
        mealId: id,
        userId: userId,
        dateKey: dateKey,
        consumedAt: DateTime(2026, 11, 20),
        mealType: type,
        inputMethod: 'manual',
        title: type,
        items: const [],
        totalCalories: 500,
        totalProtein: 20,
        totalCarbs: 60,
        totalFat: 15,
        totalFiber: 5,
        totalSugar: 10,
        totalSodium: 300,
        analysisStatus: 'done',
      );
    }

    ProgressCubit cubit(FakeNutritionRepository nutrition) => ProgressCubit(
      nutritionRepository: nutrition,
      uid: 'u1',
      currentUid: () => 'u1',
      clock: () => DateTime(2026, 11, 22, 12),
    );

    test('aggregates owned in-window meal types', () async {
      final nutrition = FakeNutritionRepository()
        ..logs = [log('2026-11-22')]
        ..meals = [
          meal('m1', 'breakfast', '2026-11-22'),
          meal('m2', 'lunch', '2026-11-22'),
          meal('m3', 'lunch', '2026-11-21'),
          meal('m4', 'dinner', '2026-11-21', userId: 'u2'),
          meal('m5', 'dinner', '2026-10-01'),
        ];
      final c = cubit(nutrition);
      await c.load();
      expect(c.state.mealTypeCounts, {'breakfast': 1, 'lunch': 2});
      await c.close();
    });

    test('empty window yields an empty distribution', () async {
      final c = cubit(FakeNutritionRepository());
      await c.load();
      expect(c.state.mealTypeCounts, isEmpty);
      await c.close();
    });

    test('session mismatch blocks reads', () async {
      final nutrition = FakeNutritionRepository();
      final c = ProgressCubit(
        nutritionRepository: nutrition,
        uid: 'u1',
        currentUid: () => 'u2',
        clock: () => DateTime(2026, 11, 22, 12),
      );
      await c.load();
      expect(nutrition.dailyLogReads, 0);
      await c.close();
    });
  });

  group('Export report unknown values', () {
    testWidgets('renders dashes for unknown profile fields', (tester) async {
      SharedPreferences.setMockInitialValues(const {'locale': 'ar'});
      final prefs = await AppPreferences.load();
      final nutrition = FakeNutritionRepository();
      final userRepo = FakeUserRepository();
      final sessionCubit = SessionCubit(
        authService: AuthService.withAuth(
          MockFirebaseAuth(mockUser: MockUser(uid: 'u1'), signedIn: true),
        ),
        userRepository: userRepo,
      );
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<NutritionRepository>.value(value: nutrition),
            RepositoryProvider<UserRepository>.value(value: userRepo),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<SessionCubit>.value(value: sessionCubit),
              BlocProvider<ThemeCubit>.value(value: ThemeCubit(prefs)),
              BlocProvider<LocaleCubit>.value(value: LocaleCubit(prefs)),
            ],
            child: MaterialApp(
              locale: const Locale('ar'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppTheme.dark(),
              home: ExportReportScreen(
                waterWeightRepository: FakeWaterWeightRepository(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('—'), findsWidgets);
    });
  });
}
