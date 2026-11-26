import '../../../../core/widgets/sufra_lustre.dart';
import '../../../../core/widgets/catalog_food_art.dart';
import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:flutter/material.dart';
import 'package:sufradepi/core/widgets/sufra_button_response.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../data/models/favorite_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/favorites_logic.dart';
import '../cubit/favorites_cubit.dart';

/// Screen 20 "المفضلة". The cubit must be provided above (bound to the
/// signed-in uid). Navigation callbacks are optional: when null the matching
/// affordance is not shown, so nothing is a dead tap.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    this.onOpenMeal,
    this.onOpenRecipe,
    this.onBack,
  });
  final void Function(FavoriteMealView view)? onOpenMeal;
  final void Function(FavoriteModel recipe)? onOpenRecipe;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: BlocConsumer<FavoritesCubit, FavoritesState>(
          listenWhen: (a, b) => a.noticeSeq != b.noticeSeq,
          listener: (context, s) {
            final text = switch (s.notice) {
              FavoritesNotice.removed => l.favoritesRemoved,
              FavoritesNotice.removeFailed => l.favoritesRemoveFailed,
              FavoritesNotice.added => l.favoritesAdded,
              FavoritesNotice.addFailed => l.favoritesAddFailed,
              FavoritesNotice.favoriteSaved => l.favoritesSaved,
              FavoritesNotice.favoriteSaveFailed => l.favoritesSaveFailed,
              FavoritesNotice.none => null,
            };
            if (text != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SufraSnackBar(content: Text(text)));
            }
          },
          builder: (context, s) {
            final cubit = context.read<FavoritesCubit>();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Row(
                    children: [
                      if (onBack != null)
                        IconButton(
                          onPressed: onBack,
                          tooltip: l.premiumBack,
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          l.favoritesTitle,
                          style: context.readableDisplayStyle(size: 28),
                        ),
                      ),
                      if (s.status == FavoritesStatus.ready &&
                          s.tab == FavoritesTab.meals)
                        _SortButton(sort: s.sort, onSelected: cubit.setSort),
                    ],
                  ),
                ),
                _Tabs(tab: s.tab, onChanged: cubit.setTab),
                const SizedBox(height: 12),
                Expanded(child: _body(context, s, cubit, l)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    FavoritesState s,
    FavoritesCubit cubit,
    AppLocalizations l,
  ) {
    switch (s.status) {
      case FavoritesStatus.loading:
        return const AppLoadingView();
      case FavoritesStatus.failure:
        return AppErrorView(
          message: l.favoritesLoadFailed,
          onRetry: cubit.load,
        );
      case FavoritesStatus.expired:
        return AppErrorView(message: l.favoritesExpired);
      case FavoritesStatus.ready:
        break;
    }
    return switch (s.tab) {
      FavoritesTab.meals => _mealsTab(context, s, cubit, l),
      FavoritesTab.recipes => _recipesTab(context, s, cubit, l),
      FavoritesTab.frequent => _frequentTab(context, s, l),
    };
  }

  Widget _mealsTab(
    BuildContext c,
    FavoritesState s,
    FavoritesCubit cubit,
    AppLocalizations l,
  ) {
    if (s.meals.isEmpty && s.hero == null) {
      return _Empty(
        title: l.favoritesEmptyMealsTitle,
        message: l.favoritesEmptyMealsBody,
      );
    }
    final fmt = NumberFormat.decimalPattern(
      Localizations.localeOf(c).toString(),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        if (s.hero != null) _Hero(hero: s.hero!),
        if (s.hero != null) const SizedBox(height: 14),
        if (s.meals.isEmpty)
          _Empty(
            title: l.favoritesEmptyMealsTitle,
            message: l.favoritesEmptyMealsBody,
          )
        else if (MediaQuery.textScalerOf(c).scale(14) > 20 ||
            MediaQuery.sizeOf(c).width < 380)
          for (final view in s.meals)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MealCard(
                view: view,
                busy: s.busyIds.contains(view.favorite.favoriteId),
                fmt: fmt,
                onOpen: onOpenMeal,
                onRemove: () => cubit.remove(view.favorite),
                onAdd: () => _pickType(c, view, cubit),
              ),
            )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
            children: [
              for (var i = 0; i < s.meals.length; i++)
                _MealCard(
                  view: s.meals[i],
                  busy: s.busyIds.contains(s.meals[i].favorite.favoriteId),
                  fmt: fmt,
                  onOpen: onOpenMeal,
                  onRemove: () => cubit.remove(s.meals[i].favorite),
                  onAdd: () => _pickType(c, s.meals[i], cubit),
                ),
            ],
          ),
      ],
    );
  }

  Widget _recipesTab(
    BuildContext c,
    FavoritesState s,
    FavoritesCubit cubit,
    AppLocalizations l,
  ) {
    if (s.recipes.isEmpty) {
      return _Empty(
        title: l.favoritesEmptyRecipesTitle,
        message: l.favoritesEmptyRecipesBody,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: s.recipes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = s.recipes[i];
        final busy = s.busyIds.contains(r.favoriteId);
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          onTap: onOpenRecipe == null ? null : () => onOpenRecipe!(r),
          child: Row(
            children: [
              _FavoriteRecipeArt(id: r.targetId),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  r.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: l.favoritesRemove,
                onPressed: busy ? null : () => cubit.remove(r),
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _frequentTab(BuildContext c, FavoritesState s, AppLocalizations l) {
    if (s.frequent.isEmpty && s.foods.isEmpty) {
      return _Empty(
        title: l.favoritesEmptyFrequentTitle,
        message: l.favoritesEmptyFrequentBody,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        if (s.foods.isNotEmpty) ...[
          Text(
            Localizations.localeOf(c).languageCode == 'ar'
                ? 'أطعمة مفضلة من تكرار التسجيل'
                : 'Favorite foods from repeated logging',
            style: c.readableDisplayStyle(size: 18),
          ),
          for (final f in s.foods)
            ListTile(
              leading: SizedBox.square(
                dimension: 52,
                child: CatalogFoodArt(id: f.targetId, size: 52),
              ),
              title: Text(f.title),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                tooltip: l.favoritesRemove,
                onPressed: () => c.read<FavoritesCubit>().remove(f),
              ),
            ),
        ],
        if (s.frequent.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(l.favoritesFrequentNote, style: c.mutedStyle()),
          ),
        for (var i = 0; i < s.frequent.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CatalogFoodArt(id: s.frequent[i].foodId, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.frequent[i].name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    l.favoritesFrequentCount(s.frequent[i].count),
                    style: c.mutedStyle(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickType(
    BuildContext c,
    FavoriteMealView view,
    FavoritesCubit cubit,
  ) async {
    final l = AppLocalizations.of(c);
    final types = {
      'breakfast': l.mealBreakfast,
      'lunch': l.mealLunch,
      'dinner': l.mealDinner,
      'snack': l.mealSnack,
    };
    final picked = await showSufraBottomSheet<String>(
      context: c,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l.favoritesPickMealType,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final e in types.entries)
              ListTile(
                title: Text(e.value),
                onTap: () => Navigator.pop(ctx, e.key),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await cubit.addToDiary(view, picked);
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab, required this.onChanged});
  final FavoritesTab tab;
  final ValueChanged<FavoritesTab> onChanged;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = {
      FavoritesTab.meals: l.favoritesTabMeals,
      FavoritesTab.recipes: l.favoritesTabRecipes,
      FavoritesTab.frequent: l.favoritesTabFrequent,
    };
    final large = MediaQuery.textScalerOf(context).scale(13) > 18;
    if (large) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in labels.entries)
              ChoiceChip(
                selected: tab == e.key,
                label: Text(e.value),
                side: const BorderSide(color: Color(0xFFD99A35)),
                onSelected: (_) => onChanged(e.key),
              ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: .1)),
        ),
        child: Row(
          children: [
            for (final e in labels.entries)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: tab == e.key,
                  child: SufraControlFeedback(
                    radius: 99,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: tab == e.key
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFB8C00),
                                    Color(0xFFE65100),
                                  ],
                                )
                              : null,
                        ),
                        child: Text(
                          e.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tab == e.key
                                ? Colors.white
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onSelected});
  final FavoritesSort sort;
  final ValueChanged<FavoritesSort> onSelected;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = {
      FavoritesSort.recent: l.favoritesSortRecent,
      FavoritesSort.name: l.favoritesSortName,
      FavoritesSort.calories: l.favoritesSortCalories,
    };
    return PopupMenuButton<FavoritesSort>(
      tooltip: l.favoritesSortLabel,
      initialValue: sort,
      onSelected: onSelected,
      icon: const Icon(Icons.sort_rounded),
      itemBuilder: (_) => [
        for (final e in labels.entries)
          PopupMenuItem(value: e.key, child: Text(e.value)),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.hero});
  final ({String title, int count}) hero;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SufraLustre(
      float: true,
      color: const Color(0xFFFDBA74),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0x66FB8C00), Color(0x667C3AED)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .14)),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: _FloatingHearts()),
            ),
            Row(
              children: [
                const _FoodThumb(size: 76),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l.favoritesHeroChip,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hero.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.favoritesHeroCount(hero.count),
                        style: context.mutedStyle(size: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.view,
    required this.busy,
    required this.fmt,
    required this.onOpen,
    required this.onRemove,
    required this.onAdd,
  });
  final FavoriteMealView view;
  final bool busy;
  final NumberFormat fmt;
  final void Function(FavoriteMealView)? onOpen;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final meal = view.meal;
    final String meta;
    if (meal == null) {
      meta = l.favoritesUnavailable;
    } else if (meal.totalProtein == null) {
      meta = l.favoritesMealMeta(fmt.format(meal.totalCalories.round()));
    } else {
      meta = l.favoritesMealMetaProtein(
        fmt.format(meal.totalCalories.round()),
        fmt.format(meal.totalProtein!.round()),
      );
    }
    final naturalHeight =
        MediaQuery.textScalerOf(context).scale(14) > 20 ||
        MediaQuery.sizeOf(context).width < 380;
    return GlassCard(
      borderColor: const Color(0x77D99A35),
      padding: const EdgeInsets.all(12),
      onTap: meal != null && onOpen != null ? () => onOpen!(view) : null,
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: l.favoritesRemove,
                onPressed: busy ? null : onRemove,
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
            ),
          ),
          Opacity(
            opacity: meal == null ? .4 : 1,
            child: meal != null && meal.items.isNotEmpty
                ? SizedBox(
                    width: 120,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (var i = 0; i < meal.items.take(4).length; i++)
                          Positioned(
                            left: i * 26.0,
                            child: CatalogFoodArt(
                              id: meal.items[i].foodId,
                              size: 42,
                            ),
                          ),
                      ],
                    ),
                  )
                : _FoodThumb(size: 64, imageUrl: view.favorite.imageUrl),
          ),
          const SizedBox(height: 8),
          Text(
            view.favorite.title,
            maxLines: naturalHeight ? null : 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            meta,
            maxLines: naturalHeight ? null : 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: context.mutedStyle(size: 11),
          ),
          if (naturalHeight) const SizedBox(height: 12) else const Spacer(),
          if (meal != null)
            Align(
              alignment: Alignment.bottomLeft,
              child: Semantics(
                button: true,
                label: l.favoritesAddToDiary,
                child: SufraControlFeedback(
                  radius: 20,
                  child: GestureDetector(
                    onTap: busy ? null : onAdd,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF22C55E),
                      ),
                      child: busy
                          ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.message});
  final String title, message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 44,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.mutedStyle(),
          ),
        ],
      ),
    ),
  );
}

/// Neutral thumbnail. The app has no per-meal artwork, and the design's
/// sprite cells are fixed sample dishes, so a real photo (imageUrl) is used
/// when present, otherwise a plain glass circle with a generic icon.
class _FoodThumb extends StatelessWidget {
  const _FoodThumb({required this.size, this.imageUrl});
  final double size;
  final String? imageUrl;
  @override
  Widget build(BuildContext context) {
    final fallback = SizedBox(
      width: size,
      height: size,
      child: const Icon(Icons.restaurant_outlined),
    );
    final url = imageUrl;
    if (url == null || !(Uri.tryParse(url)?.hasScheme ?? false)) {
      return fallback;
    }
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// Port of the design's `.sxp` hearts: three #FB7185 hearts rise 44px and
/// fade over 3s (ease-in, loop) with 0 / 0.9 / 1.7s delays. Static when the
/// platform asks for reduced motion.
class _FloatingHearts extends StatefulWidget {
  const _FloatingHearts();
  @override
  State<_FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<_FloatingHearts>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.stop();
      _started = false;
    } else if (!_started) {
      _started = true;
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const _hearts = [
    (14.0, 14.0, 0.0),
    (60.0, 60.0, 0.9),
    (30.0, 90.0, 1.7),
  ];

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(
          children: [
            for (final h in _hearts)
              _heart(
                h.$1,
                h.$2,
                reduce ? .5 : (((_c.value * 3 - h.$3) / 3) % 1 + 1) % 1,
                reduce,
              ),
          ],
        ),
      ),
    );
  }

  Widget _heart(double right, double top, double t, bool reduce) {
    // keyframes: 0% y+10 scale .6 op 0 / 30% op .9 / 100% y-34 scale 1.2 op 0
    final op = reduce ? .6 : (t < .3 ? t / .3 * .9 : .9 * (1 - (t - .3) / .7));
    final dy = reduce ? 0.0 : 10 - 44 * Curves.easeIn.transform(t);
    final scale = reduce ? 1.0 : .6 + .6 * Curves.easeIn.transform(t);
    return PositionedDirectional(
      end: right,
      top: top,
      child: Opacity(
        opacity: op.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            child: const Icon(
              Icons.favorite_rounded,
              size: 16,
              color: Color(0xFFFB7185),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteRecipeArt extends StatelessWidget {
  const _FavoriteRecipeArt({required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    const bindings = {
      'themealdb_53025': 'ful',
      'themealdb_53026': 'taameya',
      'themealdb_53027': 'koshari',
      'themealdb_52963': 'shakshuka',
      'themealdb_53028': 'shawarma',
      'themealdb_53029': 'molokhia',
      'themealdb_53030': 'feteer',
      'themealdb_53031': 'fatta',
    };
    final name = bindings[id];
    if (name == null) return const _FoodThumb(size: 52);
    final original = const {'ful', 'taameya', 'koshari'}.contains(name);
    return Semantics(
      image: true,
      label: Localizations.localeOf(context).languageCode == 'ar'
          ? 'رسم توضيحي للطبق، مش قياس للحصة'
          : 'Dish illustration, not a portion measurement',
      child: Image.asset(
        'assets/images/${original ? 'reference_food' : 'generated_food'}/$name.png',
        width: 52,
        height: 52,
        fit: BoxFit.contain,
      ),
    );
  }
}
