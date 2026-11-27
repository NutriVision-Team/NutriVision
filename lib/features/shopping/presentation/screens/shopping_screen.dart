import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import '../../../barcode/domain/off_product.dart';
import '../../../barcode/presentation/screens/barcode_account_scope.dart';
import '../../../barcode/presentation/screens/product_result_screen.dart';
import '../../../../core/widgets/catalog_photo.dart';
import '../../../food_catalog/data/datasources/local_food_data_source.dart';
import '../../../../core/widgets/water_glass_surface.dart';
import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:sufradepi/core/widgets/sufra_button_response.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/progress_widgets.dart';
import '../../../../data/models/meal_plan_model.dart';
import '../../../../data/models/shopping_list_model.dart';
import '../../../planning_shared/presentation/planning_widgets.dart';
import '../../domain/shopping_list_logic.dart';
import '../cubit/shopping_cubit.dart';

/// Screen 22 — Shopping list (قايمة التسوق).
class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key, required this.cubit, this.currentPlan});

  static const routePath = '/shopping';

  final ShoppingCubit cubit;

  /// The saved plan of the currently displayed week, when loaded, enabling
  /// "generate from weekly plan". Null shows the action as unavailable.
  final MealPlanModel? currentPlan;

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.cubit.state.status == ShoppingStatus.loading) {
      widget.cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: PlanningScaffold(
        currentNavIndex: -1,
        avoidNavigationOverlap: true,
        child: BlocBuilder<ShoppingCubit, ShoppingState>(
          builder: (context, state) {
            switch (state.status) {
              case ShoppingStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ShoppingStatus.error:
                return PlanningError(
                  onRetry: () => context.read<ShoppingCubit>().load(),
                );
              case ShoppingStatus.ready:
                return _ShoppingBody(state: state, plan: widget.currentPlan);
            }
          },
        ),
      ),
    );
  }
}

class _ShoppingBody extends StatelessWidget {
  const _ShoppingBody({required this.state, required this.plan});

  final ShoppingState state;
  final MealPlanModel? plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (purchased, total) = state.progress;
    final grouped = groupShoppingItems(state.items);
    return PlanningList(
      bottom: 0,
      children: [
        PlanningTitle(l10n.shoppingTitle),
        Row(
          children: [
            Expanded(
              child: SufraProgressBar(
                fraction: total == 0 ? 0 : purchased / total,
                height: 10,
                gradient: const LinearGradient(
                  colors: [AppColors.greenLight, AppColors.turquoise],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${planningNumber(context, purchased)} / ${planningNumber(context, total)}',
                style: TextStyle(color: context.planningMuted),
              ),
            ),
          ],
        ),
        if (grouped.isEmpty)
          GlassCard(
            child: Column(
              children: [
                Icon(
                  Icons.shopping_basket_outlined,
                  color: AppColors.cyanLight,
                  size: 34,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.shoppingEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.planningMuted),
                ),
              ],
            ),
          )
        else ...[
          _GroupGrid(state: state, grouped: grouped),
          GlassCard(
            borderColor: AppColors.orangeLight.withValues(alpha: .5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [for (final item in state.items) _CheckRow(item: item)],
            ),
          ),
        ],
        if (state.skippedCount > 0)
          Text(
            l10n.shoppingSkipped(state.skippedCount),
            style: const TextStyle(color: AppColors.orangeLight, fontSize: 12),
          ),
        TextButton.icon(
          onPressed: state.busy ? null : () => _chooseCatalogFood(context),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'اختار الصنف اللي محتاجه'
                : 'Choose the food you need',
          ),
        ),
        TextButton.icon(
          onPressed: state.busy ? null : () => _chooseProduct(context),
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'اختار عبوة بالباركود'
                : 'Choose a pack by barcode',
          ),
        ),
        _ManualAdd(),
        if (plan != null)
          _ActionButton(
            label: state.generatedFromPlan
                ? l10n.shoppingRegenerate
                : l10n.shoppingGenerateFromPlan,
            busy: state.busy,
            onTap: () => context.read<ShoppingCubit>().generateFromPlan(plan!),
          )
        else
          Text(
            l10n.shoppingNoPlan,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.planningMuted, fontSize: 12),
          ),
      ],
    );
  }

  static String _groupLabel(BuildContext context, ShoppingGroup group) {
    final l10n = context.l10n;
    switch (group) {
      case ShoppingGroup.produce:
        return l10n.shoppingGroupProduce;
      case ShoppingGroup.protein:
        return l10n.shoppingGroupProtein;
      case ShoppingGroup.dairy:
        return l10n.shoppingGroupDairy;
      case ShoppingGroup.grains:
        return l10n.shoppingGroupGrains;
      case ShoppingGroup.other:
        return l10n.shoppingGroupOther;
    }
  }
}

class _GroupGrid extends StatelessWidget {
  const _GroupGrid({required this.state, required this.grouped});

  final ShoppingState state;
  final Map<ShoppingGroup, List<ShoppingListItemModel>> grouped;

  static const _colors = {
    ShoppingGroup.produce: AppColors.greenLight,
    ShoppingGroup.protein: AppColors.pinkLight,
    ShoppingGroup.dairy: AppColors.cyanLight,
    ShoppingGroup.grains: AppColors.orangeLight,
    ShoppingGroup.other: AppColors.purpleLight,
  };

  @override
  Widget build(BuildContext context) {
    final entries = grouped.entries.toList();
    if (MediaQuery.textScalerOf(context).scale(11) > 15) {
      return Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _GroupCard(
              group: entries[i].key,
              items: entries[i].value,
              color: _colors[entries[i].key] ?? AppColors.cyanLight,
            ),
          ],
        ],
      );
    }
    return GridView(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: MediaQuery.textScalerOf(context).scale(16) > 22
            ? 185
            : 154,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < entries.length; i++)
          PlanningEntrance(
            index: i,
            child: _GroupCard(
              group: entries[i].key,
              items: entries[i].value,
              color: _colors[entries[i].key] ?? AppColors.cyanLight,
            ),
          ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.items,
    required this.color,
  });

  final ShoppingGroup group;
  final List<ShoppingListItemModel> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final purchased = items.where((item) => item.isPurchased).length;
    final icon = planningIconFor(_spriteCategory(group));
    final large = MediaQuery.textScalerOf(context).scale(11) > 15;
    final narrow = MediaQuery.sizeOf(context).width < 360;
    return WaterGlassSurface(
      tint: color,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.5), const Color(0x0AFFFFFF)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.orangeLight.withValues(alpha: .5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ShoppingBody._groupLabel(context, group),
                        maxLines: large ? null : 2,
                        overflow: large
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: narrow ? 14 : 16,
                        ),
                      ),
                      Text(
                        l10n.shoppingItemCount(items.length),
                        style: TextStyle(
                          color: context.planningMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PlanningMealIcon(icon: icon, size: narrow ? 28 : 38),
              ],
            ),
            if (large) const SizedBox(height: 18) else const Spacer(),
            Text(
              items
                  .map((item) => _localizedShoppingName(context, item))
                  .join(' · '),
              maxLines: large ? null : 1,
              overflow: large ? null : TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: context.planningMuted),
            ),
            const SizedBox(height: 8),
            SufraProgressBar(
              fraction: items.isEmpty ? 0 : purchased / items.length,
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.55)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _spriteCategory(ShoppingGroup group) {
    switch (group) {
      case ShoppingGroup.produce:
        return 'vegetables';
      case ShoppingGroup.protein:
        return 'poultry';
      case ShoppingGroup.dairy:
        return 'dairy';
      case ShoppingGroup.grains:
        return 'grains';
      case ShoppingGroup.other:
        return '';
    }
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.item});

  final ShoppingListItemModel item;

  @override
  Widget build(BuildContext context) {
    final purchased = item.isPurchased;
    return Semantics(
      checked: purchased,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.read<ShoppingCubit>().toggle(item.itemId);
        },
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: purchased
                ? AppColors.greenLight.withValues(alpha: .12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(
            vertical: purchased ? 14 : 10,
            horizontal: purchased ? 8 : 0,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 250),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: purchased ? AppColors.greenLight : Colors.transparent,
                  border: Border.all(
                    color: purchased
                        ? AppColors.greenLight
                        : context.planningMuted.withValues(alpha: 0.8),
                    width: 2,
                  ),
                  boxShadow: purchased
                      ? [
                          BoxShadow(
                            color: AppColors.greenLight.withValues(alpha: 0.6),
                            blurRadius: 14,
                          ),
                        ]
                      : null,
                ),
                child: purchased
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.darkBackground,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              if (item.productBarcode != null) ...[
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 400),
                  child: SizedBox(
                    key: ValueKey(item.productBarcode),
                    width: 48,
                    height: 48,
                    child: item.productImageUrl == null
                        ? const Icon(Icons.image_not_supported_outlined)
                        : Image.network(
                            item.productImageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.image_not_supported_outlined),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (item.linkedFoodId != null) ...[
                if (CatalogPhoto.forFood(item.linkedFoodId!) != null)
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 500),
                    transitionBuilder: (child, a) => ScaleTransition(
                      scale: a,
                      child: FadeTransition(opacity: a, child: child),
                    ),
                    child: CatalogPhoto(
                      key: ValueKey(item.linkedFoodId),
                      name: CatalogPhoto.forFood(item.linkedFoodId!)!,
                      size: 48,
                    ),
                  )
                else
                  const Tooltip(
                    message: 'صورة غير متاحة / Image unavailable',
                    child: Icon(Icons.image_not_supported_outlined, size: 34),
                  ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: purchased ? TextDecoration.lineThrough : null,
                    color: purchased
                        ? context.planningMuted.withValues(alpha: 0.6)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_localizedShoppingName(context, item)),
                      if (item.productBrand != null)
                        Text(
                          item.productBrand!,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.planningMuted,
                          ),
                        ),
                      if (item.productBarcode != null)
                        Text(
                          item.productBarcode!,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 10,
                            color: context.planningMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Text(
                item.unit == 'g'
                    ? planningGrams(context, item.quantity)
                    : item.unit == 'pack'
                    ? '${planningNumber(context, item.quantity)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'عبوة' : 'pack'}'
                    : '${planningNumber(context, item.quantity)} ${item.unit}',
                style: TextStyle(color: context.planningMuted, fontSize: 12),
              ),
              IconButton(
                tooltip: Localizations.localeOf(context).languageCode == 'ar'
                    ? 'غيّر الصنف'
                    : 'Change food',
                onPressed: () => item.productBarcode != null
                    ? _chooseProduct(context, replaceItemId: item.itemId)
                    : _chooseCatalogFood(context, replaceItemId: item.itemId),
                icon: const Icon(Icons.swap_horiz, size: 18),
              ),
              IconButton(
                tooltip: context.l10n.mealDelete,
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    context.read<ShoppingCubit>().removeItem(item.itemId),
                icon: Icon(Icons.close, size: 18, color: context.planningMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualAdd extends StatefulWidget {
  @override
  State<_ManualAdd> createState() => _ManualAddState();
}

class _ManualAddState extends State<_ManualAdd> {
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final cubit = context.read<ShoppingCubit>();
    final quantity = double.tryParse(_quantity.text.trim()) ?? 0;
    setState(() => _busy = true);
    var added = false;
    try {
      await cubit.ensureList();
      added = await cubit.addManualItem(_name.text, quantity, 'g');
    } catch (_) {
      added = false;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (added) {
      _name.clear();
      _quantity.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SufraSnackBar(content: Text(context.l10n.shoppingAddInvalid)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final large = MediaQuery.textScalerOf(context).scale(11) > 15;

    Widget flexible(Widget child, int flex) =>
        large ? child : Expanded(flex: flex, child: child);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shoppingAddTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Flex(
            direction: large ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: large
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.center,
            children: [
              flexible(
                TextField(
                  controller: _name,
                  decoration: InputDecoration(hintText: l10n.shoppingAddName),
                ),
                3,
              ),
              const SizedBox(width: 8),
              flexible(
                TextField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: l10n.foodGramUnit),
                ),
                2,
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _busy ? null : _add,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SufraControlFeedback(
      radius: 18,
      overlay: true,
      child: GestureDetector(
        onTap: busy
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        child: Container(
          height: MediaQuery.textScalerOf(context).scale(11) > 15 ? null : 54,
          constraints: const BoxConstraints(minHeight: 54),
          padding: MediaQuery.textScalerOf(context).scale(11) > 15
              ? const EdgeInsets.all(12)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.turquoise.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }
}

Future<void> _chooseCatalogFood(
  BuildContext context, {
  String? replaceItemId,
}) async {
  final cubit = context.read<ShoppingCubit>();
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  List<LocalFoodRecord> foods;
  try {
    foods = await cubit.catalogChoices();
  } catch (_) {
    return;
  }
  if (!context.mounted || cubit.inactive) return;
  final remaining = await cubit.remainingToday();
  if (!context.mounted || cubit.inactive) return;
  var query = '';
  final selected = await showSufraDialog<LocalFoodRecord>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setDialog) {
        final filtered = foods
            .where(
              (f) =>
                  f.nameAr.contains(query) ||
                  f.nameEn.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        return SufraAlertDialog(
          title: Text(
            ar ? 'اختار الصنف نفسه' : 'Choose the exact food',
            style: context.readableDisplayStyle(size: 20),
          ),
          content: SizedBox(
            width: 420,
            height: 430,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: ar ? 'ابحث عن الصنف' : 'Search foods',
                  ),
                  onChanged: (v) => setDialog(() => query = v),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (c, i) {
                      final food = filtered[i];
                      final image = CatalogPhoto.forFood(food.id);
                      return ListTile(
                        leading: image == null
                            ? const Icon(Icons.image_not_supported_outlined)
                            : CatalogPhoto(name: image, size: 48),
                        title: Text(ar ? food.nameAr : food.nameEn),
                        subtitle: Text(
                          [
                            if (food.nutrientsPer100g.energyKcal != null)
                              '${food.nutrientsPer100g.energyKcal!.toStringAsFixed(0)} ${ar ? 'سعرة لكل 100 جم' : 'kcal per 100 g'}'
                            else
                              ar ? 'السعرات غير متاحة' : 'Energy unavailable',
                            ar
                                ? 'رسم توضيحي، مش قياس للحصة أو تأكيد ملاءمة'
                                : 'Illustration, not a portion or suitability assessment',
                          ].join(' · '),
                        ),
                        onTap: () => Navigator.pop(c, food),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(ar ? 'إلغاء' : 'Cancel'),
            ),
          ],
        );
      },
    ),
  );
  if (selected == null || !context.mounted || cubit.inactive) return;
  var amountText = '100';
  final grams = await showSufraDialog<double>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setAmount) {
        final amount = double.tryParse(amountText);
        final valid =
            amount != null && amount.isFinite && amount > 0 && amount <= 10000;
        final kcal = valid && selected.nutrientsPer100g.energyKcal != null
            ? selected.nutrientsPer100g.energyKcal! * amount / 100
            : null;
        return SufraAlertDialog(
          title: Text(
            ar ? 'كمية للمقارنة' : 'Amount to compare',
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 20,
              height: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ar
                    ? '${selected.nameAr}، بنفس حالة التحضير'
                    : '${selected.nameEn}, same preparation state',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: amountText,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: ar ? 'الكمية بالجرام' : 'Amount in grams',
                ),
                onChanged: (v) => setAmount(() {
                  amountText = v;
                }),
              ),
              if (kcal != null)
                Text('${kcal.toStringAsFixed(0)} ${ar ? 'سعرة' : 'kcal'}'),
              Text(
                remaining == null
                    ? (ar
                          ? 'المتبقي اليوم غير متاح. راجع هدفك وسجلك.'
                          : 'Today’s remainder is unavailable. Review your target and records.')
                    : (kcal == null
                          ? ''
                          : (ar
                                ? (remaining - kcal >= 0
                                      ? 'داخل المتبقي المسجل، فاضل ${(remaining - kcal).toStringAsFixed(0)} سعرة'
                                      : 'أعلى من المتبقي المسجل بـ ${(kcal - remaining).toStringAsFixed(0)} سعرة')
                                : (remaining - kcal >= 0
                                      ? 'Within recorded remainder, ${(remaining - kcal).toStringAsFixed(0)} kcal left'
                                      : '${(kcal - remaining).toStringAsFixed(0)} kcal above recorded remainder'))),
              ),
              Text(
                ar
                    ? 'مقارنة حسابية وقت فتح الاختيار، مش توصية بالأكل أو تقييم طبي. حفظ التسوق مش تسجيل وجبة.'
                    : 'An arithmetic snapshot when opened, not an eating recommendation or medical assessment. Saving shopping does not log a meal.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(ar ? 'إلغاء' : 'Cancel'),
            ),
            TextButton(
              onPressed: valid ? () => Navigator.pop(c, amount) : null,
              child: Text(ar ? 'احفظ كمية التسوق' : 'Save shopping amount'),
            ),
          ],
        );
      },
    ),
  );
  if (grams == null || !context.mounted || cubit.inactive) return;
  final saved = await cubit.selectCatalogFood(
    selected,
    grams: grams,
    replaceItemId: replaceItemId,
  );
  if (context.mounted && !saved) {
    ScaffoldMessenger.of(context).showSnackBar(
      SufraSnackBar(
        content: Text(ar ? 'الإضافة ما اتحفظتش' : 'Could not save food'),
      ),
    );
  }
}

Future<void> _chooseProduct(
  BuildContext context, {
  String? replaceItemId,
}) async {
  final cubit = context.read<ShoppingCubit>();
  if (cubit.inactive) return;
  final product = await Navigator.of(context).push<OffProduct>(
    MaterialPageRoute(
      builder: (scannerContext) => BarcodeAccountScope(
        userId: cubit.userId,
        activeUserId: () => cubit.inactive ? null : cubit.userId,
        onPhotoFallback: null,
        onSearchFallback: null,
        onOpenProduct: (product) async {
          final selected = await Navigator.of(scannerContext).push<bool>(
            MaterialPageRoute(
              builder: (productContext) => ProductResultScreen(
                product: product,
                onSelectForShopping: () =>
                    Navigator.of(productContext).pop(true),
              ),
            ),
          );
          if (selected == true && scannerContext.mounted && !cubit.inactive) {
            Navigator.of(scannerContext).pop(product);
          }
        },
      ),
    ),
  );
  if (product == null || !context.mounted || cubit.inactive) return;
  final saved = await cubit.selectProduct(
    product,
    replaceItemId: replaceItemId,
  );
  if (!context.mounted || cubit.inactive) return;
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  ScaffoldMessenger.of(context).showSnackBar(
    SufraSnackBar(
      content: Text(
        saved
            ? (ar
                  ? 'سفرة ضافت العبوة لقائمة التسوق'
                  : 'Sufra added the pack to your shopping list')
            : (ar
                  ? 'سفرة مقدرتش تحفظ العبوة، جرّب تاني'
                  : 'Sufra could not save the pack. Try again'),
      ),
    ),
  );
}

String _localizedShoppingName(
  BuildContext context,
  ShoppingListItemModel item,
) {
  if (item.linkedFoodId == null) return item.name;
  final records = context.read<ShoppingCubit>().foods.cachedRecords;
  for (final food in records) {
    if (food.id == item.linkedFoodId) {
      return Localizations.localeOf(context).languageCode == 'ar'
          ? food.nameAr
          : food.nameEn;
    }
  }
  return item.name;
}
