import '../../../../core/widgets/sufra_lustre.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:sufradepi/core/widgets/sufra_button_response.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/datasources/local_recipe_data_source.dart';
import '../../domain/recipe_catalog_repository.dart';
import '../../domain/ingredient_recipe_matcher.dart';
import '../widgets/discovery_widgets.dart';
import 'recipe_detail_screen.dart';

class RecipeSuggestionScreen extends StatefulWidget {
  const RecipeSuggestionScreen({
    super.key,
    this.repository,
    this.suggestionService,
    this.favorites,
  });
  static const routePath = '/recipes';
  final RecipeCatalogRepository? repository;
  final RecipeSuggestionService? suggestionService;
  final RecipeFavorites? favorites;
  @override
  State<RecipeSuggestionScreen> createState() => _RecipeSuggestionScreenState();
}

class _RecipeSuggestionScreenState extends State<RecipeSuggestionScreen> {
  late RecipeCatalogRepository _repository;
  late Future<List<LocalRecipeRecord>> _load;
  final _search = TextEditingController();
  final _ingredients = <String>[];
  String _mealType = 'lunch';
  double? _maxCalories, _maxMinutes;
  bool _suggesting = false;
  bool _savedOnly = false;
  List<String>? _suggestedIds;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _repository = widget.repository ?? RecipeCatalogRepository();
    _load = _loadCatalogAndFavorites();
  }

  Future<List<LocalRecipeRecord>> _loadCatalogAndFavorites() async {
    final repository = _repository;
    final favorites = widget.favorites;
    final results = await Future.wait<Object?>([
      repository.getAll(),
      if (favorites != null) favorites.refresh(),
    ]);
    return results.first as List<LocalRecipeRecord>;
  }

  @override
  void didUpdateWidget(covariant RecipeSuggestionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.suggestionService != widget.suggestionService ||
        oldWidget.favorites != widget.favorites) {
      _generation++;
      _suggesting = false;
      _suggestedIds = null;
      _savedOnly = false;
      _reset();
    }
  }

  @override
  void dispose() {
    _generation++;
    _search.dispose();
    super.dispose();
  }

  Future<void> _addIngredient() async {
    final ingredient = await showSufraDialog<String>(
      context: context,
      builder: (_) => const _IngredientDialog(),
    );
    if (!mounted || ingredient == null || _ingredients.contains(ingredient)) {
      return;
    }
    setState(() {
      _ingredients.add(ingredient);
      _suggestedIds = null;
    });
  }

  Future<void> _suggestAi(List<LocalRecipeRecord> records) async {
    final service = widget.suggestionService;
    if (service == null) return;
    final generation = ++_generation;
    setState(() => _suggesting = true);
    try {
      final ids = await service.suggest(
        RecipeRequest(
          mealType: _mealType,
          ingredients: List.unmodifiable(_ingredients),
          requireMealType: true,
          maxCalories: _maxCalories,
          maxCookingMinutes: _maxMinutes,
        ),
      );
      if (!mounted || generation != _generation) return;
      final known = records.map((r) => r.id).toSet();
      if (ids.any((id) => !known.contains(id))) {
        throw const FormatException('Unverified recipe ID');
      }
      final allowed = IngredientRecipeMatcher.match(
        records,
        RecipeRequest(
          mealType: _mealType,
          ingredients: List.unmodifiable(_ingredients),
          requireMealType: true,
          maxCalories: _maxCalories,
          maxCookingMinutes: _maxMinutes,
        ),
      ).map((m) => m.recipe.id).toSet();
      setState(() {
        _suggestedIds = ids.where(allowed.contains).toSet().toList();
        _search.clear();
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        await discoveryExplain(
          context,
          AppLocalizations.of(context).discoveryMsg014,
          AppLocalizations.of(context).discoveryMsg015,
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _suggesting = false);
      }
    }
  }

  Future<void> _suggestLocal(List<LocalRecipeRecord> records) async {
    if (_ingredients.isEmpty) {
      await discoveryExplain(
        context,
        AppLocalizations.of(context).discoveryMsg016,
        AppLocalizations.of(context).discoveryMsg017,
      );
      return;
    }
    final matches = IngredientRecipeMatcher.match(
      records,
      RecipeRequest(
        mealType: _mealType,
        ingredients: List.unmodifiable(_ingredients),
        requireMealType: true,
        maxCalories: _maxCalories,
        maxCookingMinutes: _maxMinutes,
      ),
    );
    setState(() {
      _suggestedIds = matches.map((m) => m.recipe.id).toList();
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) => DiscoveryScaffold(
    child: FutureBuilder<List<LocalRecipeRecord>>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: snapshot.error is RecipeLicenseException
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(AppLocalizations.of(context).discoveryMsg018),
                  )
                : DiscoveryError(onRetry: () => setState(_reset)),
          );
        }
        final all = snapshot.data ?? [];
        final byId = {for (final recipe in all) recipe.id: recipe};
        final searched = RecipeCatalogRepository.filter(
          _suggestedIds == null
              ? all
              : _suggestedIds!
                    .map((id) => byId[id])
                    .whereType<LocalRecipeRecord>()
                    .toList(),
          _search.text,
        );
        final saved = widget.favorites?.read() ?? <String>{};
        final records = _savedOnly
            ? searched.where((r) => saved.contains(r.id)).toList()
            : searched;
        return DiscoveryList(
          children: [
            SufraLustre(
              radius: 12,
              color: AppColors.cyanLight,
              child: DiscoveryTitle(
                AppLocalizations.of(context).discoveryMsg019,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                children: [
                  for (final meal in [
                    (
                      'breakfast',
                      AppLocalizations.of(context).discoveryBreakfast,
                    ),
                    ('lunch', AppLocalizations.of(context).discoveryLunch),
                    ('dinner', AppLocalizations.of(context).discoveryDinner),
                  ])
                    Expanded(
                      child: Semantics(
                        selected: _mealType == meal.$1,
                        child: SufraControlFeedback(
                          radius: 99,
                          overlay: true,
                          child: GestureDetector(
                            onTap: _suggesting
                                ? null
                                : () => setState(() {
                                    _mealType = meal.$1;
                                    _suggestedIds = null;
                                  }),
                            child: AnimatedContainer(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                gradient: _mealType == meal.$1
                                    ? AppColors.primaryGradient
                                    : null,
                              ),
                              child: Text(
                                meal.$2,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _mealType == meal.$1
                                      ? FontWeight.w700
                                      : FontWeight.w400,
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
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.of(context).discoveryMsg020,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final ingredient in _ingredients)
                        InputChip(
                          shape: const StadiumBorder(),
                          label: Text(ingredient),
                          onDeleted: _suggesting
                              ? null
                              : () => setState(() {
                                  _ingredients.remove(ingredient);
                                  _suggestedIds = null;
                                }),
                        ),
                      ActionChip(
                        shape: const StadiumBorder(),
                        label: Text(
                          AppLocalizations.of(context).discoveryMsg021,
                        ),
                        backgroundColor: AppColors.cyanLight,
                        labelStyle: const TextStyle(
                          color: AppColors.darkBackground,
                        ),
                        onPressed: _suggesting ? null : _addIngredient,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      AppLocalizations.of(context).recipeCalorieLimit,
                    ),
                    subtitle: Text(
                      _maxCalories == null
                          ? AppLocalizations.of(context).recipeNoLimit
                          : '${discoveryNumber(context, _maxCalories)} ${AppLocalizations.of(context).foodKcal}',
                    ),
                    value: _maxCalories != null,
                    onChanged: _suggesting
                        ? null
                        : (v) => setState(() {
                            _maxCalories = v ? 600 : null;
                            _suggestedIds = null;
                          }),
                  ),
                  if (_maxCalories != null)
                    Slider(
                      value: _maxCalories!,
                      min: 100,
                      max: 1500,
                      divisions: 28,
                      label:
                          '${discoveryNumber(context, _maxCalories)} ${AppLocalizations.of(context).foodKcal}',
                      onChanged: _suggesting
                          ? null
                          : (v) => setState(() {
                              _maxCalories = v;
                              _suggestedIds = null;
                            }),
                    ),
                  Text(
                    AppLocalizations.of(context).recipeTimeLimit,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final m in <double?>[null, 15, 30, 60])
                        ChoiceChip(
                          selected: _maxMinutes == m,
                          label: Text(
                            m == null
                                ? AppLocalizations.of(context).recipeNoLimit
                                : '${discoveryNumber(context, m)} ${AppLocalizations.of(context).unitMinutesShort}',
                          ),
                          onSelected: _suggesting
                              ? null
                              : (_) => setState(() {
                                  _maxMinutes = m;
                                  _suggestedIds = null;
                                }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.aiPurple],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: _suggesting ? null : () => _suggestLocal(all),
                child: _suggesting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        AppLocalizations.of(context).discoveryMsg026,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).discoveryMsg027,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).discoveryMsg028,
                  icon: const Icon(Icons.info_outline, size: 18),
                  onPressed: () => discoveryExplain(
                    context,
                    AppLocalizations.of(context).discoveryMsg029,
                    '${AppLocalizations.of(context).recipeStrictConstraints}\n${AppLocalizations.of(context).discoveryMsg025}\n${AppLocalizations.of(context).discoveryMsg030}',
                  ),
                ),
              ],
            ),
            if (widget.suggestionService != null)
              TextButton.icon(
                onPressed: _suggesting ? null : () => _suggestAi(all),
                icon: const Icon(Icons.auto_awesome),
                label: Text(AppLocalizations.of(context).discoveryMsg031),
              ),
            if (_suggestedIds != null)
              TextButton(
                onPressed: () => setState(() => _suggestedIds = null),
                child: Text(AppLocalizations.of(context).discoveryMsg032),
              ),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: AppLocalizations.of(context).discoveryMsg033,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: AppLocalizations.of(context).discoveryMsg034,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            ),
            if (widget.favorites != null)
              FilterChip(
                label: Text(AppLocalizations.of(context).discoveryMsg035),
                selected: _savedOnly,
                shape: const StadiumBorder(),
                onSelected: (value) => setState(() => _savedOnly = value),
              ),

            if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(AppLocalizations.of(context).discoveryMsg037),
              ),
            for (final (index, recipe) in records.indexed)
              DiscoveryEntrance(
                index: index,
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () async {
                    await context.push(
                      '${RecipeDetailScreen.routeBase}/${Uri.encodeComponent(recipe.id)}',
                    );
                    if (mounted) setState(() {});
                  },
                  child: Row(
                    children: [
                      RecipeSourceImage(recipe: recipe),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              discoveryArabic(context)
                                  ? recipe.nameAr ?? recipe.nameEn
                                  : recipe.nameEn,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context).discoveryMsg038,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.cyanLight,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _IngredientDialog extends StatefulWidget {
  const _IngredientDialog();
  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) => SufraAlertDialog(
    title: Text(AppLocalizations.of(context).discoveryMsg039),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 80,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).discoveryMsg040,
      ),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppLocalizations.of(context).discoveryMsg041),
      ),
      TextButton(
        onPressed: _submit,
        child: Text(AppLocalizations.of(context).discoveryMsg042),
      ),
    ],
  );
}
