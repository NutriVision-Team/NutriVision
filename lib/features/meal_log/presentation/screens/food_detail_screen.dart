import '../../../../core/widgets/catalog_food_art.dart';
import '../../../../core/widgets/catalog_photo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/decimal_input.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../data/models/food_catalog_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/food_portion.dart';
import 'meal_review_screen.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({super.key, required this.food});
  static const routePath = '/food';
  final FoodCatalogModel food;
  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final _grams = TextEditingController(text: '100');
  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amount = parseDecimalInput(_grams.text);
    final valid =
        amount != null && amount.isFinite && amount > 0 && amount <= 10000;
    final portion = valid ? FoodPortion(widget.food, amount) : null;
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const BackButtonIcon(),
                  ),
                  Expanded(
                    child: Text(
                      (widget.food.localizedNames?[Localizations.localeOf(
                                context,
                              ).languageCode]
                              as String?) ??
                          widget.food.name,
                      style: context.readableDisplayStyle(size: 26),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(child: CatalogFoodArt(id: widget.food.foodId, size: 110)),
              CatalogImageCredit(foodId: widget.food.foodId),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _grams,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: l10n.foodGrams,
                        errorText: valid ? null : l10n.foodInvalidGrams,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final key in FoodPortion.nutrients)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Expanded(child: Text(nutrientLabel(l10n, key))),
                            Text(
                              portion?.amount(key)?.toStringAsFixed(1) ??
                                  l10n.foodUnknown,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              key == 'calories'
                                  ? l10n.foodKcal
                                  : key == 'sodium'
                                  ? l10n.foodMg
                                  : l10n.foodGramUnit,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.foodSource(widget.food.source ?? l10n.foodUnknown),
                style: context.mutedStyle(),
              ),
              if (portion != null && !portion.canSave) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.foodIncompleteWarning,
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
              const SizedBox(height: 24),
              GradientButton(
                label: l10n.mealReviewTitle,
                onPressed: portion?.canSave == true
                    ? () => context.push(
                        MealReviewScreen.routePath,
                        extra: portion,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String nutrientLabel(AppLocalizations l10n, String key) => switch (key) {
  'calories' => l10n.foodCalories,
  'protein' => l10n.foodProtein,
  'carbohydrates' => l10n.foodCarbs,
  'fat' => l10n.foodFat,
  'fiber' => l10n.foodFiber,
  'sugar' => l10n.foodSugar,
  'sodium' => l10n.foodSodium,
  _ => key,
};
