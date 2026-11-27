import '../../../../core/widgets/catalog_photo.dart';
import '../../../../core/widgets/catalog_food_art.dart';
import 'package:flutter/material.dart';
import 'package:sufradepi/core/widgets/sufra_button_response.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/progress_widgets.dart';
import '../../../../data/models/meal_plan_model.dart';
import '../../../planning_shared/presentation/planning_widgets.dart';
import '../../domain/weekly_plan_generator.dart';
import '../cubit/planner_cubit.dart';

/// Screen 21 — Weekly planner (خطة الأسبوع).
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key, required this.cubit});

  static const routePath = '/planner';

  final PlannerCubit cubit;

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  @override
  void initState() {
    super.initState();
    // Self-loading: the screen never waits on route wiring to fetch.
    if (widget.cubit.state.status == PlannerStatus.loading) {
      widget.cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: PlanningScaffold(
        avoidNavigationOverlap: true,
        currentNavIndex: -1,
        child: BlocBuilder<PlannerCubit, PlannerState>(
          builder: (context, state) {
            final l10n = context.l10n;
            switch (state.status) {
              case PlannerStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case PlannerStatus.error:
                return PlanningError(
                  onRetry: () => context.read<PlannerCubit>().load(),
                );
              case PlannerStatus.ready:
                return _PlannerBody(state: state, title: l10n.plannerTitle);
            }
          },
        ),
      ),
    );
  }
}

class _PlannerBody extends StatelessWidget {
  const _PlannerBody({required this.state, required this.title});

  final PlannerState state;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plan = state.plan;
    final dayMeals = state.mealsForDay(state.selectedDayIndex);
    final dayCalories = state.caloriesForDay(state.selectedDayIndex);
    final target = plan?.dailyCalorieTarget;
    if (state.constraintIssue != null) {
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          PlanningTitle(title),
          const SizedBox(height: 16),
          GlassCard(
            child: Text(
              ar
                  ? state.constraintIssue == 'mealCount'
                        ? 'التخطيط هنا بيدعم ٣ أو ٤ وجبات حاليًا. عدد الوجبات اللي اخترته لسه مش مدعوم.'
                        : state.constraintIssue == 'review'
                        ? 'اختياراتك محتاجة مراجعة مختص قبل توليد أو تبديل وجبات. تقدر تتابع سجلك وتقاريرك عادي.'
                        : 'فيه نظام غذائي مش مدعوم هنا. التوليد والتبديل متوقفين بدل ما نتجاهله.'
                  : state.constraintIssue == 'mealCount'
                  ? 'Planning supports 3 or 4 meals. Your chosen meal count is not supported yet.'
                  : state.constraintIssue == 'review'
                  ? 'Your choices need professional review before generating or replacing meals. Your diary and reports remain available.'
                  : 'A dietary choice is not supported here. Generation and replacement are paused rather than ignoring it.',
            ),
          ),
          TextButton(
            onPressed: () => context.push('/diary'),
            child: Text(ar ? 'افتح وجباتي' : 'Open my meals'),
          ),
          TextButton(
            onPressed: () => context.push('/report'),
            child: Text(ar ? 'افتح تقريري' : 'Open my report'),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PlanningTitle(title),
                    if (state.noAlternative)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'مفيش بديل مختلف يناسب الاختيارات دي دلوقتي. وجبتك زي ما هي.'
                              : 'No different option fits these choices right now. Your meal is unchanged.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (context
                            .read<PlannerCubit>()
                            .activeFoodChoices
                            .preferred
                            .isNotEmpty ||
                        context
                            .read<PlannerCubit>()
                            .activeFoodChoices
                            .excluded
                            .isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'بنراعي الأكل اللي اخترته، لو موجود في القائمة.'
                              : 'Your food choices apply when matched in the food list.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (context
                        .read<PlannerCubit>()
                        .generator
                        .unmatchedFoodTerms([
                          ...context
                              .read<PlannerCubit>()
                              .activeFoodChoices
                              .excluded,
                          ...context
                              .read<PlannerCubit>()
                              .activeFoodChoices
                              .allergens,
                        ])
                        .isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'فيه اختيارات استبعاد مش لاقيينها في القائمة. راجع مكونات الوجبات قبل اعتمادها.'
                              : 'Some exclusions were not found in the food list. Review meal ingredients before using them.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'اقترح من وجباتي المسجّلة'
                                    : 'Include my logged meals',
                              ),
                            ),
                            Switch.adaptive(
                              value: state.includeRecordedMeals,
                              onChanged: state.saving
                                  ? null
                                  : context
                                        .read<PlannerCubit>()
                                        .setIncludeRecordedMeals,
                            ),
                          ],
                        ),
                        Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'الوجبات اللي راجعت مكوناتها وكمياتها بس'
                              : 'Only meals with reviewed catalog ingredients and weights',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    if (state.includeRecordedMeals &&
                        state.recordedCandidateCount == 0)
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'مفيش وجبات مسجلة مكتملة نقدر نقترحها دلوقتي. المعروض اقتراحات من القائمة.'
                            : 'No complete logged meal is available to reuse. Suggestions use the food list.',
                      ),
                    _DayTabs(state: state),
                    const SizedBox(height: 12),
                    if (plan == null)
                      GlassCard(
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.cyanLight,
                              size: 34,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.plannerEmpty,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: context.planningMuted),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      GlassCard(
                        borderColor: AppColors.orangeLight.withValues(
                          alpha: .5,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            for (var i = 0; i < dayMeals.length; i++) ...[
                              if (i > 0) const SizedBox(height: 12),
                              PlanningEntrance(
                                index: i,
                                child: _MealRow(meal: dayMeals[i]),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (dayMeals.isEmpty)
                        GlassCard(
                          child: Text(
                            l10n.plannerDayEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.planningMuted),
                          ),
                        ),
                      _AddMealRow(
                        state: state,
                        present: dayMeals.map((m) => m.mealType),
                      ),
                      GlassCard(
                        borderColor: AppColors.orangeLight.withValues(
                          alpha: .5,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 12,
                              children: [
                                Text(
                                  l10n.plannerTotal,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    '${planningNumber(context, dayCalories)} / ${target != null ? planningNumber(context, target) : l10n.foodUnknown}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontFamily: AppTheme.displayFontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (target != null &&
                                (dayCalories - target).abs() > target * .1)
                              Text(
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'الاقتراحات لسه مش مغطية هدف اليوم بشكل مناسب. ما تعتمدهاش كنظام يوم كامل.'
                                    : 'These suggestions do not closely match your daily target. Do not use them as a complete daily diet.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            Text(
                              l10n.plannerPortionNote,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            SufraProgressBar(
                              fraction: target != null && target > 0
                                  ? dayCalories / target
                                  : 0,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryBlue,
                                  AppColors.turquoise,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (plan != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.plannerWeekTotal(
                            planningNumber(
                              context,
                              plan.meals.fold<double>(
                                0,
                                (sum, m) => sum + m.calories,
                              ),
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.plannerAllergyWarning,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    const SizedBox(height: 12),
                    if (state.missingTarget)
                      GlassCard(
                        child: Text(
                          l10n.plannerMissingTarget,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.orangeLight),
                        ),
                      ),
                    if (MediaQuery.textScalerOf(context).scale(11) > 15)
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: _ActionButton(
                              label: l10n.plannerGenerate,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryBlue,
                                  AppColors.aiPurple,
                                ],
                              ),
                              shadow: AppColors.aiPurple,
                              busy: state.saving,
                              onTap: () =>
                                  context.read<PlannerCubit>().generate(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: _ActionButton(
                              label: l10n.plannerShoppingCta,
                              outline: true,
                              onTap: () => context.go('/shopping'),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: l10n.plannerGenerate,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryBlue,
                                  AppColors.aiPurple,
                                ],
                              ),
                              shadow: AppColors.aiPurple,
                              busy: state.saving,
                              onTap: () =>
                                  context.read<PlannerCubit>().generate(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              label: l10n.plannerShoppingCta,
                              outline: true,
                              onTap: () => context.go('/shopping'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DayTabs extends StatelessWidget {
  const _DayTabs({required this.state});

  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final letters = [
      l10n.weekdaySat,
      l10n.weekdaySun,
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
    ];
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: SufraControlFeedback(
              radius: 14,
              overlay: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<PlannerCubit>().selectDay(i);
                },
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient:
                        i == state.selectedDayIndex &&
                            Theme.of(context).brightness == Brightness.dark
                        ? const LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.turquoise,
                            ],
                          )
                        : null,
                    color:
                        i == state.selectedDayIndex &&
                            Theme.of(context).brightness == Brightness.light
                        ? AppColors.blueDeep
                        : Colors.transparent,
                    boxShadow: i == state.selectedDayIndex
                        ? [
                            BoxShadow(
                              color: AppColors.turquoise.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    letters[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: i == state.selectedDayIndex
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: i == state.selectedDayIndex
                          ? Colors.white
                          : context.planningMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal});

  final MealPlanMealModel meal;

  String _slotLabel(BuildContext context, String mealType) {
    final l10n = context.l10n;
    switch (mealType) {
      case 'breakfast':
        return l10n.mealBreakfast;
      case 'lunch':
        return l10n.mealLunch;
      case 'dinner':
        return l10n.mealDinner;
      case 'snack':
        return l10n.mealSnack;
      case 'iftar':
        return l10n.mealIftar;
      case 'suhoor':
        return l10n.mealSuhoor;
      default:
        return mealType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // foods entries are canonical catalog ids (typed portions carry the
    // quantities). Prefer a pictured ingredient without substituting another food.
    final picturedFoods = meal.foods.where(
      (id) => CatalogPhoto.forFood(id) != null,
    );
    final firstFood = picturedFoods.isNotEmpty
        ? picturedFoods.first
        : meal.foods.isEmpty
        ? null
        : meal.foods.first;
    final category = firstFood == null
        ? ''
        : context.read<PlannerCubit>().generator.categoryOf(firstFood) ?? '';
    final icon = planningIconFor(category);
    final labels = meal.foods
        .map(
          (id) => context.read<PlannerCubit>().generator.foodLabel(
            id,
            arabic: l10n.localeName.startsWith('ar'),
          ),
        )
        .toList();
    final mealTitle =
        labels.isNotEmpty && labels.every((label) => label.isNotEmpty)
        ? labels.join(l10n.localeName.startsWith('ar') ? ' و' : ', ')
        : meal.title;
    return Row(
      children: [
        firstFood != null &&
                (CatalogPhoto.forFood(firstFood) != null ||
                    CatalogFoodPainter.identity(firstFood) != null)
            ? IgnorePointer(child: CatalogFoodArt(id: firstFood, size: 44))
            : PlanningMealIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.foodPortions != null
                    ? _slotLabel(context, meal.mealType)
                    : '${_slotLabel(context, meal.mealType)} · $mealTitle',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              if (meal.foodPortions != null)
                Text(
                  meal.foodPortions!
                      .map(
                        (p) =>
                            '${context.read<PlannerCubit>().generator.foodLabel(p.foodId, arabic: l10n.localeName.startsWith('ar'))}: ${planningNumber(context, p.grams)} ${l10n.foodGramUnit}',
                      )
                      .join('\n'),
                  style: TextStyle(color: context.planningMuted, fontSize: 12),
                ),
              Text(
                '${planningNumber(context, meal.calories)} ${l10n.foodKcal}',
                style: TextStyle(color: context.planningMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: l10n.plannerReplace,
          padding: EdgeInsets.zero,
          icon: Icon(Icons.swap_horiz, color: context.planningMuted, size: 22),
          onSelected: (action) {
            HapticFeedback.selectionClick();
            final cubit = context.read<PlannerCubit>();
            if (action == 'replace') {
              cubit.replaceMeal(meal.mealId);
            } else {
              cubit.removeMeal(meal.mealId);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'replace', child: Text(l10n.plannerReplace)),
            PopupMenuItem(value: 'remove', child: Text(l10n.mealDelete)),
          ],
        ),
      ],
    );
  }
}

class _AddMealRow extends StatelessWidget {
  const _AddMealRow({required this.state, required this.present});

  final PlannerState state;
  final Iterable<String> present;

  @override
  Widget build(BuildContext context) {
    final missing = plannerSlots
        .where(
          (slot) =>
              !present.contains(slot) &&
              !(slot == 'snack' &&
                  context.read<PlannerCubit>().activeFoodChoices.mealsPerDay ==
                      3),
        )
        .toList(growable: false);
    if (state.plan == null || missing.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    String label(String slot) {
      switch (slot) {
        case 'breakfast':
          return l10n.mealBreakfast;
        case 'lunch':
          return l10n.mealLunch;
        case 'dinner':
          return l10n.mealDinner;
        default:
          return l10n.mealSnack;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final slot in missing)
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: Text('${l10n.plannerAddMeal} ${label(slot)}'),
            onPressed: state.saving
                ? null
                : () => context.read<PlannerCubit>().addMeal(slot),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.gradient,
    this.shadow,
    this.outline = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color? shadow;
  final bool outline;
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
        child: AnimatedScale(
          scale: 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: MediaQuery.textScalerOf(context).scale(11) > 15 ? null : 54,
            constraints: const BoxConstraints(minHeight: 54),
            padding: MediaQuery.textScalerOf(context).scale(11) > 15
                ? const EdgeInsets.all(12)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: outline ? null : gradient,
              color: outline ? Colors.white.withValues(alpha: 0.08) : null,
              borderRadius: BorderRadius.circular(18),
              border: outline
                  ? Border.all(color: AppColors.cyanLight)
                  : const Border.fromBorderSide(
                      BorderSide(color: Color(0x73FFFFFF), width: 0.6),
                    ),
              boxShadow: outline
                  ? null
                  : [
                      BoxShadow(
                        color: (shadow ?? AppColors.turquoise).withValues(
                          alpha: 0.45,
                        ),
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
                    style: TextStyle(
                      color: outline
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.cyanLight
                                : AppColors.primaryBlue)
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
