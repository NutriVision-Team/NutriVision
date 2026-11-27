import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../meal_log/domain/catalog_meal_draft.dart';
import '../../meal_log/domain/food_portion.dart';
import '../domain/food_recognition_provider.dart';

/// Meal result, not an unrelated name-search list. Numeric values are always
/// deterministic catalog calculations on explicitly labelled estimated amounts.
class PhotoMealResultCard extends StatelessWidget {
  const PhotoMealResultCard({
    super.key,
    required this.result,
    required this.chosen,
    required this.skipped,
    required this.unconfirmed,
    required this.onChoose,
    required this.onConfirm,
    required this.onPortion,
    required this.onSkip,
    this.onSkipClarification,
    this.clarificationSkipped = false,
    this.onClarifyOil,
    this.addedOil,
  });
  final VoidCallback? onSkipClarification, onClarifyOil;
  final bool clarificationSkipped;
  final FoodPortion? addedOil;
  final FoodRecognitionResult result;
  final Map<int, FoodPortion> chosen;
  final Set<int> skipped, unconfirmed;
  final void Function(int) onChoose, onConfirm, onPortion, onSkip;
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String t(String a, String e) => ar ? a : e;
    String state(String? value) => switch (value) {
      'raw' => t('نيّ', 'Raw'),
      'cooked' => t('مطبوخ', 'Cooked'),
      'prepared' => t('مجهّز', 'Prepared'),
      'dried' => t('مجفف', 'Dried'),
      'fluid' => t('سائل', 'Liquid'),
      'canned' => t('معلّب', 'Canned'),
      _ => t('حالة التحضير غير معروفة', 'Preparation unknown'),
    };
    final total = chosen.isEmpty
        ? null
        : CatalogMealDraft([
            ...chosen.values,
            if (addedOil != null) addedOil!,
          ]).totals;
    final complete = chosen.length + skipped.length == result.items.length;
    String n(double? v) => v == null
        ? t('غير متاح', 'Unknown')
        : v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          t('اقتراح لطبقك', 'Suggested meal'),
          style: context.readableDisplayStyle(size: 23),
        ),
        Text(
          t(
            'الكمية من الصورة تقدير مش قياس. راجع الصنف وحالة التحضير والجرامات. الزيت والسكر والإضافات المخفية ممكن ما تظهرش.',
            'Image portions are estimates, not measurements. Review food, preparation state and grams. Hidden oil, sugar and additions may not be visible.',
          ),
          style: context.mutedStyle(size: 12),
        ),
        const SizedBox(height: 12),
        if (chosen.isNotEmpty)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t(
                    'تحب توضّح الكمية أو الزيت؟ اختياري',
                    'Clarify the amount or oil? Optional',
                  ),
                  style: context.readableDisplayStyle(size: 17),
                ),
                Text(
                  t(
                    'تقدر تعدّل الكمية تحت كل صنف أو تكمّل بالتقدير. الزيت مش بيتضاف للحساب من غير كمية معروفة.',
                    'Edit amounts below or continue with estimates. Oil is not added to the calculation without a known amount.',
                  ),
                  style: context.mutedStyle(size: 12),
                ),
                if (onClarifyOil != null)
                  TextButton(
                    onPressed: onClarifyOil,
                    child: Text(
                      t(
                        'وضّح زيت الزيتون بالجرام',
                        'Clarify olive oil in grams',
                      ),
                    ),
                  ),
                if (onSkipClarification != null && !clarificationSkipped)
                  OutlinedButton(
                    onPressed: onSkipClarification,
                    child: Text(
                      t(
                        'تخطّي التوضيح وكمل بالتقدير',
                        'Skip clarification and use estimates',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        for (var i = 0; i < result.items.length; i++)
          GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 15, child: Text('${i + 1}')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => onChoose(i),
                        child: Text(
                          chosen[i]?.food.localizedNames?[ar ? 'ar' : 'en'] ??
                              chosen[i]?.food.name ??
                              (ar ? result.items[i].nameAr : null) ??
                              result.items[i].name,
                          style: context.readableDisplayStyle(size: 17),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: t('استبعاد', 'Skip'),
                      onPressed: () => onSkip(i),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                if (skipped.contains(i))
                  Text(t('مستبعد من الحساب', 'Excluded from calculation'))
                else if (chosen[i] case final FoodPortion p) ...[
                  Text(
                    '${n(p.grams)} ${t('جم', 'g')} · ${state(p.food.foodState)}',
                    textDirection: TextDirection.ltr,
                  ),
                  Text(
                    '${n(p.amount('calories')?.roundToDouble())} ${t('سعرة', 'kcal')}',
                    style: context.readableDisplayStyle(size: 22),
                  ),
                  Text(
                    '${t('بروتين', 'Protein')} ${n(p.amount('protein'))} · ${t('كارب', 'Carbs')} ${n(p.amount('carbohydrates'))} · ${t('دهون', 'Fat')} ${n(p.amount('fat'))} ${t('جم', 'g')}',
                  ),

                  Text(
                    t(
                      'راجع وزن الجزء اللي هتاكله بس، من غير عضم أو قشر. تقدير الصورة مش وزن مقاس.',
                      'Review the edible portion only, without bones or peel. The image estimate is not a measured weight.',
                    ),
                  ),
                  if (unconfirmed.contains(i))
                    Text(
                      t(
                        'الصنف وحالة التحضير محتاجين تأكيدك',
                        'Confirm the food and preparation state',
                      ),
                      style: const TextStyle(color: Colors.amber),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => onChoose(i),
                        child: Text(t('غيّر الصنف', 'Change food')),
                      ),
                      TextButton(
                        onPressed: () => onPortion(i),
                        child: Text(t('عدّل الكمية', 'Edit amount')),
                      ),
                      if (unconfirmed.contains(i))
                        TextButton(
                          onPressed: () => onConfirm(i),
                          child: Text(
                            t(
                              'راجعت الصنف والتحضير والكمية',
                              'I reviewed food, preparation and portion',
                            ),
                          ),
                        ),
                    ],
                  ),
                ] else ...[
                  if (result.items[i].suggestedPortionGrams
                      case final double grams)
                    Text(
                      '${n(grams)} ${t('جم تقدير غير محسوب', 'g, uncalculated estimate')}',
                    ),
                  if (result.items[i].foodState case final String st
                      when st == 'raw' || st == 'cooked')
                    Text(
                      st == 'raw'
                          ? t(
                              'شكله نيّ. السعرات بتفرق جدًا بين النيّ والمطبوخ، اختار الحالة الصح في المطابقة.',
                              'This looks raw. Calories differ a lot between raw and cooked, so pick the right state when matching.',
                            )
                          : t('شكله مطبوخ.', 'This looks cooked.'),
                    ),
                  Text(
                    t(
                      'محتاجين نراجع الصنف وطريقة تحضيره قبل حساب السعرات',
                      'Review the food and how it was prepared before calculating calories',
                    ),
                  ),
                  TextButton(
                    onPressed: () => onChoose(i),
                    child: Text(t('اختار المطابقة', 'Choose match')),
                  ),
                ],
              ],
            ),
          ),
        if (addedOil != null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${t('زيت زيتون مضاف:', 'Added olive oil:')} ${n(addedOil!.grams)} ${t('جم', 'g')}',
                ),
                Text(
                  '${n(addedOil!.amount('calories'))} ${t('سعرة مضافة للإجمالي', 'kcal added to total')}',
                ),
                TextButton(
                  onPressed: onClarifyOil,
                  child: Text(t('عدّل أو احذف الزيت', 'Edit or remove oil')),
                ),
              ],
            ),
          ),
        if (total != null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  complete
                      ? t('الإجمالي تقديري', 'Estimated total')
                      : t(
                          'إجمالي جزئي للأصناف المطابقة فقط',
                          'Partial total of matched foods only',
                        ),
                  style: context.readableDisplayStyle(size: 18),
                ),
                Text(
                  '${t('حوالي', 'About')} ${n(total.energyKcal.roundToDouble())} ${t('سعرة', 'kcal')}',
                  style: context.readableDisplayStyle(size: 30),
                ),
                Text(
                  '${t('بروتين', 'Protein')} ${n(total.proteinG)} · ${t('كارب', 'Carbs')} ${n(total.carbohydrateG)} · ${t('دهون', 'Fat')} ${n(total.fatG)} ${t('جم', 'g')}',
                ),
                Text(
                  t(
                    'مفيش نطاق دقة موثوق للصورة دي. الأرقام مش قياس معملي ومش تأكيد لكل المكونات.',
                    'No calibrated accuracy range is available for this image. Values are not laboratory measurements or confirmation of all ingredients.',
                  ),
                  style: context.mutedStyle(size: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
