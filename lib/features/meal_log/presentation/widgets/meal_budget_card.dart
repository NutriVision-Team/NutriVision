import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/meal_budget_preview.dart';

/// Compares the whole reviewed draft with the recorded daily budget. It does
/// not judge medical suitability. No automatic replacement or save occurs.
class MealBudgetCard extends StatefulWidget {
  const MealBudgetCard({
    super.key,
    required this.preview,
    this.warn,
    this.onAlternatives,
  });
  final MealBudgetPreview preview;
  final Future<void> Function()? warn;
  final VoidCallback? onAlternatives;
  @override
  State<MealBudgetCard> createState() => _MealBudgetCardState();
}

class _MealBudgetCardState extends State<MealBudgetCard> {
  bool _warned = false;
  void _check() {
    if (widget.preview.after >= 0) {
      _warned = false;
      return;
    }
    if (_warned) return;
    _warned = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.preview.after < 0) {
        (widget.warn ?? HapticFeedback.heavyImpact)();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(covariant MealBudgetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _check();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final p = widget.preview;
    final over = p.after < 0;
    return GlassCard(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ar ? 'وجبتك ضمن يومك' : 'This meal in your day',
            style: context.readableDisplayStyle(size: 18),
          ),
          const SizedBox(height: 8),
          Text(ar ? 'المتبقي قبل الوجبة:' : 'Remaining before this meal:'),
          Text(
            '${p.before.toStringAsFixed(0)} ${ar ? 'سعرة' : 'kcal'}',
            textDirection: TextDirection.ltr,
            style: context.readableDisplayStyle(size: 20),
          ),
          Text(
            ar
                ? (over
                      ? 'الوجبة هتعدّي هدفك اليومي بـ:'
                      : 'المتبقي بعد الحفظ:')
                : (over
                      ? 'This meal would exceed your daily target by:'
                      : 'Remaining after saving:'),
          ),
          Text(
            '${p.after.abs().toStringAsFixed(0)} ${ar ? 'سعرة' : 'kcal'}',
            textDirection: TextDirection.ltr,
            style: context.readableDisplayStyle(size: 20),
          ),
          if (over) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ar
                        ? 'راجع الكميات أو استكشف بدائل قبل الحفظ. تقدر تكمّل باختيارك.'
                        : 'Review amounts or explore alternatives before saving. You can still choose to continue.',
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed:
                  widget.onAlternatives ?? () => context.push('/alternatives'),
              icon: const Icon(Icons.swap_horiz),
              label: Text(ar ? 'استكشف بدائل' : 'Explore alternatives'),
            ),
            Text(
              ar
                  ? 'الاختيار يرجعك للمراجعة من غير حفظ تلقائي. المقارنة مش حكم على الشبع أو احتياجاتك الطبية.'
                  : 'A choice returns to review without saving automatically. The comparison does not assess fullness or medical needs.',
              style: context.mutedStyle(size: 12),
            ),
          ],
          Text(
            ar
                ? 'حسب هدفك وسجلاتك الحالية، مش اقتراح تاكل أو تقلل أكلك. ده مش تأكيد إن الوجبة مناسبة لحالة صحية أو حساسية.'
                : 'Based on your target and current records, not advice to eat more or less. This does not confirm suitability for a health condition or allergy.',
            style: context.mutedStyle(size: 12),
          ),
        ],
      ),
    );
  }
}
