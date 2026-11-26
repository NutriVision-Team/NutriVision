import '../../../health_coach/domain/coach_reviewed_explanation.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../data/models/food_catalog_model.dart';
import '../../../../data/repositories/food_repository.dart';
import '../../../food_catalog/data/local_food_repository.dart';
import '../../../health_coach/domain/coach_catalog_tools.dart';
import '../../../meal_log/domain/catalog_meal_draft.dart';
import '../../../recipes/domain/recipe_catalog_repository.dart';

/// Honest local tool inside Coach. Never presented as an AI-generated answer.
class CoachFoodCalculatorPanel extends StatefulWidget {
  const CoachFoodCalculatorPanel({super.key, this.repository, this.onExplain});
  final Future<void> Function(CatalogMealDraft)? onExplain;
  final FoodRepository? repository;
  @override
  State<CoachFoodCalculatorPanel> createState() => _CalculatorState();
}

class _CalculatorState extends State<CoachFoodCalculatorPanel> {
  final query = TextEditingController(), grams = TextEditingController();
  final selected = <String, double>{};
  List<FoodCatalogModel> results = [];
  FoodCatalogModel? food;
  CatalogMealDraft? draft;
  bool busy = false, failed = false;
  int generation = 0;
  late final tools = CoachCatalogTools(
    foods: widget.repository ?? LocalFoodRepository(),
    recipes: RecipeCatalogRepository(),
  );
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String t(String a, String e) => ar ? a : e;
  @override
  void dispose() {
    generation++;
    query.dispose();
    grams.dispose();
    super.dispose();
  }

  String normalized(String raw) {
    var v = raw.replaceAll('٫', '.');
    const digits = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      v = v.replaceAll(digits[i], '$i');
    }
    return v;
  }

  Future<void> search() async {
    if (busy) return;
    final g = ++generation;
    setState(() {
      busy = true;
      failed = false;
      food = null;
      results = [];
    });
    try {
      final found = await tools.searchFoods(query.text);
      if (mounted && g == generation) setState(() => results = found);
    } catch (_) {
      if (mounted && g == generation) setState(() => failed = true);
    } finally {
      if (mounted && g == generation) setState(() => busy = false);
    }
  }

  Future<void> add() async {
    final amount = double.tryParse(normalized(grams.text));
    if (busy || food == null) return;
    if (amount == null || !amount.isFinite || amount <= 0 || amount > 10000) {
      setState(() => failed = true);
      return;
    }
    final next = {...selected, food!.foodId: amount};
    final g = ++generation;
    setState(() {
      busy = true;
      failed = false;
    });
    try {
      final calculated = await tools.calculate(next);
      if (mounted && g == generation) {
        setState(() {
          selected
            ..clear()
            ..addAll(next);
          draft = calculated;
        });
      }
    } catch (_) {
      if (mounted && g == generation) setState(() => failed = true);
    } finally {
      if (mounted && g == generation) setState(() => busy = false);
    }
  }

  Future<void> explain() async {
    final callback = widget.onExplain;
    if (busy || draft == null || callback == null) return;
    final snapshot = Map<String, double>.of(selected);
    final g = ++generation;
    setState(() {
      busy = true;
      failed = false;
    });
    late final CatalogMealDraft reviewed;
    late final String question;
    try {
      reviewed = await tools.calculate(snapshot);
      question = reviewedCalculationQuestion(reviewed, ar ? 'ar' : 'en');
    } catch (_) {
      if (mounted && g == generation) {
        setState(() {
          failed = true;
          busy = false;
        });
      }
      return;
    }
    if (!mounted || g != generation) return;
    setState(() => busy = false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('اشرح الحساب مع المدرّب؟', 'Explain this calculation?')),
        content: SingleChildScrollView(
          child: Text(
            '${t('هتتبعت الأصناف والأوزان ومصادرها للحساب والشرح فقط، من غير حفظ وجبة:', 'These foods, weights and sources will be sent for calculation and explanation only. No meal is saved:')}\n\n$question\n\n${reviewed.portions.map((p) => '${p.food.name} (${p.food.foodState}): \u2066${p.grams} g\u2069, ${p.food.source}').join('\n')}\n\u2066${reviewed.totals!.energyKcal.toStringAsFixed(1)} kcal\u2069',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('رجوع', 'Back')),
          ),
          FilledButton(
            key: const ValueKey('coach_confirm_explanation'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('إرسال للشرح', 'Send for explanation')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || widget.onExplain == null) return;
    setState(() {
      busy = true;
      failed = false;
    });
    try {
      if (!mounted || g != generation) return;
      await widget.onExplain!(reviewed);
    } catch (_) {
      if (mounted && g == generation) setState(() => failed = true);
    } finally {
      if (mounted && g == generation) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: GlassCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        minTileHeight: 64,
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        key: const ValueKey('coach_local_calculator'),
        title: Text(t('احسب وجبتك بالمقادير', 'Calculate a weighed meal')),
        leading: const Icon(Icons.calculate_outlined),
        childrenPadding: const EdgeInsets.all(14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(
              'حساب محلي من كتالوج الأكل، مش تقدير من المدرب. اختار الصنف وحالته، واكتب الوزن بالجرام. مفيش إرسال للمدرّب إلا لما تراجع وتوافق، ومفيش حفظ وجبة تلقائي.',
              'Local catalog calculation, not a Coach estimate. Choose the food and preparation state, then enter weighed grams. Nothing is sent to the Coach without your review and approval; no meal is saved automatically.',
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('coach_food_query'),
            controller: query,
            maxLength: 100,
            enabled: !busy,
            decoration: InputDecoration(labelText: t('اسم الصنف', 'Food name')),
          ),
          OutlinedButton(
            onPressed: busy ? null : search,
            child: Text(t('ابحث في الكتالوج', 'Search catalog')),
          ),
          for (final r in results)
            ListTile(
              selected: food?.foodId == r.foodId,
              leading: Icon(
                food?.foodId == r.foodId
                    ? Icons.check_circle
                    : Icons.circle_outlined,
              ),
              onTap: busy ? null : () => setState(() => food = r),
              title: Text(r.name),
              subtitle: Text(
                [
                  r.foodState ?? '',
                  r.source ?? '',
                ].where((s) => s.isNotEmpty).join(' · '),
              ),
            ),
          if (food != null) ...[
            TextField(
              key: const ValueKey('coach_food_grams'),
              controller: grams,
              enabled: !busy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: t('الوزن بالجرام', 'Weight in grams'),
              ),
            ),
            FilledButton(
              onPressed: busy ? null : add,
              child: Text(t('أضف للحساب', 'Add to calculation')),
            ),
          ],
          if (busy) const LinearProgressIndicator(),
          if (failed)
            Text(
              t(
                'راجع الوزن واختار صنف ببيانات غذائية ومصدر واضح.',
                'Check the weight and choose a food with source nutrition.',
              ),
            ),
          if (draft != null) ...[
            const Divider(),
            for (final p in draft!.portions)
              Text(
                '${p.food.name}: \u2066${p.grams.toStringAsFixed(0)} g\u2069',
                textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
              ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${draft!.totals!.energyKcal.toStringAsFixed(1)} kcal',
                key: const ValueKey('coach_calculated_energy'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              t('بروتين: ', 'Protein: ') +
                  (draft!.totals!.proteinG == null
                      ? t('غير معروف', 'unknown')
                      : '${draft!.totals!.proteinG!.toStringAsFixed(1)} g'),
            ),
            Text(
              t(
                'النتيجة للوزن المختار من بيانات المصدر، مش قياس معملي لوجبتك. القيمة الناقصة تفضل غير معروفة.',
                'Source-based result for the chosen weight, not a lab measurement of your meal. Missing nutrients stay unknown.',
              ),
            ),
            if (widget.onExplain != null)
              OutlinedButton(
                key: const ValueKey('coach_explain_calculation'),
                onPressed: busy ? null : explain,
                child: Text(
                  t('اشرح الحساب مع المدرّب', 'Explain with the Coach'),
                ),
              ),
            TextButton(
              onPressed: () => setState(() {
                selected.clear();
                draft = null;
              }),
              child: Text(t('امسح الحساب', 'Clear calculation')),
            ),
          ],
        ],
      ),
    ),
  );
}
