import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/catalog_food_art.dart';
import '../../../../core/widgets/dish_float.dart';
import '../../../../core/widgets/sufra_button_response.dart';
import '../../../../core/widgets/saved_catalog_label.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import '../../../meal_log/presentation/screens/meal_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ordered_number_pair.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../data/models/meal_entry_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../meal_log/presentation/screens/meal_log_hub_screen.dart';
import '../cubit/diary_cubit.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key, this.initialDate});
  final DateTime? initialDate;
  static const routePath = '/diary';
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>();
    final state = session.state;
    if (state is! SessionAuthenticated) {
      return const Scaffold(body: AppLoadingView());
    }
    return BlocProvider(
      key: ValueKey(state.user.uid),
      create: (context) => DiaryCubit(
        repository: context.read<NutritionRepository>(),
        uid: state.user.uid,
        date: initialDate,
        currentUid: () {
          final s = session.state;
          return s is SessionAuthenticated ? s.user.uid : null;
        },
      )..load(),
      child: const _DiaryBody(),
    );
  }
}

class _DiaryBody extends StatelessWidget {
  const _DiaryBody();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    void add() => context.push(MealLogHubScreen.routePath);
    final compact =
        MediaQuery.textScalerOf(context).scale(14) > 20 &&
        MediaQuery.sizeOf(context).height < 700;
    return Scaffold(
      extendBody: !compact,
      body: NebulaBackground(
        child: SafeArea(
          child: BlocBuilder<DiaryCubit, DiaryState>(
            builder: (context, state) {
              final target = state.calorieTarget;
              final large = MediaQuery.textScalerOf(context).scale(14) > 20;
              final compact = large && MediaQuery.sizeOf(context).height < 700;
              final cubit = context.read<DiaryCubit>();
              final first = DateTime(
                state.date.year,
                state.date.month,
                state.date.day -
                    ((state.date.weekday - DateTime.saturday + 7) % 7),
              );
              final groups = <String, List<MealEntryModel>>{
                for (final type in ['breakfast', 'lunch', 'dinner', 'snack'])
                  type: state.meals.where((m) => m.mealType == type).toList(),
              };
              final other = state.meals
                  .where((m) => !groups.containsKey(m.mealType))
                  .toList();
              if (other.isNotEmpty) {
                groups['other'] = other;
              }
              final names = {
                'breakfast': l.mealBreakfast,
                'lunch': l.mealLunch,
                'dinner': l.mealDinner,
                'snack': l.mealSnack,
                'other': l.diaryOtherMeals,
              };
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, compact ? 12 : 24, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.diaryTitle,
                            style: context.readableDisplayStyle(
                              size: compact ? 20 : 28,
                            ),
                          ),
                        ),
                        if (compact) ...[
                          IconButton(
                            key: const ValueKey('diary-previous-week'),
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).previousPageTooltip,
                            onPressed: () => cubit.load(
                              state.date.subtract(const Duration(days: 7)),
                            ),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            key: const ValueKey('diary-next-week'),
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).nextPageTooltip,
                            onPressed: () => cubit.load(
                              state.date.add(const Duration(days: 7)),
                            ),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                        IconButton(
                          tooltip: l.diaryChooseDate,
                          onPressed: () async {
                            final day = await showDatePicker(
                              context: context,
                              initialDate: state.date,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (day != null && context.mounted) {
                              cubit.load(day);
                            }
                          },
                          icon: const Icon(Icons.calendar_month_outlined),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: GestureDetector(
                      onHorizontalDragEnd: (d) {
                        final v = d.primaryVelocity ?? 0;
                        if (v.abs() > 150) {
                          cubit.load(
                            DateTime(
                              state.date.year,
                              state.date.month,
                              state.date.day + (v > 0 ? -7 : 7),
                            ),
                          );
                        }
                      },
                      child: _WeekViewport(
                        large: large,
                        child: Row(
                          children: [
                            for (var i = 0; i < 7; i++)
                              _DayWidth(
                                large: large,
                                child: Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    end: i == 6 ? 0 : 6,
                                  ),
                                  child: _DayButton(
                                    day: DateTime(
                                      first.year,
                                      first.month,
                                      first.day + i,
                                    ),
                                    selected: state.date,
                                    onTap: cubit.load,
                                    locale: locale,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (large && !compact)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          key: const ValueKey('diary-previous-week'),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).previousPageTooltip,
                          onPressed: () => cubit.load(
                            state.date.subtract(const Duration(days: 7)),
                          ),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        IconButton(
                          key: const ValueKey('diary-next-week'),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).nextPageTooltip,
                          onPressed: () => cubit.load(
                            state.date.add(const Duration(days: 7)),
                          ),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  Expanded(
                    child: state.loading
                        ? const AppLoadingView()
                        : state.failed
                        ? AppErrorView(onRetry: cubit.load)
                        : RefreshIndicator(
                            onRefresh: cubit.load,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                GlassCard(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Directionality(
                                                  textDirection:
                                                      TextDirection.ltr,
                                                  child: Wrap(
                                                    spacing: 5,
                                                    children: [
                                                      if (target != null &&
                                                          target > 0)
                                                        OrderedNumberPair(
                                                          key: const ValueKey(
                                                            'diary-calorie-pair',
                                                          ),
                                                          first: state.calories
                                                              .round(),
                                                          second: target
                                                              .round(),
                                                          style: context
                                                              .readableDisplayStyle(
                                                                size: 20,
                                                              ),
                                                        )
                                                      else
                                                        Text(
                                                          '${state.calories.round()}',
                                                          style: context
                                                              .readableDisplayStyle(
                                                                size: 20,
                                                              ),
                                                        ),
                                                      Text(
                                                        l.foodKcal,
                                                        style: context
                                                            .readableDisplayStyle(
                                                              size: 20,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (target != null && target > 0)
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional.only(
                                                    start: 8,
                                                  ),
                                              child: Text(
                                                '${(state.calories / target * 100).round()}%',
                                                textDirection:
                                                    TextDirection.ltr,
                                                style: context.mutedStyle(),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (target != null && target > 0) ...[
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: (state.calories / target)
                                                .clamp(0, 1),
                                            minHeight: 9,
                                            color: AppColors.turquoise,
                                            backgroundColor: Colors.white12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                for (final group in groups.entries) ...[
                                  const SizedBox(height: 12),
                                  GlassCard(
                                    key: ValueKey('diary-slot-${group.key}'),
                                    borderColor: const Color(0x66D99A35),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          spacing: 12,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              names[group.key]!,
                                              style: context
                                                  .readableDisplayStyle(
                                                    size: 18,
                                                  ),
                                            ),
                                            if (group.value.length != 1)
                                              Text(
                                                group.value.isEmpty
                                                    ? l.diaryEmptySlot
                                                    : group.value
                                                          .fold<double>(
                                                            0,
                                                            (s, m) =>
                                                                s +
                                                                m.totalCalories,
                                                          )
                                                          .round()
                                                          .toString(),
                                                style: context.mutedStyle(),
                                              ),
                                          ],
                                        ),
                                        for (final meal in group.value) ...[
                                          const SizedBox(height: 8),
                                          _MealRow(meal: meal, locale: locale),
                                        ],
                                        if (group.value.isEmpty) ...[
                                          const SizedBox(height: 12),
                                          GradientButton(
                                            label: l.diaryAddMeal,
                                            onPressed: add,
                                            height: 48,
                                            fontSize: 15,
                                            borderRadius: 16,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FloatingGlassNavBar(
          currentIndex: 1,
          onAdd: add,
          items: [
            NavItem(
              label: l.navHome,
              icon: Icons.home_rounded,
              onTap: () => context.go('/home'),
            ),
            NavItem(
              label: l.navDiary,
              icon: Icons.calendar_today_rounded,
              onTap: () {},
            ),
            NavItem(
              label: l.navProgress,
              icon: Icons.show_chart_rounded,
              onTap: () => context.go('/stats'),
            ),
            NavItem(
              label: l.navAccount,
              icon: Icons.person_outline_rounded,
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.selected,
    required this.onTap,
    required this.locale,
  });
  final DateTime day;
  final DateTime selected;
  final ValueChanged<DateTime> onTap;
  final String locale;
  @override
  Widget build(BuildContext context) {
    final active = DateUtils.isSameDay(day, selected);
    final label = locale == 'ar'
        ? const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'][day.weekday - 1]
        : DateFormat.E(locale).format(day).substring(0, 1);
    return Semantics(
      selected: active,
      button: true,
      label: DateFormat.yMMMEd(locale).format(day),
      child: InkWell(
        key: ValueKey('diary-day-${day.year}-${day.month}-${day.day}'),
        onTap: () => onTap(day),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: active ? null : Colors.white.withValues(alpha: .1),
            gradient: active ? AppColors.primaryGradient : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.turquoise.withValues(alpha: .5),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text('${day.day}', style: context.readableDisplayStyle(size: 17)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealRow extends StatefulWidget {
  const _MealRow({required this.meal, required this.locale});
  final MealEntryModel meal;
  final String locale;
  @override
  State<_MealRow> createState() => _MealRowState();
}

class _MealRowState extends State<_MealRow> {
  bool hovered = false, pressed = false, focused = false;
  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final locale = widget.locale;
    final active = hovered || focused;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final large = MediaQuery.textScalerOf(context).scale(14) > 20;
    final fallback = meal.items.length == 1
        ? CatalogFoodArt(id: meal.items.single.foodId, size: 72)
        : const Icon(
            Icons.restaurant_outlined,
            color: AppColors.orangeDeep,
            size: 36,
          );
    final art = ExcludeSemantics(
      child: IgnorePointer(
        child: _VisibleDiaryDish(
          child: SizedBox(
            width: 80,
            height: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child:
                  meal.imageUrl != null &&
                      Uri.tryParse(meal.imageUrl!)?.scheme == 'https'
                  ? Image.network(
                      meal.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallback,
                    )
                  : Center(child: fallback),
            ),
          ),
        ),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meal.inputMethod == 'catalog' &&
            meal.items.length == 1 &&
            meal.title == meal.items.single.foodName)
          SavedCatalogLabel(
            item: meal.items.single,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          )
        else
          Text(
            meal.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        const SizedBox(height: 4),
        Text(
          DateFormat.Hm(locale).format(meal.consumedAt),
          textDirection: TextDirection.ltr,
          style: context.mutedStyle(size: 12),
        ),
        for (final item in meal.items)
          SavedCatalogLabel(
            item: item,
            amount: true,
            style: context.mutedStyle(size: 12),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x77D99A35)),
            color: dark ? const Color(0x181565C0) : const Color(0x111565C0),
          ),
          child: Text(
            '${meal.totalCalories.round()} kcal',
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ],
    );
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedScale(
        scale: pressed && !reduced ? .985 : 1,
        duration: reduced ? Duration.zero : const Duration(milliseconds: 160),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? const Color(0x99D99A35) : const Color(0x33D99A35),
            ),
            gradient: LinearGradient(
              colors: dark
                  ? const [Color(0x241565C0), Color(0x187C3AED)]
                  : const [Color(0x101565C0), Color(0x0AFB8C00)],
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withValues(alpha: .13),
                      blurRadius: 16,
                    ),
                  ]
                : [],
          ),
          child: SufraButtonResponse(
            radius: 20,
            pressed: pressed,
            hovered: active,
            intensity: .15,
            child: InkWell(
              key: ValueKey('diary-meal-${meal.mealId}'),
              borderRadius: BorderRadius.circular(20),
              onHighlightChanged: (v) => setState(() => pressed = v),
              onFocusChange: (v) => setState(() => focused = v),
              onTap: () async {
                final changed = await context.push<bool>(
                  MealDetailScreen.locationFor(meal),
                );
                if (changed == true && context.mounted) {
                  context.read<DiaryCubit>().load();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: large
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: art,
                          ),
                          const SizedBox(height: 10),
                          details,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          art,
                          const SizedBox(width: 12),
                          Expanded(child: details),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekViewport extends StatelessWidget {
  const _WeekViewport({required this.large, required this.child});
  final bool large;
  final Widget child;
  @override
  Widget build(BuildContext context) => large
      ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: child)
      : child;
}

class _DayWidth extends StatelessWidget {
  const _DayWidth({required this.large, required this.child});
  final bool large;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      large ? SizedBox(width: 60, child: child) : Expanded(child: child);
}

/// Only visible diary artwork keeps a ticker. Text and values never float.
class _VisibleDiaryDish extends StatefulWidget {
  const _VisibleDiaryDish({required this.child});
  final Widget child;
  @override
  State<_VisibleDiaryDish> createState() => _VisibleDiaryDishState();
}

class _VisibleDiaryDishState extends State<_VisibleDiaryDish> {
  ScrollPosition? position;
  bool visible = false, queued = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != position) {
      position?.removeListener(schedule);
      position = next;
      position?.addListener(schedule);
    }
    schedule();
  }

  void schedule() {
    if (queued) return;
    queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      queued = false;
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final y = box.localToGlobal(Offset.zero).dy;
      final next =
          y + box.size.height > 0 &&
          y <
              MediaQuery.sizeOf(context).height -
                  FloatingGlassNavBar.barHeight(context) -
                  16;
      if (next != visible) setState(() => visible = next);
    });
  }

  @override
  void dispose() {
    position?.removeListener(schedule);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TickerMode(
    enabled: visible && !MediaQuery.disableAnimationsOf(context),
    child: DishFloat(child: widget.child),
  );
}
