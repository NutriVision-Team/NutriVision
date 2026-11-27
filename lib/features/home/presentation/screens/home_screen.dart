import '../widgets/home_quick_actions.dart';
import '../../../../core/widgets/saved_catalog_label.dart';
import '../../../../core/widgets/catalog_food_art.dart';
import '../../../../core/utils/date_utils.dart';
import '../widgets/home_activity_story.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/home_loading_skeleton.dart';
import '../../../../core/widgets/glass_shortcut.dart';
import '../widgets/dashboard_water_card.dart';
import '../../../progress/data/water_weight_repository.dart';
import '../widgets/dashboard_sections.dart';
import '../widgets/home_progress_card.dart';
import '../../../gamification/data/progression_repository.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import '../widgets/home_recipe_section.dart';
import '../../../../core/widgets/sufra_logo.dart';
import '../widgets/local_profile_avatar.dart';
import '../../../../core/widgets/language_settings.dart';
import '../../../meal_log/presentation/screens/meal_detail_screen.dart';
import '../../../meal_log/presentation/screens/food_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/floating_nav_bar.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../core/widgets/progress_widgets.dart';
import '../../../../core/widgets/theme_switcher.dart';
import '../../../../data/models/meal_entry_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../cubit/home_cubit.dart';

/// Screen 08 — Home.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.clock,
    this.progression,
    this.waterRepository,
  });

  final WaterWeightRepository? waterRepository;
  final ProgressionRepository? progression;

  final DateTime Function()? clock;

  static const String routePath = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoRouter? _router;
  String? _homeLocation;
  bool _wasTop = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (identical(router, _router)) return;
    _router?.routerDelegate.removeListener(_routeChanged);
    _router = router;
    _homeLocation = GoRouterState.of(context).matchedLocation;
    _wasTop = true;
    router.routerDelegate.addListener(_routeChanged);
  }

  void _routeChanged() {
    final top = _router
        ?.routerDelegate
        .currentConfiguration
        .lastOrNull
        ?.matchedLocation;
    final isTop = top == _homeLocation;
    final returned = isTop && !_wasTop;
    _wasTop = isTop;
    if (!returned) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_wasTop) return;
      final session = context.read<SessionCubit>().state;
      if (session is SessionAuthenticated) {
        context.read<HomeCubit>().load(session.user.uid);
      }
    });
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_routeChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionCubit>().state;
    if (session is SessionAuthenticated) {
      context.read<HomeCubit>().load(session.user.uid);
    }
  }

  void _comingSoon() => context.push('/coach');

  void _openMealLog() => context.push('/log');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading) {
                return const HomeLoadingSkeleton();
              }
              if (state is HomeFailure) {
                return AppErrorView(
                  message: l10n.stateError,
                  onRetry: () {
                    final session = context.read<SessionCubit>().state;
                    if (session is SessionAuthenticated) {
                      context.read<HomeCubit>().load(session.user.uid);
                    }
                  },
                );
              }
              final loaded = state as HomeLoaded;
              return _HomeContent(
                loaded: loaded,
                progression: widget.progression,
                waterRepository: widget.waterRepository,
                comingSoon: _comingSoon,
                now: (widget.clock ?? DateTime.now)(),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FloatingGlassNavBar(
          currentIndex: 0,
          onAdd: _openMealLog,
          items: [
            NavItem(
              label: l10n.navHome,
              icon: Icons.home_rounded,
              onTap: () {},
            ),
            NavItem(
              label: l10n.navDiary,
              icon: Icons.calendar_today_rounded,
              onTap: () => context.push('/diary'),
            ),
            NavItem(
              label: l10n.navProgress,
              icon: Icons.show_chart_rounded,
              onTap: () => context.go('/stats'),
            ),
            NavItem(
              label: l10n.navAccount,
              icon: Icons.person_outline_rounded,
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.loaded,
    required this.comingSoon,
    required this.now,
    this.progression,
    this.waterRepository,
  });

  final DateTime now;
  final WaterWeightRepository? waterRepository;
  final ProgressionRepository? progression;

  final HomeLoaded loaded;
  final VoidCallback comingSoon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = loaded.profile?.displayName.isNotEmpty == true
        ? loaded.profile!.displayName.split(' ').first
        : '';
    final hour = now.hour;
    final greeting = hour < 12
        ? l10n.homeGreetingMorning
        : l10n.homeGreetingEvening;
    final plan = loaded.nutritionProfile;

    return RefreshIndicator(
      onRefresh: () async {
        final session = context.read<SessionCubit>().state;
        if (session is SessionAuthenticated) {
          await context.read<HomeCubit>().load(session.user.uid);
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Scaffold reserves the navigation bar height, so do not reserve it
        // again inside the scroll content.
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          Flex(
            direction: MediaQuery.textScalerOf(context).scale(13) > 18
                ? Axis.vertical
                : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: MediaQuery.textScalerOf(context).scale(13) > 18 ? 0 : 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SufraLogo(size: 46),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: context.greetingStyle(
                              size: 14,
                              color: AppColors.goldDeep,
                            ),
                          ),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context
                                .readableDisplayStyle(size: 26)
                                .copyWith(height: 1.1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  LocalProfileAvatar(
                    uid:
                        (context.read<SessionCubit>().state
                                as SessionAuthenticated)
                            .user
                            .uid,
                  ),
                  const SizedBox(width: 9),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: 15,
                    onTap: () => context.push('/reminders'),
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(Icons.notifications_outlined, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            borderRadius: 99,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () => context.push(FoodSearchScreen.routePath),
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.cyanLight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.homeSearchHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.mutedStyle(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (loaded.liveFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'التحديث المباشر اتوقف. اسحب لتحديث السجل.'
                    : 'Live updates stopped. Pull to refresh your records.',
              ),
            ),
          const HomeHeroCard(),
          const SizedBox(height: 12),
          DailyNutritionCard(data: loaded),
          const SizedBox(height: 12),
          Row(
            children: [
              MacroTile(
                label: l10n.macroProtein,
                current: loaded.eatenProtein,
                target: plan?.proteinTarget ?? 0,
                color: AppColors.macroProtein,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0891B2), AppColors.turquoise],
                ),
              ),
              const SizedBox(width: 10),
              MacroTile(
                label: l10n.macroCarbs,
                current: loaded.eatenCarbs,
                target: plan?.carbsTarget ?? 0,
                color: AppColors.macroCarbs,
                gradient: const LinearGradient(
                  colors: [AppColors.orangeDeep, AppColors.copper],
                ),
              ),
              const SizedBox(width: 10),
              MacroTile(
                label: l10n.macroFat,
                current: loaded.eatenFat,
                target: plan?.fatTarget ?? 0,
                color: AppColors.macroFat,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6D28D9), AppColors.aiPurple],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DailyInsightCard(data: loaded),
          const SizedBox(height: 12),
          if (progression != null && loaded.profile != null) ...[
            HomeProgressCard(
              uid: loaded.profile!.uid,
              repository: progression!,
              todayKey: SufraDateUtils.toDateKey(now),
            ),
            const SizedBox(height: 12),
          ],
          DailyActivityCard(data: loaded),
          const SizedBox(height: 12),
          if (waterRepository != null && loaded.profile != null) ...[
            DashboardWaterCard(
              uid: loaded.profile!.uid,
              repository: waterRepository!,
            ),
            const SizedBox(height: 12),
          ],
          ConsistencyCard(data: loaded, now: now),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homeBrowseMeals,
                  style: context.readableDisplayStyle(size: 19),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/favorites'),
                child: Text(l10n.logHubFavoritesTitle),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in [
                (l10n.logHubSearchTitle, Icons.search, '/food-search'),
                (l10n.logHubPhotoTitle, Icons.camera_alt_outlined, '/camera'),
                (
                  l10n.logHubFavoritesTitle,
                  Icons.favorite_border,
                  '/favorites',
                ),
              ])
                GlassShortcut(
                  icon: entry.$2,
                  label: entry.$1,
                  onPressed: () => context.push(entry.$3),
                ),
            ],
          ),
          const SizedBox(height: 12),
          HomeActivityStory(data: loaded, now: now),
          const SizedBox(height: 16),
          const HomeRecipeSection(),
          const SizedBox(height: 16),
          Text(
            l10n.homeMealsToday,
            style: context.readableDisplayStyle(size: 19),
          ),
          const SizedBox(height: 8),
          if (loaded.todaysMeals.isEmpty)
            GlassCard(
              child: AppEmptyView(
                message: l10n.homeNoMeals,
                icon: Icons.no_meals_outlined,
              ),
            )
          else
            ...loaded.todaysMeals.map(
              (meal) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MealCard(meal: meal),
              ),
            ),
          TextButton(
            onPressed: () => context.push('/diary'),
            child: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'افتح سجل الوجبات'
                  : 'Open meal diary',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeTipsTitle,
            style: context.readableDisplayStyle(size: 19),
          ),
          const SizedBox(height: 8),
          _TipCard(
            icon: Icons.water_drop_outlined,
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.turquoise],
            ),
            title: l10n.tipWaterTitle,
            body:
                '${l10n.waterMlOf((loaded.hydrationGoalMl ?? 2000).toStringAsFixed(0), (loaded.dailyLog?.waterIntakeMl ?? 0).toStringAsFixed(0))} · ${loaded.hydrationGoalMl == null ? l10n.waterGoalDefaultNote : l10n.waterGoalChosenNote}',
            onTap: () => context.push('/water'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: l10n.appLanguage,
                icon: const Icon(Icons.translate, size: 20),
                onPressed: () => showLanguageSettings(context),
              ),
              const LiquidThemeButton(),
              IconButton(
                tooltip: l10n.themeAccentPicker,
                icon: const Icon(Icons.palette_outlined, size: 20),
                onPressed: () => showSufraDialog<void>(
                  context: context,
                  builder: (_) => SufraAlertDialog(
                    title: Text(
                      l10n.themeAccentPicker,
                      style: context.readableDisplayStyle(size: 21),
                    ),
                    scrollable: true,
                    content: const AccentPalettePicker(named: true),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const HomeQuickActions(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});

  final MealEntryModel meal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final typeLabel = switch (meal.mealType) {
      'breakfast' => l10n.mealBreakfast,
      'lunch' => l10n.mealLunch,
      'dinner' => l10n.mealDinner,
      'suhoor' => l10n.mealSuhoor,
      'iftar' => l10n.mealIftar,
      _ => l10n.mealSnack,
    };
    final large = MediaQuery.textScalerOf(context).scale(14) > 20;
    final catalogTitle =
        meal.inputMethod == 'catalog' &&
        meal.items.length == 1 &&
        meal.title == meal.items.single.foodName;
    final fallback = meal.items.length == 1
        ? CatalogFoodArt(id: meal.items.single.foodId, size: 62)
        : const _MealImagePlaceholder();
    return GlassCard(
      key: ValueKey('home-meal-${meal.mealId}'),
      borderColor: const Color(0x77D99A35),
      onTap: () => context.push(MealDetailScreen.locationFor(meal)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Flex(
        direction: large ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: large
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 62,
              height: 62,
              child:
                  meal.imageUrl != null &&
                      Uri.tryParse(meal.imageUrl!)?.scheme == 'https'
                  ? Image.network(
                      meal.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallback,
                    )
                  : fallback,
            ),
          ),
          SizedBox(width: large ? 0 : 10, height: large ? 10 : 0),
          Flexible(
            flex: large ? 0 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (catalogTitle)
                  SavedCatalogLabel(
                    item: meal.items.single,
                    style: context.mutedStyle(),
                  )
                else
                  Text(meal.title, style: context.mutedStyle()),
              ],
            ),
          ),
          SizedBox(width: large ? 0 : 10, height: large ? 10 : 0),
          Column(
            crossAxisAlignment: large
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Text(
                '${meal.totalCalories.round()}',
                textDirection: TextDirection.ltr,
                style: context.readableDisplayStyle(size: 22),
              ),
              Text(l10n.unitKcal, style: context.mutedStyle(size: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealImagePlaceholder extends StatelessWidget {
  const _MealImagePlaceholder();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .6),
    ),
    child: const Icon(
      Icons.restaurant_outlined,
      color: AppColors.orangeDeep,
      size: 30,
    ),
  );
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final Gradient gradient;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: gradient,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(body, style: context.mutedStyle(size: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
