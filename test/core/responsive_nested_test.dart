import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_habits_screen.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_daily_checkin_screen.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_storage_screen.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_learn_article_screen.dart';
import 'package:sufradepi/features/coach/domain/coach_learn_content.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/manual_food_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/food_search_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_detail_screen.dart';
import 'package:sufradepi/data/repositories/food_repository.dart';
import 'package:sufradepi/core/widgets/sufra_licenses_screen.dart';
import 'package:sufradepi/features/splash/presentation/splash_screen.dart';
import 'package:sufradepi/features/recipes/presentation/screens/quantified_recipe_screen.dart';
import 'package:sufradepi/features/recipes/domain/recipe_catalog_repository.dart';
import '../planning/coach_retry_test.dart' show AmbiguousCoachStore;
import '../planning/screens_smoke_test.dart' show SmokeNutritionRepository;
import '../features/voice_logging/voice_flow_test.dart' show VoiceFoods;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/features/health_coach/coach_access_host.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import 'package:sufradepi/features/diary/presentation/screens/diary_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_review_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_log_hub_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/food_detail_screen.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/auth/presentation/screens/login_screen.dart';
import 'package:sufradepi/features/auth/presentation/screens/register_screen.dart';
import 'package:sufradepi/features/auth/presentation/screens/welcome_screen.dart';
import 'package:sufradepi/features/onboarding/presentation/onboarding_screen.dart';
import 'package:sufradepi/features/profile_setup/presentation/screens/profile_setup_screen.dart';
import 'package:sufradepi/features/nutrition_plan/presentation/plan_screen.dart';
import 'package:sufradepi/features/premium/presentation/screens/premium_screen.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;
import '../meal_log/catalog_flow_test.dart' show catalog;

void main() {
  setUpAll(loadRealFonts);
  for (final width in [320.0, 800.0]) {
    for (final name in [
      'habits',
      'checkin',
      'storage',
      'article',
      'manual',
      'search',
      'meal-detail',
      'licenses',
      'splash',
      'quantify',
    ]) {
      testWidgets('complete host $name $width', (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(width, width == 320 ? 844 : 1280);
        addTearDown(t.view.reset);
        final h = await Harness.signedIn();
        final coach = CoachCubit(
          userId: 'u1',
          store: AmbiguousCoachStore(),
          nutrition: SmokeNutritionRepository(),
          locale: width == 320 ? 'en' : 'ar',
        );
        await coach.load();
        final recipes = await t.runAsync(
          () => RecipeCatalogRepository().getAll(),
        );
        final screen = switch (name) {
          'habits' => CoachHabitsScreen(cubit: coach),
          'checkin' => CoachDailyCheckinScreen(cubit: coach),
          'storage' => CoachStorageScreen(cubit: coach),
          'article' => CoachLearnArticleScreen(topic: coachLearnTopics.first),
          'manual' => const ManualFoodScreen(),
          'search' => RepositoryProvider<FoodRepository>.value(
            value: VoiceFoods(),
            child: const FoodSearchScreen(),
          ),
          'meal-detail' => const MealDetailScreen(
            mealId: 'm1',
            dateKey: '2026-11-22',
          ),
          'licenses' => const SufraLicensesScreen(),
          'splash' => const SplashScreen(),
          'quantify' => QuantifiedRecipeScreen(recipe: recipes!.first),
          'home' => HomeScreen(clock: () => DateTime(2026, 11, 22)),
          'diary' => DiaryScreen(initialDate: DateTime(2026, 11, 22)),
          'review' => MealReviewScreen(portion: FoodPortion(catalog(), 150)),
          'food' => FoodDetailScreen(food: catalog()),
          'log' => const MealLogHubScreen(),
          'login' => const LoginScreen(),
          'register' => const RegisterScreen(),
          'welcome' => const WelcomeScreen(),
          'onboarding' => OnboardingScreen(preferences: h.preferences),
          'setup' => const ProfileSetupScreen(),
          'plan' => const PlanScreen(),
          _ => const PremiumScreen(),
        };
        final key = GlobalKey();
        await t.pumpWidget(
          h.wrap(
            Builder(
              builder: (c) => MediaQuery(
                data: MediaQuery.of(c).copyWith(
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 24, bottom: 32),
                  textScaler: TextScaler.linear(width == 320 ? 1.6 : 1),
                ),
                child: RepaintBoundary(
                  key: key,
                  child: CoachAccessHost(
                    router: GoRouter.of(c),
                    enabled: true,
                    child: screen,
                  ),
                ),
              ),
            ),
            locale: Locale(width == 320 ? 'en' : 'ar'),
          ),
        );
        await t.pump(const Duration(seconds: 2));
        await t.runAsync(() async {
          for (final e in find.byType(Image).evaluate()) {
            await precacheImage((e.widget as Image).image, e);
          }
        });
        await t.pump();
        expect(t.takeException(), isNull, reason: '$name width$width');
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await im.toByteData(format: ui.ImageByteFormat.png);
          File(
            'build/test_evidence/route_${name}_${width.toInt()}.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          im.dispose();
        });
        await t.pumpWidget(const SizedBox());
        await h.dispose();
        await coach.close();
      });
    }
  }
}
