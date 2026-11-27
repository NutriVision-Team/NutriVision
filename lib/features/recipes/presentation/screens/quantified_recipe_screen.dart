import '../../../../core/widgets/nebula_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/food_catalog_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../meal_log/domain/food_portion.dart';
import '../../../meal_log/domain/meal_review_input.dart';
import '../../../meal_log/presentation/screens/food_search_screen.dart';
import '../../../meal_log/presentation/screens/meal_review_screen.dart';
import '../../data/datasources/local_recipe_data_source.dart';
import '../../domain/quantified_recipe_draft.dart';
import '../recipe_arabic.dart';
import '../widgets/discovery_widgets.dart';

class QuantifiedRecipeScreen extends StatefulWidget {
  const QuantifiedRecipeScreen({super.key, required this.recipe});
  final LocalRecipeRecord recipe;
  @override
  State<QuantifiedRecipeScreen> createState() => _QuantifiedRecipeScreenState();
}

class _QuantifiedRecipeScreenState extends State<QuantifiedRecipeScreen> {
  final _chosen = <int, FoodPortion>{};
  final _excluded = <int>{};
  double _yield = 1, _servings = 1;
  String _mealType = 'lunch';
  bool _yieldConfirmed = false;
  QuantifiedRecipeDraft get draft => QuantifiedRecipeDraft(
    sourceId: widget.recipe.id,
    ingredientCount: widget.recipe.ingredients.length,
    ingredients: _chosen,
    excluded: _excluded,
    yieldServings: _yield,
    servingsToLog: _servings,
  );
  Future<double?> number(
    String title,
    double initial, {
    double max = 10000,
  }) async {
    final l = AppLocalizations.of(context),
        c = TextEditingController(text: initial.toString());
    final route = DialogRoute<double>(
      context: context,
      builder: (ctx) => SufraAlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          textDirection: TextDirection.ltr,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () {
              final n = double.tryParse(c.text);
              if (n == null || !n.isFinite || n <= 0 || n > max) return;
              Navigator.pop(ctx, n);
            },
            child: Text(l.weightLogSave),
          ),
        ],
      ),
    );
    final n = await Navigator.of(context).push(route);
    await route.completed;
    c.dispose();
    return n;
  }

  Future<void> match(int i) async {
    final l = AppLocalizations.of(context);
    final food = await context.push<FoodCatalogModel>(
      FoodSearchScreen.pickRoutePath,
    );
    if (!mounted || food == null) return;
    final grams = await number(l.foodGrams, _chosen[i]?.grams ?? 100);
    if (!mounted || grams == null) return;
    setState(() {
      _chosen[i] = FoodPortion(food, grams);
      _excluded.remove(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        r = widget.recipe,
        d = draft,
        meal = draft.meal;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(14) > 20
            ? 104
            : 56,
        title: Text(
          l.recipeYourVersion,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: NebulaBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.recipeQuantifiedNotice),
            const SizedBox(height: 12),
            Text(
              discoveryArabic(context) ? (r.nameAr ?? r.nameEn) : r.nameEn,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            for (final (i, item) in r.ingredients.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GlassCard(
                  borderColor: _excluded.contains(i)
                      ? null
                      : (_chosen.containsKey(i)
                            ? AppColors.turquoise.withValues(alpha: .65)
                            : AppColors.orangeLight.withValues(alpha: .5)),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        title: Text(
                          discoveryArabic(context)
                              ? (RecipeArabic.ingredients[item.name] ??
                                    item.name)
                              : item.name,
                        ),
                        subtitle: Text(
                          '${discoveryArabic(context) ? RecipeArabic.measure(item.measure ?? '—') : item.measure ?? '—'}\n${_chosen[i] == null ? l.foodUnknown : '${(_chosen[i]!.food.localizedNames?[AppLocalizations.of(context).localeName.startsWith('ar') ? 'ar' : 'en'] as String? ?? _chosen[i]!.food.name)}: ${discoveryNumber(context, _chosen[i]!.grams)} ${l.foodGramUnit}'}',
                        ),
                        leading: Icon(
                          _chosen.containsKey(i)
                              ? Icons.check_circle_outline
                              : Icons.edit_outlined,
                        ),
                        onTap: () => match(i),
                      ),
                      CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        title: Text(l.recipeExcludeIngredient),
                        value: _excluded.contains(i),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _chosen.remove(i);
                            _excluded.add(i);
                          } else {
                            _excluded.remove(i);
                          }
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final n = await number(l.recipeYield, _yield, max: 1000);
                if (n != null && mounted) {
                  setState(() {
                    _yield = n;
                    _yieldConfirmed = true;
                    if (_servings > n) _servings = n;
                  });
                }
              },
              child: Text('${l.recipeYield}: $_yield'),
            ),
            TextButton(
              onPressed: () async {
                final n = await number(
                  l.recipeServingsToLog,
                  _servings,
                  max: _yield,
                );
                if (n != null && mounted) setState(() => _servings = n);
              },
              child: Text('${l.recipeServingsToLog}: $_servings'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _mealType,
              items: [
                for (final (v, t) in [
                  ('breakfast', l.discoveryBreakfast),
                  ('lunch', l.discoveryLunch),
                  ('dinner', l.discoveryDinner),
                ])
                  DropdownMenuItem(value: v, child: Text(t)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _mealType = v);
              },
            ),
            const SizedBox(height: 12),
            Text(
              meal?.totals == null
                  ? '—'
                  : '${discoveryNumber(context, meal!.totals!.energyKcal)} ${l.foodKcal}',
            ),
            if (meal?.totals != null)
              Text(
                '${l.macroProtein}: ${meal!.totals!.proteinG?.toStringAsFixed(1) ?? '—'} ${l.foodGramUnit} · ${l.macroCarbs}: ${meal.totals!.carbohydrateG?.toStringAsFixed(1) ?? '—'} ${l.foodGramUnit} · ${l.macroFat}: ${meal.totals!.fatG?.toStringAsFixed(1) ?? '—'} ${l.foodGramUnit}',
              ),
            if (!d.complete || !_yieldConfirmed)
              Text(l.recipeMatchEveryIngredient),
            FilledButton(
              onPressed: _yieldConfirmed && meal?.canSave == true
                  ? () => context.push(
                      MealReviewScreen.routePath,
                      extra: MealReviewInput(
                        draft: meal!,
                        mealType: _mealType,
                        title: discoveryArabic(context)
                            ? (r.nameAr ?? r.nameEn)
                            : r.nameEn,
                        notes:
                            '${l.recipeYourVersion}; ${l.recipeYield}: $_yield; ${l.recipeServingsToLog}: $_servings; ${l.recipeExcludedCount}: ${_excluded.length}',
                      ),
                    )
                  : null,
              child: Text(l.mealReviewTitle),
            ),
          ],
        ),
      ),
    );
  }
}
