import '../../features/dashboard/presentation/destination_hubs.dart';
import 'package:sufradepi/features/progress/export/coach_report_snapshot.dart';
import '../../features/planner/domain/planner_food_choices.dart';
import '../../features/gamification/data/local_account_day_ledger.dart';
import '../../features/gamification/presentation/local_protected_experience.dart';
import '../../features/gamification/data/bounded_firestore_progression.dart';
import '../../features/gamification/data/progression_repository.dart';
import '../../features/gamification/presentation/progression_screen.dart';
import '../../core/widgets/journey_theme_control.dart';
import '../../features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import '../../features/recipes/presentation/screens/quantified_recipe_screen.dart';
import '../../features/recipes/data/datasources/local_recipe_data_source.dart';
import '../../features/reminders/presentation/screens/reminders_account_screen.dart';
import '../../features/planning_shared/presentation/planning_account_screen.dart';
import '../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../features/favorites/data/favorites_repository.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/premium/presentation/screens/premium_screen.dart';
import '../../core/widgets/nebula_background.dart';
import '../../features/barcode/presentation/screens/barcode_account_scope.dart';
import '../../features/barcode/presentation/screens/barcode_scanner_screen.dart';
import '../../features/barcode/presentation/screens/product_result_screen.dart';
import '../../features/voice_logging/voice_meal_screen.dart';
import '../../features/camera_analysis/presentation/camera_analysis_screen.dart';
import '../../features/camera_analysis/data/cloudflare_personal_food_recognition.dart';
import '../../features/meal_log/domain/meal_review_input.dart';
import '../../features/progress/presentation/screens/stats_screen.dart';
import '../../features/progress/presentation/screens/report_screen.dart';
import '../../features/progress/presentation/screens/water_screen.dart';
import '../../features/progress/presentation/screens/weight_screen.dart';
import '../../features/progress/presentation/screens/export_report_screen.dart';
import '../../features/meal_log/domain/catalog_meal_draft.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/recipes/data/persistence/cloud_recipe_favorites.dart';
import '../../features/achievements/data/persistence/achievement_progress_store.dart';
import '../../features/meal_log/presentation/screens/meal_detail_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/date_utils.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/repositories/food_repository.dart';
import '../../features/recipes/domain/recipe_catalog_repository.dart';
import '../../features/recipes/presentation/screens/recipe_suggestion_screen.dart';
import '../../features/recipes/presentation/screens/recipe_detail_screen.dart';
import '../../features/alternatives/presentation/screens/alternatives_screen.dart';
import '../../features/achievements/domain/achievement_activity.dart';
import '../../features/achievements/presentation/screens/achievements_screen.dart';
import '../../features/meal_log/presentation/screens/food_search_screen.dart';
import '../../features/meal_log/presentation/screens/food_detail_screen.dart';
import '../../features/meal_log/presentation/screens/meal_review_screen.dart';
import '../../features/meal_log/domain/food_portion.dart';
import '../../features/diary/presentation/screens/diary_screen.dart';
import '../../data/models/food_catalog_model.dart';
import '../../core/widgets/app_states.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_preferences.dart';
import '../../features/auth/presentation/cubit/session_cubit.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/meal_log/presentation/screens/meal_log_hub_screen.dart';
import '../../features/nutrition_plan/presentation/plan_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile_setup/presentation/screens/profile_setup_screen.dart';
import '../../features/shared/coming_soon_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

/// Turns a bloc stream into a [Listenable] for GoRouter's refreshListenable.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createRouter({
  LocalAccountDayLedger? rewardCandidate,
  // Test seam for screen/router coverage only. Null preserves the production
  // bounded Firestore path below; never supplies an alternate reward writer.
  ProgressionRepository Function(String uid)? progressionForTesting,
  required SessionCubit sessionCubit,
  required AppPreferences preferences,
}) {
  final recipes = RecipeCatalogRepository();
  AchievementActivityLoader? activityLoader;
  String? currentUid() {
    final state = sessionCubit.state;
    return state is SessionAuthenticated ? state.user.uid : null;
  }

  void assertActive(String expected) {
    if (currentUid() != expected) {
      throw StateError('Account is no longer active');
    }
  }

  CloudRecipeFavorites? favoriteStore;
  AchievementProgressStore? achievementStore;
  CloudRecipeFavorites favoritesFor(String uid) {
    if (favoriteStore?.userId != uid) {
      favoriteStore = CloudRecipeFavorites(
        userId: uid,
        activeUserId: currentUid,
        backend: FirestoreRecipeFavoritesBackend(
          FirebaseFirestore.instance,
          assertActive: assertActive,
        ),
        catalog: recipes,
      );
    }
    return favoriteStore!;
  }

  AchievementProgressStore progressFor(String uid) {
    if (achievementStore?.userId != uid) {
      achievementStore = AchievementProgressStore(
        userId: uid,
        activeUserId: currentUid,
        backend: FirestoreAchievementProgressBackend(
          FirebaseFirestore.instance,
          assertActive: assertActive,
        ),
      );
    }
    return achievementStore!;
  }

  Widget accountView(Widget Function(String uid) builder) =>
      BlocBuilder<SessionCubit, SessionState>(
        bloc: sessionCubit,
        builder: (_, state) {
          if (state is! SessionAuthenticated || !state.isReady) {
            return const Scaffold(body: AppLoadingView());
          }
          return KeyedSubtree(
            key: ValueKey(state.user.uid),
            child: builder(state.user.uid),
          );
        },
      );

  return GoRouter(
    initialLocation: SplashScreen.routePath,
    refreshListenable: Listenable.merge([
      GoRouterRefreshStream(sessionCubit.stream),
      preferences,
    ]),
    redirect: (context, state) {
      final session = sessionCubit.state;
      final location = state.matchedLocation;

      const splash = SplashScreen.routePath;
      const onboarding = OnboardingScreen.routePath;
      const login = LoginScreen.routePath;
      const register = RegisterScreen.routePath;
      const welcome = WelcomeScreen.routePath;
      const setup = ProfileSetupScreen.routePath;
      const plan = PlanScreen.routePath;
      const home = HomeScreen.routePath;

      // 1. Session still resolving: stay on splash.
      if (session is SessionUnknown) {
        return location == splash ? null : splash;
      }

      // 2. First launch: onboarding before anything else.
      if (!preferences.onboardingSeen) {
        return location == onboarding ? null : onboarding;
      }

      // 3. Signed out: auth screens only.
      if (session is SessionUnauthenticated) {
        return (location == login || location == register) ? null : login;
      }

      if (session is SessionFailure) {
        return location == login ? null : login;
      }

      // 4. Signed in but personal setup not finished.
      if (session is SessionAuthenticated && session.needsSetup) {
        const allowed = {welcome, setup, plan};
        return allowed.contains(location) ? null : welcome;
      }

      // 5. Signed in and ready: keep auth/first-run screens out of reach.
      if (session is SessionAuthenticated && session.isReady) {
        final setupStatus = context.read<ProfileSetupCubit>().state.status;
        if (location == plan &&
            setupStatus is SetupSaved &&
            setupStatus.uid == session.user.uid) {
          return null;
        }
        const firstRun = {
          splash,
          onboarding,
          login,
          register,
          welcome,
          setup,
          plan,
        };
        return firstRun.contains(location) ? home : null;
      }

      // Authenticated with a profile still loading: wait on splash.
      return location == splash ? null : splash;
    },
    routes: [
      GoRoute(
        path: '/reminders',
        builder: (context, _) => const RemindersAccountScreen(),
      ),
      for (final page in PlanningPage.values)
        GoRoute(
          path: '/${page.name}',
          builder: (_, state) => accountView(
            (uid) => PlanningAccountScreen(
              foodChoices: state.extra is PlannerFoodChoices
                  ? state.extra! as PlannerFoodChoices
                  : const PlannerFoodChoices(),
              reviewedMeal:
                  state.extra is OwnedReviewedMeal &&
                      (state.extra! as OwnedReviewedMeal).uid == uid
                  ? (state.extra! as OwnedReviewedMeal).draft
                  : null,
              rewardCandidate: rewardCandidate,
              key: ValueKey('${page.name}:$uid'),
              uid: uid,
              currentUid: currentUid,
              page: page,
            ),
          ),
        ),
      GoRoute(
        path: '/premium',
        builder: (_, _) => const NebulaBackground(child: PremiumScreen()),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, _) => accountView(
          (uid) => BlocProvider(
            create: (_) => FavoritesCubit(
              uid: uid,
              currentUid: currentUid,
              backend: FirestoreFavoritesBackend(
                FirebaseFirestore.instance,
                assertActive: assertActive,
              ),
              nutrition: context.read<NutritionRepository>(),
            )..load(),
            child: NebulaBackground(
              child: FavoritesScreen(
                onOpenMeal: (view) {
                  if (view.meal != null) {
                    context.push(MealDetailScreen.locationFor(view.meal!));
                  }
                },
                onOpenRecipe: (favorite) => context.push(
                  Uri(
                    pathSegments: ['', 'recipe', favorite.targetId],
                  ).toString(),
                ),
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: BarcodeScannerScreen.routePath,
        builder: (context, _) => accountView(
          (uid) => BarcodeAccountScope(
            userId: uid,
            activeUserId: currentUid,
            onPhotoFallback: () => context.push(CameraAnalysisScreen.routePath),
            onSearchFallback: () => context.push(FoodSearchScreen.routePath),
            onOpenProduct: (product) async {
              if (currentUid() != uid) return;
              await context.push(
                ProductResultScreen.routePath,
                extra: OwnedOffProduct(uid, product),
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: ProductResultScreen.routePath,
        builder: (_, state) => accountView((uid) {
          final payload = state.extra;
          if (payload is! OwnedOffProduct || payload.ownerUid != uid) {
            return const Scaffold(body: AppErrorView());
          }
          return ProductResultScreen(product: payload.product);
        }),
      ),
      GoRoute(
        path: VoiceMealScreen.routePath,
        builder: (_, _) => accountView((uid) => const VoiceMealScreen()),
      ),
      GoRoute(
        path: CameraAnalysisScreen.routePath,
        builder: (_, state) => accountView(
          (uid) => CameraAnalysisScreen(
            returnReviewedDraft: state.extra == 'coach-reviewed-draft',
            provider: CloudflarePersonalFoodRecognitionProvider(
              enabled: const bool.fromEnvironment(
                'SUFRA_PERSONAL_PHOTOS_ENABLED',
                defaultValue: true,
              ),
              allowedUid: const String.fromEnvironment('SUFRA_PHOTO_OWNER_UID'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, _) => accountView((uid) {
          if (rewardCandidate != null) {
            return LocalProtectedExperience(uid: uid, ledger: rewardCandidate);
          }
          if (progressionForTesting != null) {
            return ProgressionScreen(
              key: ValueKey(uid),
              uid: uid,
              todayKey: SufraDateUtils.toDateKey(DateTime.now()),
              currentDayKey: () => SufraDateUtils.toDateKey(DateTime.now()),
              repository: progressionForTesting(uid),
            );
          }
          String? activeUid() {
            final state = context.read<SessionCubit>().state;
            return state is SessionAuthenticated ? state.user.uid : null;
          }

          final source = firestoreProgressionSource(
            FirebaseFirestore.instance,
            uid,
            activeUid,
          );
          return ProgressionScreen(
            key: ValueKey(uid),
            uid: uid,
            todayKey: SufraDateUtils.toDateKey(DateTime.now()),
            currentDayKey: () => SufraDateUtils.toDateKey(DateTime.now()),
            repository: ReadOnlyProgressionRepository(
              nutrition: context.read<NutritionRepository>(),
              currentUid: activeUid,
              profile: () => null,
              loadProfile: source.profile,
              loadMeals: source.meals,
              loadPlans: (_) => source.plans(),
              changes: (_) => source.watch(),
            ),
          );
        }),
      ),
      GoRoute(
        path: '/nutrition-stats',
        builder: (context, _) => accountView(
          (uid) => StatsScreen(
            achievementLoader: activityLoader ??=
                RepositoryAchievementActivityLoader(
                  nutrition: context.read<NutritionRepository>(),
                  foods: context.read<FoodRepository>(),
                ),
          ),
        ),
      ),
      GoRoute(
        path: '/report',
        builder: (_, _) => accountView((uid) => const ReportScreen()),
      ),
      GoRoute(
        path: '/water',
        builder: (_, _) => accountView((uid) => const WaterScreen()),
      ),
      GoRoute(
        path: '/weight',
        builder: (_, _) => accountView((uid) => const WeightScreen()),
      ),
      GoRoute(
        path: '/report/export',
        builder: (_, state) => accountView(
          (uid) => ExportReportScreen(
            coach: (state.extra is CoachReportSnapshot)
                ? (state.extra as CoachReportSnapshot).forOwner(uid)
                : null,
          ),
        ),
      ),
      GoRoute(
        path: MealDetailScreen.routePath,
        builder: (_, state) => state.uri.queryParameters['date'] != null
            ? MealDetailScreen(
                mealId: state.pathParameters['id']!,
                dateKey: state.uri.queryParameters['date']!,
              )
            : const Scaffold(body: AppErrorView()),
      ),
      GoRoute(
        path: '/recipes',
        builder: (_, _) => accountView(
          (uid) => RecipeSuggestionScreen(
            repository: recipes,
            favorites: favoritesFor(uid),
          ),
        ),
      ),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, state) => accountView(
          (uid) => RecipeDetailScreen(
            recipeId: state.pathParameters['id']!,
            repository: recipes,
            favorites: favoritesFor(uid),
          ),
        ),
      ),
      GoRoute(
        path: '/recipe-quantify',
        builder: (_, state) => accountView(
          (uid) => state.extra is LocalRecipeRecord
              ? QuantifiedRecipeScreen(
                  recipe: state.extra! as LocalRecipeRecord,
                )
              : const Scaffold(body: AppErrorView()),
        ),
      ),
      GoRoute(
        path: '/alternatives',
        builder: (context, _) => accountView(
          (uid) => AlternativesScreen(
            loadProfile: () async {
              final profiles = await context
                  .read<NutritionRepository>()
                  .getNutritionProfiles(uid);
              return profiles.where((p) => p.isActive).firstOrNull ??
                  profiles.firstOrNull;
            },
          ),
        ),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, _) => accountView((uid) {
          activityLoader ??= RepositoryAchievementActivityLoader(
            nutrition: context.read<NutritionRepository>(),
            foods: context.read<FoodRepository>(),
          );
          return AchievementsScreen(
            key: ValueKey(uid),
            userId: uid,
            todayKey: SufraDateUtils.toDateKey(DateTime.now()),
            loader: activityLoader!,
            progressStore: progressFor(uid),
          );
        }),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => accountView((uid) => const ProfileHubScreen()),
      ),
      GoRoute(
        path: '/meals',
        builder: (_, _) => accountView((uid) => const MealsHubScreen()),
      ),
      GoRoute(
        path: FoodSearchScreen.pickRoutePath,
        builder: (_, state) => FoodSearchScreen(
          selectOnly: true,
          initialQuery: state.extra is String ? state.extra! as String : '',
        ),
      ),
      GoRoute(
        path: FoodSearchScreen.routePath,
        builder: (_, _) => const FoodSearchScreen(),
      ),
      GoRoute(
        path: FoodDetailScreen.routePath,
        builder: (_, state) => state.extra is FoodCatalogModel
            ? FoodDetailScreen(food: state.extra! as FoodCatalogModel)
            : const Scaffold(body: AppErrorView()),
      ),
      GoRoute(
        path: MealReviewScreen.routePath,
        builder: (_, state) => switch (state.extra) {
          MealReviewInput input => MealReviewScreen(
            draft: input.draft,
            initialMealType: input.mealType,
            initialNotes: input.notes,
            initialTitle: input.title,
            inputMethod: input.inputMethod,
          ),
          FoodPortion portion => MealReviewScreen(portion: portion),
          CatalogMealDraft draft => MealReviewScreen(draft: draft),
          _ => const Scaffold(body: AppErrorView()),
        },
      ),
      GoRoute(
        path: DiaryScreen.routePath,
        builder: (_, _) => const DiaryScreen(),
      ),

      GoRoute(
        path: SplashScreen.routePath,
        builder: (context, state) =>
            const JourneyThemeControl(child: SplashScreen()),
      ),
      GoRoute(
        path: OnboardingScreen.routePath,
        builder: (context, state) => JourneyThemeControl(
          child: OnboardingScreen(preferences: preferences),
        ),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        builder: (context, state) => JourneyThemeControl(
          child: LoginScreen(
            startGoogle: state.uri.queryParameters['google'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: RegisterScreen.routePath,
        builder: (context, state) =>
            const JourneyThemeControl(child: RegisterScreen()),
      ),
      GoRoute(
        path: WelcomeScreen.routePath,
        builder: (context, state) =>
            const JourneyThemeControl(child: WelcomeScreen()),
      ),
      GoRoute(
        path: ProfileSetupScreen.routePath,
        builder: (context, state) =>
            const JourneyThemeControl(child: ProfileSetupScreen()),
      ),
      GoRoute(
        path: PlanScreen.routePath,
        builder: (context, state) =>
            const JourneyThemeControl(child: PlanScreen()),
      ),
      GoRoute(
        path: HomeScreen.routePath,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: MealLogHubScreen.routePath,
        builder: (context, state) =>
            const JourneyThemeControl(child: MealLogHubScreen()),
      ),
      GoRoute(
        path: ComingSoonScreen.routePath,
        builder: (context, state) => const ComingSoonScreen(),
      ),
    ],
  );
}
