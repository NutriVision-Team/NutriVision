import '../support/optional_fonts.dart';
import 'package:sufradepi/features/meal_log/domain/catalog_meal_draft.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/food_search_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_detail_screen.dart';
import 'package:sufradepi/core/widgets/ordered_number_pair.dart';
import 'package:sufradepi/features/diary/presentation/screens/diary_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/food_detail_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_review_screen.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_log_hub_screen.dart';
import 'package:sufradepi/core/widgets/state_cards.dart';
import 'package:sufradepi/core/widgets/nebula_background.dart';
import 'dart:io';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:sufradepi/app/responsive_frame.dart';
import 'package:sufradepi/features/health_coach/coach_access_host.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sufradepi/core/config/app_preferences.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/theme/theme_cubit.dart';
import 'package:sufradepi/core/utils/date_utils.dart' as app_dates;
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'package:sufradepi/data/models/user_profile_model.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/data/repositories/user_repository.dart';
import 'package:sufradepi/features/auth/presentation/cubit/session_cubit.dart';
import 'package:sufradepi/features/auth/presentation/screens/login_screen.dart';
import 'package:sufradepi/features/auth/presentation/screens/register_screen.dart';
import 'package:sufradepi/features/auth/presentation/screens/welcome_screen.dart';
import 'package:sufradepi/features/home/presentation/cubit/home_cubit.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import 'package:sufradepi/features/nutrition_plan/presentation/plan_screen.dart';
import 'package:sufradepi/features/onboarding/presentation/onboarding_screen.dart';
import 'package:sufradepi/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import 'package:sufradepi/features/profile_setup/presentation/screens/profile_setup_screen.dart';
import 'package:sufradepi/features/splash/presentation/splash_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/services/auth_service.dart';

class FakeNutritionRepository implements NutritionRepository {
  NutritionProfileModel? activeProfile;
  List<MealEntryModel> meals = [];
  List<DailyLogModel> logs = [];

  @override
  Future<void> saveNutritionProfile(
    String uid,
    NutritionProfileModel profile,
  ) async {
    activeProfile = profile;
  }

  @override
  Future<List<NutritionProfileModel>> getNutritionProfiles(String uid) async =>
      [if (activeProfile != null) activeProfile!];

  @override
  Future<void> saveMealEntry(String uid, MealEntryModel meal) async {
    meals = [
      ...meals.where((m) => !(m.userId == uid && m.mealId == meal.mealId)),
      meal,
    ];
  }

  @override
  Future<void> deleteMealEntry(String uid, String mealId) async {
    meals = meals
        .where((m) => !(m.userId == uid && m.mealId == mealId))
        .toList();
  }

  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async => meals;

  @override
  Future<void> upsertDailyLog(String uid, DailyLogModel dailyLog) async {}

  @override
  Future<DailyLogModel?> getDailyLog(String uid, String dateKey) async =>
      logs.where((l) => l.dateKey == dateKey).firstOrNull;

  @override
  Future<List<DailyLogModel>> getDailyLogs(
    String uid, {
    int limit = 30,
  }) async => logs;
}

class FakeUserRepository implements UserRepository {
  UserProfileModel? user;

  @override
  Future<UserProfileModel?> getCurrentUser() async => user;

  @override
  Future<void> upsertUser(UserProfileModel user) async {
    this.user = user;
  }
}

Future<void> loadRealFonts() async {
  await loadPrivateReviewFonts();

  // Load every family declared in pubspec.yaml explicitly (same files the app bundles).
  final pub = File('pubspec.yaml').readAsLinesSync();
  final fams = <String, List<String>>{};
  String? cur;
  var inFonts = false;
  for (final line in pub) {
    if (line.startsWith('  fonts:')) { inFonts = true; continue; }
    if (!inFonts) continue;
    final f = RegExp(r'^    - family: (.+)$').firstMatch(line);
    if (f != null) { cur = f.group(1)!.trim(); fams[cur] = []; continue; }
    final a = RegExp(r'^\s+- asset: (.+)$').firstMatch(line);
    if (a != null && cur != null) fams[cur]!.add(a.group(1)!.trim());
  }
  for (final e in fams.entries) {
    final l = FontLoader(e.key);
    for (final path in e.value.toSet()) {
      final b = File(path).readAsBytesSync();
      l.addFont(Future.value(ByteData.view(b.buffer)));
    }
    await l.load();
  }
  const families = <String, List<String>>{
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
  // Material Icons are auto-loaded on devices but not in the golden-test
  // environment; load the SDK copy so icons render instead of tofu boxes.
  Directory? dir = File(Platform.resolvedExecutable).parent;
  File? iconsFile;
  for (var i = 0; i < 8 && dir != null; i++) {
    final candidate = File(
      '${dir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (candidate.existsSync()) {
      iconsFile = candidate;
      break;
    }
    dir = dir.parent;
  }
  assert(iconsFile != null, 'MaterialIcons-Regular.otf not found in SDK');
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(iconsFile!.readAsBytesSync().buffer)));
  await iconLoader.load();
}

class Harness {
  Harness({
    required this.preferences,
    required this.userRepository,
    required this.nutritionRepository,
    required this.sessionCubit,
    required this.setupCubit,
    required this.homeCubit,
  });

  final AppPreferences preferences;
  final FakeUserRepository userRepository;
  final FakeNutritionRepository nutritionRepository;
  final SessionCubit sessionCubit;
  final ProfileSetupCubit setupCubit;
  final HomeCubit homeCubit;

  static Future<Harness> signedOut({bool authenticated = false}) async {
    SharedPreferences.setMockInitialValues(const {
      'locale': 'ar',
      'theme_mode': 'dark',
    });
    final prefs = await AppPreferences.load();
    final userRepo = FakeUserRepository();
    final nutritionRepo = FakeNutritionRepository();
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'u1'),
      signedIn: authenticated,
    );
    return Harness(
      preferences: prefs,
      userRepository: userRepo,
      nutritionRepository: nutritionRepo,
      sessionCubit: SessionCubit(
        authService: AuthService.withAuth(auth),
        userRepository: userRepo,
      ),
      setupCubit: ProfileSetupCubit(
        nutritionRepository: nutritionRepo,
        userRepository: userRepo,
      ),
      homeCubit: HomeCubit(
        userRepository: userRepo,
        nutritionRepository: nutritionRepo,
        clock: () => DateTime(2026, 11, 22, 12),
      ),
    );
  }

  static Future<Harness> signedIn() async {
    final harness = await signedOut(authenticated: true);
    final user = UserProfileModel(
      uid: 'u1',
      displayName: 'مصطفى',
      email: 'mostafa@example.com',
      onboardingCompleted: true,
    );
    harness.userRepository.user = user;
    harness.nutritionRepository.activeProfile = NutritionProfileModel(
      profileId: 'primary',
      gender: 'male',
      dateOfBirth: DateTime(2000, 8, 7),
      heightCm: 175,
      currentWeightKg: 90,
      targetWeightKg: 80,
      activityLevel: 'moderate',
      nutritionGoal: 'lose',
      dailyCalorieTarget: 2397,
      proteinTarget: 180,
      carbsTarget: 240,
      fatTarget: 80,
    );
    final today = DateTime(2026, 11, 22, 12);
    harness.nutritionRepository.logs = List.generate(5, (i) {
      final day = today.subtract(Duration(days: i));
      return DailyLogModel(
        dateKey: app_dates.SufraDateUtils.toDateKey(day),
        timezone: 'Africa/Cairo',
        totalCalories: 1800,
        totalProtein: 140,
        totalCarbs: 180,
        totalFat: 60,
        totalFiber: 20,
        totalSugar: 40,
        totalSodium: 1500,
        calorieTarget: 2397,
        proteinTarget: 180,
        carbsTarget: 240,
        fatTarget: 80,
        waterIntakeMl: i == 0 ? 1250 : 2000,
        mealCount: 3,
      );
    });
    harness.nutritionRepository.meals = [
      MealEntryModel(
        mealId: 'm1',
        userId: 'u1',
        dateKey: app_dates.SufraDateUtils.toDateKey(today),
        consumedAt: today,
        mealType: 'breakfast',
        inputMethod: 'manual',
        title: 'فول بالزيت',
        items: const [],
        totalCalories: 420,
        totalProtein: 22,
        totalCarbs: 45,
        totalFat: 16,
        totalFiber: 12,
        totalSugar: 3,
        totalSodium: 450,
        analysisStatus: 'confirmed',
      ),
    ];
    return harness;
  }

  Widget wrap(
    Widget screen, {
    List<GoRoute> additionalRoutes = const [],
    Locale locale = const Locale(String.fromEnvironment('SUFRA_LANG', defaultValue: 'ar')),
    ThemeMode themeMode = const bool.fromEnvironment('SUFRA_LIGHT') ? ThemeMode.light : ThemeMode.dark,
    bool appShell = false,
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => screen),
        ...additionalRoutes,
        for (final path in const [
          '/splash',
          '/onboarding',
          '/login',
          '/register',
          '/welcome',
          '/setup',
          '/plan',
          '/home',
          '/diary',
        ])
          GoRoute(path: path, builder: (_, _) => const SizedBox()),
      ],
    );
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserRepository>.value(value: userRepository),
        RepositoryProvider<NutritionRepository>.value(
          value: nutritionRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: sessionCubit),
          BlocProvider<ThemeCubit>.value(value: ThemeCubit(preferences)),
          BlocProvider<LocaleCubit>.value(value: LocaleCubit(preferences)),
          BlocProvider<ProfileSetupCubit>.value(value: setupCubit),
          BlocProvider<HomeCubit>.value(value: homeCubit),
        ],
        child: MaterialApp.router(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          routerConfig: router,
          builder: appShell
              ? (context, child) => CoachAccessHost(
                  router: router,
                  enabled: true,
                  child: ResponsiveFrame(child: child ?? const SizedBox()),
                )
              : null,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }

  Future<void> dispose() async {
    await sessionCubit.close();
    await setupCubit.close();
    await homeCubit.close();
  }
}

void configurePhoneSurface(WidgetTester tester) {
  final envW = double.tryParse(Platform.environment['SUFRA_W'] ?? '') ?? 390;
  final envH = double.tryParse(Platform.environment['SUFRA_H'] ?? '') ?? 844;
  tester.view.physicalSize = Size(envW * 2, envH * 2);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadRealFonts);

  Future<void> capture(
    WidgetTester tester,
    Harness harness,
    Widget screen,
    String name,
  ) async {
    configurePhoneSurface(tester);
    await tester.runAsync(() async {
      await tester.pumpWidget(harness.wrap(screen));
      // Let real async image decoding (logo webp) finish outside fake-async.
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump(const Duration(milliseconds: 900));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(name));
  }

  testWidgets('golden: meal log hub real sprite art', (tester) async {
    final h = await Harness.signedOut();
    await capture(
      tester,
      h,
      const MealLogHubScreen(),
      'goldens/13_meal_log.png',
    );
    expect(tester.takeException(), isNull);
    await h.dispose();
  });

  testWidgets('golden: reusable state cards', (tester) async {
    final h = await Harness.signedOut();
    await capture(
      tester,
      h,
      Scaffold(
        body: NebulaBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
                children: [
                  for (final state in SufraState.values)
                    SufraStateCard(
                      state: state,
                      title: state.name,
                      subtitle: 'State preview',
                      actionLabel: 'Action',
                      onAction: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      'goldens/14_states.png',
    );
    expect(tester.takeException(), isNull);
    await h.dispose();
  });

  const catalogFixture = FoodCatalogModel(
    foodId: 'fixture-only',
    name: 'أكلة اختبار',
    source: 'Sufra food catalog',
    nutritionPer100g: {
      'calories': 200,
      'protein': 10,
      'carbohydrates': 20,
      'fat': 8,
      'fiber': 4,
      'sugar': 2,
      'sodium': 50,
    },
  );
  testWidgets('golden: logged meal detail and Arabic quantity edit', (
    tester,
  ) async {
    final h = await Harness.signedIn();
    h.nutritionRepository.meals = [
      FoodPortion(catalogFixture, 150).toMeal(
        uid: 'u1',
        id: 'detail',
        at: DateTime(2026, 11, 22, 14, 15),
        mealType: 'lunch',
      ),
    ];
    await capture(
      tester,
      h,
      const MealDetailScreen(mealId: 'detail', dateKey: '2026-11-22'),
      'goldens/18_meal_detail.png',
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('تعديل'));
    await tester.tap(find.text('تعديل'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.enterText(find.byType(TextField).at(1), '٢٥٠');
    await tester.ensureVisible(find.text('حفظ التعديلات'));
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/19_edit_sheet.png'),
    );
    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(h.nutritionRepository.meals.single.items.single.weightInGrams, 250);
    expect(
      h.nutritionRepository.meals.single.totalCalories,
      closeTo(500, .00001),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await h.dispose();
  });
  testWidgets('golden: multi ingredient review quantity remove add and save', (
    tester,
  ) async {
    final h = await Harness.signedIn();
    configurePhoneSurface(tester);
    final app = h.wrap(
      MealReviewScreen(
        draft: CatalogMealDraft([
          FoodPortion(catalogFixture, 150),
          FoodPortion(catalogFixture, 100),
          FoodPortion(catalogFixture, 50),
        ]),
      ),
      additionalRoutes: [
        GoRoute(
          path: FoodSearchScreen.pickRoutePath,
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(catalogFixture),
              child: const Text('Choose test fixture'),
            ),
          ),
        ),
      ],
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(app);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump(const Duration(milliseconds: 900));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/20_multi_review.png'),
    );
    await tester.tap(find.text('150.0 جم'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.enterText(find.byType(TextField), '٢٠٠');
    await tester.pump();
    expect(find.text('400'), findsOneWidget);
    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('700 سعرة'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>).at(2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('إزالة المكوّن'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('600 سعرة'), findsOneWidget);
    await tester.tap(find.text('إضافة مكوّن'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Choose test fixture'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('800 سعرة'), findsOneWidget);
    await tester.tap(find.text('بالهنا والشفا، احفظ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    final saved = h.nutritionRepository.meals
        .where((m) => m.mealId != 'm1')
        .single;
    expect(saved.items, hasLength(3));
    expect(saved.totalCalories, 800);
    expect(saved.items.first.weightInGrams, 200);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await h.dispose();
  });
  testWidgets('golden: catalog portion detail', (tester) async {
    final h = await Harness.signedIn();
    await capture(
      tester,
      h,
      const FoodDetailScreen(food: catalogFixture),
      'goldens/15_food_detail.png',
    );
    expect(tester.takeException(), isNull);
    await h.dispose();
  });
  testWidgets('golden: catalog review', (tester) async {
    final h = await Harness.signedIn();
    await capture(
      tester,
      h,
      MealReviewScreen(portion: FoodPortion(catalogFixture, 150)),
      'goldens/16_review.png',
    );
    expect(tester.takeException(), isNull);
    await h.dispose();
  });
  testWidgets('golden: diary actual repository fixture', (tester) async {
    final h = await Harness.signedIn();
    await capture(
      tester,
      h,
      DiaryScreen(initialDate: DateTime(2026, 11, 22)),
      'goldens/17_diary.png',
    );
    final calories = tester.widget<OrderedNumberPair>(
      find.byKey(const ValueKey('diary-calorie-pair')),
    );
    expect(calories.first, 420);
    expect(calories.second, 2397);
    expect(tester.takeException(), isNull);
    await h.dispose();
  });

  testWidgets('golden: splash', (tester) async {
    final h = await Harness.signedOut();
    await capture(tester, h, const SplashScreen(), 'goldens/01_splash.png');
    await h.dispose();
  });

  testWidgets('golden: onboarding page 1', (tester) async {
    final h = await Harness.signedOut();
    await capture(
      tester,
      h,
      OnboardingScreen(preferences: h.preferences),
      'goldens/02_onboarding.png',
    );
    final counter = tester.widget<OrderedNumberPair>(
      find.byKey(const ValueKey('onboarding-counter')),
    );
    expect(counter.first, 1);
    expect(counter.second, 3);
    await h.dispose();
  });

  testWidgets('golden: login', (tester) async {
    final h = await Harness.signedOut();
    await capture(tester, h, const LoginScreen(), 'goldens/04_login.png');
    await h.dispose();
  });

  testWidgets('golden: register', (tester) async {
    final h = await Harness.signedOut();
    await capture(tester, h, const RegisterScreen(), 'goldens/05_register.png');
    await h.dispose();
  });

  testWidgets('golden: welcome', (tester) async {
    final h = await Harness.signedIn();
    await capture(tester, h, const WelcomeScreen(), 'goldens/06_welcome.png');
    await h.dispose();
  });

  testWidgets('golden: wizard goal step', (tester) async {
    final h = await Harness.signedIn();
    h.setupCubit.update(
      ProfileSetupData(
        nutritionGoal: 'lose',
        gender: 'male',
        dateOfBirth: DateTime(2000, 8, 7),
        heightCm: 175,
        currentWeightKg: 90,
        targetWeightKg: 80,
        activityLevel: 'moderate',
      ),
    );
    while (h.setupCubit.state.step < 6) {
      h.setupCubit.next();
    }
    await capture(
      tester,
      h,
      const ProfileSetupScreen(),
      'goldens/07_wizard_goal.png',
    );
    await h.dispose();
  });

  testWidgets('golden: wizard measurements step', (tester) async {
    final h = await Harness.signedIn();
    h.setupCubit.update(
      ProfileSetupData(
        nutritionGoal: 'lose',
        gender: 'male',
        dateOfBirth: DateTime(2000, 8, 7),
      ),
    );
    h.setupCubit.next();
    h.setupCubit.next();
    h.setupCubit.next();
    await capture(
      tester,
      h,
      const ProfileSetupScreen(),
      'goldens/08_wizard_measurements.png',
    );
    await h.dispose();
  });

  testWidgets('golden: plan', (tester) async {
    final h = await Harness.signedIn();
    h.setupCubit.update(
      ProfileSetupData(
        nutritionGoal: 'lose',
        gender: 'male',
        dateOfBirth: DateTime(2000, 8, 7),
        heightCm: 175,
        currentWeightKg: 90,
        targetWeightKg: 80,
        activityLevel: 'moderate',
      ),
    );
    while (h.setupCubit.state.step < 6) {
      h.setupCubit.next();
    }
    await tester.runAsync(() async {
      await h.setupCubit.finish('u1');
    });
    await capture(tester, h, const PlanScreen(), 'goldens/09_plan.png');
    await h.dispose();
  });

  testWidgets('golden: home', (tester) async {
    final h = await Harness.signedIn();
    configurePhoneSurface(tester);
    await tester.runAsync(() async {
      await h.homeCubit.load('u1');
    });
    await tester.pumpWidget(
      h.wrap(HomeScreen(clock: () => DateTime(2026, 11, 22, 18))),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/art/neb.jpg'),
        tester.element(find.byType(HomeScreen)),
      );
      await precacheImage(
        const AssetImage('assets/images/sufra_logo.webp'),
        tester.element(find.byType(HomeScreen)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/10_home.png'),
    );
    await h.dispose();
  });
}
