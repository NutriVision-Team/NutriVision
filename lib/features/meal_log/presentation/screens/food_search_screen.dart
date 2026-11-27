import '../../../../core/widgets/catalog_food_art.dart';
import 'manual_food_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../data/models/food_catalog_model.dart';
import '../../../../data/repositories/food_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/food_search_cubit.dart';
import 'food_detail_screen.dart';

class FoodSearchScreen extends StatelessWidget {
  const FoodSearchScreen({
    super.key,
    this.selectOnly = false,
    this.initialQuery = '',
  });
  final bool selectOnly;
  final String initialQuery;
  static const pickRoutePath = '/food-pick';
  static const routePath = '/food-search';

  @override
  Widget build(BuildContext context) => BlocProvider(
    lazy: false,
    create: (context) {
      final repository = context.read<FoodRepository>();
      final cubit = FoodSearchCubit(repository);
      if (initialQuery.trim().isNotEmpty) {
        cubit.search(initialQuery);
      } else if (repository is FoodCategoryBrowser) {
        cubit.browse();
      }
      return cubit;
    },
    child: _FoodSearchBody(selectOnly: selectOnly, initialQuery: initialQuery),
  );
}

class _FoodSearchBody extends StatefulWidget {
  const _FoodSearchBody({required this.selectOnly, required this.initialQuery});
  final String initialQuery;
  final bool selectOnly;
  @override
  State<_FoodSearchBody> createState() => _FoodSearchBodyState();
}

class _FoodSearchBodyState extends State<_FoodSearchBody> {
  final _query = TextEditingController();
  @override
  void initState() {
    super.initState();
    _query.text = widget.initialQuery;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search(String value) {
    setState(() {});
    final cubit = context.read<FoodSearchCubit>();
    if (value.trim().isEmpty) {
      cubit.browse(category: category, egyptian: egyptian);
    } else {
      cubit.search(value);
    }
  }

  String? category;
  bool egyptian = false;
  bool get selectOnly => widget.selectOnly;
  void browse({String? selectedCategory, bool staples = false}) {
    setState(() {
      category = selectedCategory;
      egyptian = staples;
    });
    context.read<FoodSearchCubit>().filter(
      category: selectedCategory,
      egyptian: staples,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoryName = <String, String>{
      'grains': l10n.foodCategoryGrains,
      'legumes': l10n.foodCategoryLegumes,
      'vegetables': l10n.foodCategoryVegetables,
      'dairy': l10n.foodCategoryDairy,
      'poultry': l10n.foodCategoryPoultry,
    }[category];
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ChipTheme(
              data: ChipTheme.of(context).copyWith(
                selectedColor: AppColors.turquoise,
                secondarySelectedColor: AppColors.turquoise,
                shape: const StadiumBorder(),
                side: BorderSide.none,
                showCheckmark: false,
              ),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const BackButtonIcon(),
                        tooltip: l10n.wizardBack,
                      ),
                      Expanded(
                        child: Text(
                          l10n.logHubSearchTitle,
                          style: context.readableDisplayStyle(size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _query,
                    maxLength: 120,
                    onChanged: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.foodSearchHint,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.cyanLight,
                      ),
                      counterText: '',
                      suffixIcon: _query.text.isEmpty
                          ? null
                          : IconButton(
                              key: const ValueKey('clear-food-query'),
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).deleteButtonTooltip,
                              onPressed: () {
                                _query.clear();
                                _search('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.cyanLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => context.push('/recipes'),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'وصفات مصرية وعربية'
                              : 'Egyptian & Arab recipes',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/alternatives'),
                        icon: const Icon(Icons.swap_horiz),
                        label: Text(l10n.foodAlternatives),
                      ),
                    ],
                  ),
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'اسحب التصنيفات لرؤية المزيد'
                        : 'Swipe categories to see more',
                    style: context.mutedStyle(size: 11),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            key: const ValueKey('food-category-all'),
                            selected: category == null && !egyptian,
                            label: Text(l10n.foodCategoryAll),
                            onSelected: (_) => browse(),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            key: const ValueKey('food-category-egyptian'),
                            selected: egyptian,
                            label: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width - 160,
                              ),
                              child: Text(
                                l10n.foodCategoryEgyptian,
                                softWrap: true,
                                maxLines: 3,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            onSelected: (_) => browse(staples: true),
                          ),
                          for (final (id, title) in [
                            ('grains', l10n.foodCategoryGrains),
                            ('legumes', l10n.foodCategoryLegumes),
                            ('vegetables', l10n.foodCategoryVegetables),
                            ('dairy', l10n.foodCategoryDairy),
                            ('poultry', l10n.foodCategoryPoultry),
                          ])
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 6,
                              ),
                              child: ChoiceChip(
                                key: ValueKey('food-category-$id'),
                                selected: category == id && !egyptian,
                                label: Text(title),
                                onSelected: (_) => browse(selectedCategory: id),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 6),
                            child: ActionChip(
                              label: Text(l10n.foodCategoryProducts),
                              onPressed: () => context.push('/barcode'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categoryName == null
                        ? l10n.foodCatalogTitle
                        : '${l10n.foodCatalogTitle} · $categoryName',
                    style: context.readableDisplayStyle(size: 18),
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<FoodSearchCubit, FoodSearchState>(
                    builder: (context, state) => switch (state.status) {
                      FoodSearchStatus.idle => AppEmptyView(
                        message: l10n.foodSearchStart,
                        icon: Icons.search,
                      ),
                      FoodSearchStatus.loading => const AppLoadingView(),
                      FoodSearchStatus.failure => AppErrorView(
                        onRetry: context.read<FoodSearchCubit>().retry,
                      ),
                      FoodSearchStatus.ready =>
                        state.foods.isEmpty
                            ? AppEmptyView(message: l10n.foodSearchEmpty)
                            : GlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: Column(
                                  children: [
                                    for (final food in state.foods)
                                      _FoodRow(
                                        food: food,
                                        selectOnly: selectOnly,
                                      ),
                                  ],
                                ),
                              ),
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context)
                          .push<FoodCatalogModel>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ManualFoodScreen(selectOnly: selectOnly),
                            ),
                          );
                      if (context.mounted && selectOnly && result != null) {
                        context.pop(result);
                      }
                    },
                    icon: const Icon(Icons.edit_note),
                    label: Text(l10n.foodManualTitle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.food, required this.selectOnly});
  final FoodCatalogModel food;
  final bool selectOnly;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final calories = food.nutritionPer100g?['calories'];
    // Unknown nutritional values are never replaced with zero.
    final value = calories is num && calories.isFinite && calories >= 0
        ? l10n.foodPer100g(calories.toStringAsFixed(0))
        : l10n.foodNutritionUnknown;
    return InkWell(
      key: ValueKey('food-result-${food.foodId}'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => selectOnly
          ? context.pop(food)
          : context.push(FoodDetailScreen.routePath, extra: food),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ExcludeSemantics(child: CatalogFoodArt(size: 56, id: food.foodId)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (food.localizedNames?[Localizations.localeOf(
                              context,
                            ).languageCode]
                            as String?) ??
                        food.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (calories is num && calories.isFinite && calories >= 0)
                    Wrap(
                      spacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.ltr,
                          children: [
                            Text('100 ', style: context.mutedStyle(size: 12)),
                            Text(
                              l10n.foodGramUnit,
                              style: context.mutedStyle(size: 12),
                            ),
                          ],
                        ),
                        Text('·', style: context.mutedStyle(size: 12)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.ltr,
                          children: [
                            Text(
                              '${calories.toStringAsFixed(0)} ',
                              style: context.mutedStyle(size: 12),
                            ),
                            Text(
                              l10n.foodKcal,
                              style: context.mutedStyle(size: 12),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Text(value, style: context.mutedStyle(size: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
