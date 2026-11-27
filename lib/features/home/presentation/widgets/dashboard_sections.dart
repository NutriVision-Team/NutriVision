import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/progress_widgets.dart';
import '../../../../core/utils/date_utils.dart';
import '../cubit/home_cubit.dart';

bool _ar(BuildContext c) => Localizations.localeOf(c).languageCode == 'ar';
String _n(num v) => v.round().toString();

class DailyNutritionCard extends StatelessWidget {
  const DailyNutritionCard({super.key, required this.data});
  final HomeLoaded data;
  @override
  Widget build(BuildContext context) {
    final ar = _ar(context), plan = data.nutritionProfile;
    final target = plan?.dailyCalorieTarget;
    final eaten = data.eatenCalories;
    final remaining = target == null
        ? null
        : (target - eaten).clamp(0, double.infinity);
    final excess = target == null
        ? 0
        : (eaten - target).clamp(0, double.infinity);
    final ring = CalorieRing(
      fraction: target != null && target > 0 ? eaten / target : 0,
      size: 150,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              remaining == null ? '—' : _n(remaining),
              textDirection: TextDirection.ltr,
              style: context.readableDisplayStyle(size: 32),
            ),
            Text(
              ar ? 'سعرات متبقية' : 'kcal remaining',
              style: context.mutedStyle(size: 12),
            ),
          ],
        ),
      ),
    );
    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'غذاؤك النهارده' : 'Today’s nutrition',
          style: context.readableDisplayStyle(size: 22),
        ),
        const SizedBox(height: 12),
        Text(ar ? 'المسجّل' : 'Logged', style: context.mutedStyle(size: 12)),
        Text(
          '${_n(eaten)} kcal',
          textDirection: TextDirection.ltr,
          style: context.readableDisplayStyle(size: 26),
        ),
        Text(
          target == null
              ? (ar ? 'مفيش خطة نشطة' : 'No active plan')
              : (ar
                    ? 'هدف الخطة: ${_n(target)} سعر'
                    : 'Plan target: ${_n(target)} kcal'),
          style: context.mutedStyle(size: 12),
        ),
        if (excess > 0)
          Text(
            ar
                ? '${_n(excess)} سعر فوق الهدف المسجّل'
                : '${_n(excess)} kcal above the recorded target',
            style: context.mutedStyle(size: 12),
          ),
        const SizedBox(height: 8),
        Text(
          ar
              ? 'مقارنة رقمية بالخطة، مش تقييم صحي'
              : 'A plan comparison, not a health score',
          style: context.mutedStyle(size: 11),
        ),
      ],
    );
    return GlassCard(
      onTap: () => context.push('/report'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow =
              constraints.maxWidth < 310 ||
              MediaQuery.textScalerOf(context).scale(12) > 18;
          return narrow
              ? Column(children: [ring, const SizedBox(height: 18), detail])
              : Row(
                  children: [
                    ring,
                    const SizedBox(width: 18),
                    Expanded(child: detail),
                  ],
                );
        },
      ),
    );
  }
}

class DailyActivityCard extends StatelessWidget {
  const DailyActivityCard({super.key, required this.data});
  final HomeLoaded data;
  @override
  Widget build(BuildContext context) {
    final ar = _ar(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ar ? 'ملخص يومك' : 'Your day at a glance',
            style: context.readableDisplayStyle(size: 20),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 14,
            children: [
              _Metric(
                icon: Icons.restaurant_outlined,
                value: '${data.todaysMeals.length}',
                label: ar ? 'وجبات مؤكدة' : 'confirmed meals',
              ),
              _Metric(
                icon: Icons.water_drop_outlined,
                value: '${_n(data.dailyLog?.waterIntakeMl ?? 0)} ml',
                label: ar ? 'مياه مسجلة' : 'water logged',
              ),
              _Metric(
                icon: Icons.local_fire_department_outlined,
                value: '${data.streakDays}',
                label: ar ? 'أيام تسجيل متتالية' : 'consecutive logging days',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            ar
                ? 'تسجيل النشاط البدني لسه مش متاح. مش بنحسب نسبة التزام من بيانات ناقصة.'
                : 'Physical activity logging is not available yet. Incomplete records are not an adherence score.',
            style: context.explainStyle(
              size: 11.5,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 80, maxWidth: 220),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.turquoise, size: 22),
        const SizedBox(height: 5),
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: context.readableDisplayStyle(size: 23),
        ),
        Text(label, style: context.mutedStyle(size: 12)),
      ],
    ),
  );
}

class ConsistencyCard extends StatelessWidget {
  const ConsistencyCard({super.key, required this.data, required this.now});
  final HomeLoaded data;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final ar = _ar(context), today = DateTime(now.year, now.month, now.day);
    final logs = {for (final l in data.recentLogs) l.dateKey: l};
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    return GlassCard(
      onTap: () => context.push('/diary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ar ? 'أسبوعك في السجل' : 'Your week in the diary',
            style: context.readableDisplayStyle(size: 20),
          ),
          const SizedBox(height: 5),
          Text(
            ar
                ? 'الأقدم شمال، والأحدث يمين. النقطة معناها وجبة مسجلة، مش تقييم ليومك.'
                : 'Oldest left, latest right. A dot means a logged meal, not a score for your day.',
            style: context.mutedStyle(size: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            textDirection: TextDirection.ltr,
            spacing: 9,
            runSpacing: 10,
            children: [
              for (final day in days)
                Builder(
                  builder: (context) {
                    final log = logs[SufraDateUtils.toDateKey(day)];
                    final recorded = (log?.mealCount ?? 0) > 0;
                    return Semantics(
                      label:
                          '${SufraDateUtils.toDateKey(day)} ${recorded ? (ar ? 'فيه تسجيل' : 'recorded') : (ar ? 'بدون تسجيل' : 'no record')}',
                      child: Container(
                        width: 34,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: recorded
                              ? AppColors.primaryBlue.withValues(alpha: .2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppColors.turquoise.withValues(alpha: .25),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${day.day}',
                              textDirection: TextDirection.ltr,
                            ),
                            const SizedBox(height: 5),
                            Icon(
                              recorded ? Icons.circle : Icons.circle_outlined,
                              size: 8,
                              color: AppColors.turquoise,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class DailyInsightCard extends StatelessWidget {
  const DailyInsightCard({super.key, required this.data});
  final HomeLoaded data;
  @override
  Widget build(BuildContext context) {
    final ar = _ar(context),
        protein = data.eatenProtein,
        target = data.nutritionProfile?.proteinTarget;
    final message = data.todaysMeals.isEmpty
        ? (ar
              ? 'ابدأ بوجبة واحدة. تسجيلك هو اللي بيخلّي الملخص مفيد ليك.'
              : 'Start with one meal. Your records make this summary useful.')
        : protein == null
        ? (ar
              ? 'بيانات البروتين ناقصة في سجلك. راجع الأصناف والكميات قبل المقارنة بالخطة.'
              : 'Protein data is incomplete. Review foods and portions before comparing with your plan.')
        : target != null && protein < target
        ? (ar
              ? 'البروتين المسجّل ${_n(protein)} جم من هدف ${_n(target)} جم. ده فرق عن الخطة، مش تشخيص نقص.'
              : 'Logged protein is ${_n(protein)} g against a ${_n(target)} g target. This is a plan gap, not a deficiency diagnosis.')
        : (ar
              ? 'راجع سجل يومك وأضف اللي لسه متسجّلش. الأرقام بتوصف المسجّل بس.'
              : 'Review your diary and add anything missing. These numbers describe only what is logged.');
    return GlassCard(
      onTap: () => context.push('/coach'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _InsightIcon(),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  ar ? 'ملاحظة من سجلك' : 'An insight from your diary',
                  style: context.readableDisplayStyle(size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(message, style: context.messageStyle(size: 13.5)),
          const SizedBox(height: 8),
          Text(
            ar
                ? 'ملاحظة من الأرقام المسجّلة، مش تشخيص طبي. افتح المدرّب للمزيد.'
                : 'Based on your logged numbers, not a medical diagnosis. Open the coach for more.',
            style: context.mutedStyle(size: 12),
          ),
        ],
      ),
    );
  }
}

/// Insight icon with a single soft gold sweep on first show (skipped when the
/// system asks for reduced motion).
class _InsightIcon extends StatelessWidget {
  const _InsightIcon();
  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.insights_outlined, color: AppColors.cyanLight);
    if (MediaQuery.disableAnimationsOf(context)) return icon;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -0.5, end: 1.5),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeInOut,
      child: icon,
      builder: (context, t, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment(-1 + 2 * t - 0.6, 0),
          end: Alignment(-1 + 2 * t + 0.6, 0),
          colors: const [
            Color(0x00FFD27A),
            Color(0xFFFFD27A),
            Color(0x00FFD27A),
          ],
        ).createShader(rect),
        child: child,
      ),
    );
  }
}
