import '../../../meal_log/domain/meal_review_input.dart';
import '../../../meal_log/domain/catalog_meal_draft.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/decimal_input.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../meal_log/presentation/screens/meal_review_screen.dart';
import '../../domain/off_product.dart';

/// Design screen 16. Shows only what the source returned; every absent value
/// is labelled "not provided" and never rendered as zero.
class ProductResultScreen extends StatefulWidget {
  const ProductResultScreen({
    super.key,
    required this.product,
    this.onSelectForShopping,
  });
  static const routePath = '/barcode/product';
  final OffProduct product;
  final VoidCallback? onSelectForShopping;

  @override
  State<ProductResultScreen> createState() => _ProductResultScreenState();
}

class _ProductResultScreenState extends State<ProductResultScreen> {
  late final TextEditingController _grams = TextEditingController(
    text: widget.product.servingGrams == null
        ? '100'
        : _fmt(widget.product.servingGrams!),
  );
  bool _submitted = false;

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  static String _fmt(double v) {
    final s = v.toStringAsFixed(v >= 100 ? 0 : 1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  /// Display digits follow the design: Arabic-Indic in Arabic. Input fields
  /// and codes keep Western digits (LTR).
  String _show(double v) {
    final s = _fmt(v);
    if (Localizations.localeOf(context).languageCode != 'ar') return s;
    const d = '٠١٢٣٤٥٦٧٨٩';
    return s.split('').map((c) {
      final i = '0123456789'.indexOf(c);
      return i >= 0 ? d[i] : (c == '.' ? '٫' : c);
    }).join();
  }

  double? get _amount {
    final v = parseDecimalInput(_grams.text);
    return v != null && v > 0 && v <= 10000 ? v : null;
  }

  void _add() {
    final portion = widget.product.portion(_amount ?? -1);
    if (portion == null) {
      setState(() => _submitted = true);
      return;
    }
    context.push(
      MealReviewScreen.routePath,
      extra: MealReviewInput(
        draft: CatalogMealDraft([portion], imageUrl: widget.product.imageUrl),
        inputMethod: 'barcode',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = widget.product;
    final ml = p.basis == NutrientBasis.per100ml;
    final unit = ml ? ' ' : ' ';
    final canAdd = p.canLog;
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: l.productBack,
                    onPressed: () => context.pop(),
                    icon: const BackButtonIcon(),
                  ),
                  Expanded(
                    child: Text(
                      l.productTitle,
                      style: context.readableDisplayStyle(size: 22),
                    ),
                  ),
                ],
              ),
              _header(context, l, p),
              if (p.nutriScore != null) _nutri(context, l, p.nutriScore!),
              _nutrition(context, l, p, unit),
              if (p.ingredientsText != null) _ingredients(context, l, p),
              _allergens(context, l, p),
              if (widget.onSelectForShopping != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: FilledButton.icon(
                    key: const ValueKey('select-pack'),
                    onPressed: widget.onSelectForShopping,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'اختار العبوة دي للتسوق'
                          : 'Choose this pack for shopping',
                    ),
                  ),
                )
              else
                _log(context, l, p, canAdd),
              if (widget.onSelectForShopping == null)
                TextButton.icon(
                  onPressed: () => context.push('/alternatives'),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(l.discoveryMsg052),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  l.productAttribution,
                  key: const ValueKey('off-attribution'),
                  style: context.mutedStyle(size: 11.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Localises units and fixes bidi order so Arabic reads "400 جم", not "g e 400".
  static String _amountText(BuildContext context, String raw) {
    if (Localizations.localeOf(context).languageCode != 'ar') return raw;
    final text = raw.replaceAllMapped(
      RegExp(r'(\d+(?:[.,]\d+)?)\s*(kg|g|ml|l|cl)\b', caseSensitive: false),
      (m) {
        const units = {
          'kg': 'كجم',
          'g': 'جم',
          'ml': 'مل',
          'l': 'لتر',
          'cl': 'سل',
        };
        return '${m[1]} ${units[m[2]!.toLowerCase()]}';
      },
    );
    return '\u200F$text\u200F';
  }

  Widget _header(BuildContext context, AppLocalizations l, OffProduct p) {
    return GlassCard(
      borderColor: AppColors.orangeLight.withValues(alpha: .5),
      margin: const EdgeInsets.only(top: 8),
      child: Flex(
        direction: MediaQuery.textScalerOf(context).scale(13) > 18
            ? Axis.vertical
            : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 96,
              height: 96,
              child: p.imageUrl == null
                  ? Semantics(
                      label: l.productNoImage,
                      child: const Icon(Icons.inventory_2_outlined, size: 40),
                    )
                  : Image.network(
                      p.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.inventory_2_outlined, size: 40),
                    ),
            ),
          ),
          const SizedBox(width: 14, height: 14),
          _ProductHeaderText(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: context.readableDisplayStyle(size: 22)),
                if (p.brand != null)
                  Text(p.brand!, style: context.mutedStyle(size: 13)),
                if (p.quantityText != null)
                  Text(
                    l.productQuantity(_amountText(context, p.quantityText!)),
                    style: context.mutedStyle(size: 12),
                  ),
                if (p.servingText != null)
                  Text(
                    l.productServing(_amountText(context, p.servingText!)),
                    style: context.mutedStyle(size: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutri(BuildContext context, AppLocalizations l, String grade) {
    const letters = ['a', 'b', 'c', 'd', 'e'];
    const colors = [
      Color(0xFF22C55E),
      Color(0xFF84CC16),
      Color(0xFFFACC15),
      Color(0xFFFB8C00),
      Color(0xFFEF4444),
    ];
    return GlassCard(
      borderColor: AppColors.orangeLight.withValues(alpha: .5),
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                l.productNutriScore,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                l.productNutriScoreFromSource,
                style: context.mutedStyle(size: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                for (var i = 0; i < 5; i++)
                  Expanded(
                    child: Opacity(
                      opacity: letters[i] == grade ? 1 : .45,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: letters[i] == grade ? 54 : 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors[i],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          letters[i].toUpperCase(),
                          style: TextStyle(
                            color: AppColors.darkBackground,
                            fontWeight: FontWeight.w800,
                            fontSize: letters[i] == grade ? 22 : 16,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutrition(
    BuildContext context,
    AppLocalizations l,
    OffProduct p,
    String _,
  ) {
    final ml = p.basis == NutrientBasis.per100ml;
    final rows = <(String, double?, String)>[
      (l.productCalories, p.energyKcal, l.productKcalUnit),
      (l.productProtein, p.proteinG, l.productGramUnit),
      (l.productCarbs, p.carbohydrateG, l.productGramUnit),
      (l.productFat, p.fatG, l.productGramUnit),
      (l.productFiber, p.fiberG, l.productGramUnit),
      (l.productSugars, p.sugarsG, l.productGramUnit),
      (l.productSodium, p.sodiumMg, l.productMgUnit),
    ];
    return GlassCard(
      borderColor: AppColors.orangeLight.withValues(alpha: .5),
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.basis == NutrientBasis.unknown
                ? l.productNutritionBasisUnknown
                : ml
                ? l.productNutritionPer100ml
                : l.productNutritionPer100g,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(r.$1),
                  if (r.$2 == null)
                    Text(l.productNotProvided, style: context.mutedStyle())
                  else
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${_show(r.$2!)} ${r.$3}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _ingredients(
    BuildContext context,
    AppLocalizations l,
    OffProduct p,
  ) => GlassCard(
    margin: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.productIngredients,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(p.ingredientsText!, style: context.mutedStyle(size: 13)),
        const SizedBox(height: 8),
        Text(
          Localizations.localeOf(context).languageCode == 'ar'
              ? 'راجع المكونات على العبوة، خصوصًا لو عندك حساسية. القائمة هنا ممكن تكون ناقصة.'
              : 'Check ingredients on the pack, especially if you have an allergy. This list may be incomplete.',
          style: context.mutedStyle(size: 12),
        ),
      ],
    ),
  );

  Widget _allergens(BuildContext context, AppLocalizations l, OffProduct p) {
    final tags = p.allergenTags;
    String label(String t) {
      final i = t.indexOf(':');
      final v = i >= 0 ? t.substring(i + 1) : t;
      return v.replaceAll('-', ' ');
    }

    return GlassCard(
      borderColor: AppColors.orangeLight.withValues(alpha: .5),
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.productAllergens,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (tags == null)
            Text(l.productAllergensUnknown, style: context.mutedStyle(size: 13))
          else if (tags.isEmpty)
            Text(l.productAllergensNone, style: context.mutedStyle(size: 13))
          else
            Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final t in tags)
                    Chip(
                      label: Text(label(t)),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(l.productAllergensCaveat, style: context.mutedStyle(size: 12)),
        ],
      ),
    );
  }

  Widget _log(
    BuildContext context,
    AppLocalizations l,
    OffProduct p,
    bool canAdd,
  ) {
    final ml = p.basis == NutrientBasis.per100ml;
    final blockedReason = p.basis == NutrientBasis.unknown
        ? l.productCannotLogUnknownBasis
        : ml
        ? l.productCannotLogMl
        : (p.energyKcal == null ? l.productCannotLogNoEnergy : null);
    final invalid = _submitted && _amount == null;
    return GlassCard(
      borderColor: AppColors.orangeLight.withValues(alpha: .5),
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (blockedReason != null)
            Text(
              blockedReason,
              key: const ValueKey('log-blocked'),
              style: context.mutedStyle(size: 13),
            )
          else ...[
            Text(
              l.productPortionLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _grams,
                key: const ValueKey('grams-field'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() => _submitted = false),
                decoration: InputDecoration(
                  suffixText: l.productGramUnit,
                  errorText: invalid ? l.productGramsInvalid : null,
                ),
              ),
            ),
            if (p.servingGrams != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ActionChip(
                  label: Text(l.productUseServing(_fmt(p.servingGrams!))),
                  onPressed: () =>
                      setState(() => _grams.text = _fmt(p.servingGrams!)),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: MediaQuery.textScalerOf(context).scale(17) > 24
                  ? 112
                  : 52,
              child: GradientButton(
                height: MediaQuery.textScalerOf(context).scale(17) > 24
                    ? 112
                    : 52,
                key: const ValueKey('add-to-diary'),
                label: l.productAddToDiary,
                onPressed: canAdd ? _add : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductHeaderText extends StatelessWidget {
  const _ProductHeaderText({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(13) > 18
      ? child
      : Expanded(child: child);
}
