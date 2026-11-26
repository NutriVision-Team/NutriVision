import '../../../alternatives/domain/alternatives_repository.dart';
import '../../../alternatives/domain/food_preference_filter.dart';
import '../../../camera_analysis/domain/photo_meal_resolver.dart';
import '../../../camera_analysis/domain/food_recognition_provider.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/catalog_food_art.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/catalog_meal_draft.dart';
import '../../domain/food_portion.dart';

/// Explicit portion alternatives preserve food identity and preparation state.
/// They are optional previews, not a meal prescription or automatic save.
class MealPortionAlternatives extends StatelessWidget {
  const MealPortionAlternatives({
    super.key,
    required this.draft,
    required this.remaining,
    this.allergies = const [],
    this.dietaryPreferences = const [],
  });
  final CatalogMealDraft draft;
  final double remaining;
  final List<String> allergies, dietaryPreferences;
  Future<List<CatalogMealDraft>> _swaps() async {
    final all = await AlternativesRepository().getAll();
    final results = <CatalogMealDraft>[];
    final original = draft.totals?.energyKcal;
    if (original == null || !remaining.isFinite || remaining <= 0) {
      return results;
    }
    for (var index = 0; index < draft.portions.length; index++) {
      final old = draft.portions[index];
      for (final entry in all.where((r) => r.original.id == old.food.foodId)) {
        final f = entry.alternative;
        if (!FoodPreferenceFilter.allows(
          f,
          allergies: allergies,
          dietaryPreferences: dietaryPreferences,
        )) {
          continue;
        }
        if (draft.portions.any((p) => p.food.foodId == f.id)) continue;
        final resolved = const PhotoMealResolver().resolve(
          FoodRecognitionResult(
            items: [
              RecognitionCandidate(
                name: f.nameEn,
                matchedFoodId: f.id,
                foodState: f.foodState,
                suggestedPortionGrams: old.grams,
              ),
            ],
          ),
          [f],
        );
        if (resolved.isEmpty) continue;
        final portions = [...draft.portions];
        portions[index] = resolved.values.single;
        final next = CatalogMealDraft(portions);
        final total = next.totals?.energyKcal;
        if (total != null && total < original && total <= remaining) {
          results.add(next);
        }
      }
    }
    results.sort(
      (a, b) => b.totals!.energyKcal.compareTo(a.totals!.energyKcal),
    );
    return results.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final kcal = draft.totals?.energyKcal;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ar ? 'بدائل الأكل والكميات' : 'Food and portion options',
                      style: context.readableDisplayStyle(size: 24),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                ar
                    ? 'نفس المكونات ونفس حالة التحضير، بكميات أقل وحساب جديد من بيانات المصدر. اختار لو ده يناسبك، مش مطلوب تقلل أكلك عشان الرقم. مش بنقيّم الاحتياجات الطبية أو الشبع.'
                    : 'The same foods and preparation, with smaller amounts recalculated from source data. Choose only if it works for you. The number is not a reason you must eat less. This does not assess medical needs or fullness.',
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<CatalogMealDraft>>(
                future: _swaps(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator();
                  }
                  final options = snapshot.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        ar
                            ? 'بدائل أكل جوه المتبقي'
                            : 'Food swaps within your remainder',
                        style: context.readableDisplayStyle(size: 21),
                      ),
                      Text(
                        ar
                            ? 'تبديل صنف بنفس الوزن، وباقي الطبق زي ما هو. راجع المكونات والحساسية بنفسك، دي مش شهادة أمان للحساسية.'
                            : 'One food at the same weight; the rest of the meal stays unchanged. Review ingredients and allergies yourself. This is not allergen certification.',
                      ),
                      if (options.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            ar
                                ? 'مفيش بديل من بياناتنا يحقق المتبقي مع المكونات دي. مش هنقترح اختيار بحساب ناقص.'
                                : 'No catalog swap fits the recorded remainder for this meal. We will not suggest one with incomplete totals.',
                          ),
                        ),
                      for (final next in options)
                        GlassCard(
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final p in next.portions)
                                Text(
                                  '${p.food.localizedNames?[ar ? 'ar' : 'en'] ?? p.food.name} · \u2066${p.grams.toStringAsFixed(0)} ${ar ? 'جم' : 'g'}\u2069',
                                ),
                              Text(
                                '\u2066${next.totals!.energyKcal.toStringAsFixed(0)} ${ar ? 'سعرة' : 'kcal'}\u2069',
                                style: context.readableDisplayStyle(size: 20),
                              ),
                              Text(
                                ar
                                    ? 'داخل المتبقي، فاضل \u2066${(remaining - next.totals!.energyKcal).toStringAsFixed(0)}\u2069 سعرة'
                                    : 'Within remainder, ${(remaining - next.totals!.energyKcal).toStringAsFixed(0)} kcal left',
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, next),
                                child: Text(
                                  ar
                                      ? 'استخدم البديل وراجع'
                                      : 'Use swap and review',
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (kcal != null)
                for (final scale in [.75, .5, .4])
                  Builder(
                    builder: (c) {
                      final next = CatalogMealDraft([
                        for (final p in draft.portions)
                          FoodPortion(p.food, p.grams * scale),
                      ]);
                      final total = next.totals?.energyKcal;
                      if (total == null) return const SizedBox.shrink();
                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              ar
                                  ? 'من الكميات الحالية: \u2066${(scale * 100).round()}%\u2069'
                                  : '${(scale * 100).round()}% of current amounts',
                              style: context.readableDisplayStyle(size: 20),
                            ),
                            for (final p in next.portions)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    CatalogFoodArt(id: p.food.foodId, size: 38),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        (p.food.localizedNames?[ar
                                                    ? 'ar'
                                                    : 'en']
                                                as String?) ??
                                            p.food.name,
                                      ),
                                    ),
                                    Text(
                                      '${p.grams.toStringAsFixed(0)} ${ar ? 'جم' : 'g'}',
                                      textDirection: TextDirection.ltr,
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              '${total.toStringAsFixed(0)} ${ar ? 'سعرة' : 'kcal'}',
                              style: context.readableDisplayStyle(size: 20),
                            ),
                            Text(
                              ar
                                  ? (remaining - total >= 0
                                        ? 'داخل المتبقي من هدفك، فاضل ${(remaining - total).toStringAsFixed(0)} سعرة'
                                        : 'لسه أعلى من المتبقي بـ ${(total - remaining).toStringAsFixed(0)} سعرة')
                                  : (remaining - total >= 0
                                        ? 'Within the recorded remainder, ${(remaining - total).toStringAsFixed(0)} kcal left'
                                        : 'Still ${(total - remaining).toStringAsFixed(0)} kcal above the recorded remainder'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, next),
                              child: Text(
                                ar
                                    ? 'استخدم الكميات دي وراجع'
                                    : 'Use these amounts and review',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              Text(
                ar
                    ? 'أي اختيار هيرجعك للمراجعة من غير حفظ. تقدر تعدّل كل مكوّن تاني. الزيت والإضافات محسوبين بس لو انت ضايفهم.'
                    : 'Any choice returns to review without saving. You can edit every component again. Oil and additions count only if included.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
