import '../../../../core/widgets/sufra_lustre.dart';
import '../../../../core/widgets/dish_float.dart';
import '../../../../core/widgets/sufra_button_response.dart';
import '../../../../core/widgets/sufra_dialog.dart';
import '../../../recipes/presentation/screens/recipe_detail_screen.dart'
    show RecipeSourceImage;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../recipes/data/datasources/local_recipe_data_source.dart';
import '../../../recipes/domain/recipe_catalog_repository.dart';

/// Original featured/stacked composition populated only from real source data.
/// Source categories are not silently converted into meal or health labels.
class HomeRecipeSection extends StatefulWidget {
  const HomeRecipeSection({super.key, this.repository});
  final RecipeCatalogRepository? repository;
  @override
  State<HomeRecipeSection> createState() => _HomeRecipeSectionState();
}

class _HomeRecipeSectionState extends State<HomeRecipeSection> {
  late Future<List<LocalRecipeRecord>> _recipes;
  String? _category;

  Future<List<LocalRecipeRecord>> _load() =>
      (widget.repository ?? RecipeCatalogRepository()).getAll();
  @override
  void initState() {
    super.initState();
    _recipes = _load();
  }

  @override
  void didUpdateWidget(covariant HomeRecipeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _category = null;
      _recipes = _load();
    }
  }

  String _categoryName(String value, AppLocalizations l) => switch (value) {
    'Vegetarian' => l.homeCategoryVegetarian,
    'Chicken' => l.homeCategoryChicken,
    'Beef' => l.homeCategoryBeef,
    'Side' => l.homeCategorySide,
    _ => value,
  };
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<List<LocalRecipeRecord>>(
      future: _recipes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.homeRecipeUnavailable),
                TextButton.icon(
                  onPressed: () => setState(() => _recipes = _load()),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'حاول تاني'
                        : 'Try again',
                  ),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final all = snapshot.data!;
        if (all.isEmpty) return GlassCard(child: Text(l.homeRecipeUnavailable));
        final categories =
            all
                .map((r) => r.category)
                .whereType<String>()
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        final recipes = all
            .where((r) => _category == null || r.category == _category)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final category in <String?>[null, ...categories])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        key: ValueKey('home-category-${category ?? 'all'}'),
                        side: const BorderSide(color: Color(0xFFD99A35)),
                        selected: _category == category,
                        label: Text(
                          category == null
                              ? l.foodCategoryAll
                              : _categoryName(category, l),
                        ),
                        onSelected: (_) {
                          setState(() => _category = category);
                        },
                        selectedColor: AppColors.aiPurple,
                        labelStyle: TextStyle(
                          color: _category == category ? Colors.white : null,
                          fontWeight: FontWeight.w700,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(l.homeSourceCategoryNote, style: context.mutedStyle(size: 11)),
            const SizedBox(height: 10),
            if (recipes.isNotEmpty) _FeaturedRecipe(recipe: recipes.first),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l.homeMealSuggestions,
                  style: context.readableDisplayStyle(size: 19),
                ),
                TextButton(
                  onPressed: () => context.push('/recipes'),
                  child: Text(l.homeOpenRecipes),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final recipe in recipes.skip(1).take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecipeRow(recipe: recipe),
              ),
          ],
        );
      },
    );
  }
}

String _name(BuildContext context, LocalRecipeRecord recipe) =>
    Localizations.localeOf(context).languageCode == 'ar'
    ? recipe.nameAr ?? recipe.nameEn
    : recipe.nameEn;
void _details(BuildContext context, LocalRecipeRecord recipe) =>
    context.push('/recipe/${Uri.encodeComponent(recipe.id)}');

class _RecipePhoto extends StatelessWidget {
  const _RecipePhoto({
    required this.recipe,
    required this.size,
    this.round = false,
  });
  final LocalRecipeRecord recipe;
  final double size;
  final bool round;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(round ? size : 20),
    child: SizedBox(
      width: size,
      height: size,
      child: RecipeSourceImage(recipe: recipe, size: size),
    ),
  );
}

class _FeaturedRecipe extends StatelessWidget {
  const _FeaturedRecipe({required this.recipe});
  final LocalRecipeRecord recipe;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final large = MediaQuery.textScalerOf(context).scale(13) > 18;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.copper,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            l.homeFeaturedRecipe,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBackground,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _name(context, recipe),
          style: context.readableDisplayStyle(size: 20),
        ),
        const SizedBox(height: 6),
        Text(l.homeRecipeNutritionUnknown, style: context.mutedStyle(size: 12)),
        const SizedBox(height: 12),
        _RecipePeek(recipe: recipe),
      ],
    );
    return SufraLustre(
      color: AppColors.copper,
      child: GlassCard(
        borderColor: AppColors.copper.withValues(alpha: .5),
        padding: const EdgeInsets.all(16),
        onTap: () => _details(context, recipe),
        child: large
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DishFloat(
                    child: _RecipePhoto(recipe: recipe, size: 128, round: true),
                  ),
                  const SizedBox(height: 12),
                  content,
                ],
              )
            : Row(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -12),
                    child: DishFloat(
                      child: _RecipePhoto(
                        recipe: recipe,
                        size: 128,
                        round: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: content),
                ],
              ),
      ),
    );
  }
}

class _RecipeRow extends StatelessWidget {
  const _RecipeRow({required this.recipe});
  final LocalRecipeRecord recipe;
  @override
  Widget build(BuildContext context) => GlassCard(
    borderColor: AppColors.copper.withValues(alpha: .4),
    padding: const EdgeInsets.all(10),
    onTap: () => _details(context, recipe),
    child: Row(
      children: [
        _RecipePhoto(recipe: recipe, size: 76),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _name(context, recipe),
                style: context.readableDisplayStyle(size: 18),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).homeRecipeNutritionUnknown,
                style: context.mutedStyle(size: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.chevron_left_rounded
              : Icons.chevron_right_rounded,
          color: AppColors.copper,
          textDirection: TextDirection.ltr,
        ),
      ],
    ),
  );
}

/// Source-only preview. Does not imply nutrition or a logging action.
class _RecipePeek extends StatelessWidget {
  const _RecipePeek({required this.recipe});
  final LocalRecipeRecord recipe;
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return SufraControlFeedback(
      radius: 18,
      child: OutlinedButton.icon(
        key: ValueKey('recipe-peek-${recipe.id}'),
        onPressed: () => showSufraBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (c) => FractionallySizedBox(
            heightFactor: .8,
            child: _IngredientPreview(recipe: recipe),
          ),
        ),
        icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
        label: Text(ar ? 'المكونات الأول' : 'Peek at ingredients'),
        style:
            OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFFDBA74)
                  : const Color(0xFF8A4000),
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: Color(0xFFD99A35)),
            ).copyWith(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.pressed)) {
                  return Colors.white;
                }
                return Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFFDBA74)
                    : const Color(0xFF8A4000);
              }),
            ),
      ),
    );
  }
}

class _IngredientPreview extends StatelessWidget {
  const _IngredientPreview({required this.recipe});
  final LocalRecipeRecord recipe;
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final ink = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF334155);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _name(context, recipe),
            style: context.readableDisplayStyle(size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            ar
                ? 'بص على المكونات قبل ما تختار'
                : 'Check what you need before choosing',
            style: context.mutedStyle(size: 15).copyWith(color: ink),
          ),
          const SizedBox(height: 8),
          Text(
            ar
                ? 'الأسماء والمقادير بنص المصدر. السعرات محتاجة كميات دقيقة، والوصفة مش مضافة ليوميتك.'
                : 'Names and measures are as published. Nutrition needs exact quantities. This recipe is not logged.',
            style: context.mutedStyle(size: 12).copyWith(color: ink),
          ),
          const SizedBox(height: 18),
          if (recipe.ingredients.isEmpty)
            Text(
              ar
                  ? 'المصدر ما وضحش المكونات.'
                  : 'No ingredients were provided by the source.',
            ),
          for (final ingredient in recipe.ingredients)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                blur: false,
                padding: const EdgeInsets.all(14),
                borderColor: const Color(0x99D99A35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      style: context.readableDisplayStyle(size: 17),
                    ),
                    if (ingredient.measure?.trim().isNotEmpty ?? false) ...[
                      const SizedBox(height: 6),
                      Text(
                        ingredient.measure!,
                        textDirection: TextDirection.ltr,
                        style: context
                            .mutedStyle(size: 14)
                            .copyWith(color: ink),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _details(context, recipe);
            },
            icon: const Icon(Icons.menu_book_rounded),
            label: Text(ar ? 'افتح الوصفة والخطوات' : 'Open recipe and method'),
          ),
        ],
      ),
    );
  }
}
