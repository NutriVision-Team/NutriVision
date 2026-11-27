import '../../../achievements/domain/achievement_activity.dart';
import '../stats_achievement_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/water_weight_repository.dart';
import '../cubit/weight_cubit.dart';
import 'package:flutter/material.dart';
import 'package:sufradepi/core/widgets/sufra_button_response.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/day_nutrition.dart';
import '../cubit/progress_cubit.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

import '../progress_format.dart';
import '../widgets/progress_nav.dart';

/// Screen — تقدمي (design p-Stats): week/month calorie chart, streak
/// card, weight card and badges. Genuine daily-log data only; days
/// without recorded meals render as unknown, never as zero.
class StatsScreen extends StatelessWidget {
  const StatsScreen({
    super.key,
    this.waterWeightRepository,
    this.achievementLoader,
  });
  final AchievementActivityLoader? achievementLoader;
  final WaterWeightRepository? waterWeightRepository;

  static const String routePath = '/stats';

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProgressCubit>(
          create: (context) {
            final session = context.read<SessionCubit>().state;
            final uid = session is SessionAuthenticated ? session.user.uid : '';
            return ProgressCubit(
              nutritionRepository: context.read<NutritionRepository>(),
              uid: uid,
              currentUid: () {
                final s = context.read<SessionCubit>().state;
                return s is SessionAuthenticated ? s.user.uid : null;
              },
            )..load();
          },
        ),
        BlocProvider<WeightCubit>(
          create: (context) {
            final session = context.read<SessionCubit>();
            final state = session.state;
            return WeightCubit(
              waterWeightRepository:
                  waterWeightRepository ??
                  FirestoreWaterWeightRepository(FirebaseFirestore.instance),
              nutritionRepository: context.read<NutritionRepository>(),
              uid: state is SessionAuthenticated ? state.user.uid : '',
              currentUid: () {
                final s = session.state;
                return s is SessionAuthenticated ? s.user.uid : null;
              },
            )..load();
          },
        ),
      ],
      child: _StatsView(achievementLoader: achievementLoader),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView({this.achievementLoader});
  final AchievementActivityLoader? achievementLoader;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: MediaQuery.textScalerOf(context).scale(11) <= 15,
      body: NebulaBackground(
        child: SafeArea(
          child: BlocBuilder<ProgressCubit, ProgressState>(
            builder: (context, state) {
              if (state.loading && state.days.isEmpty) {
                return const AppLoadingView();
              }
              if (state.failed && state.days.isEmpty) {
                return AppErrorView(
                  onRetry: () => context.read<ProgressCubit>().load(),
                );
              }
              return _StatsContent(
                state: state,
                achievementLoader: achievementLoader,
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const ProgressNavBar(currentIndex: 2),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.state, this.achievementLoader});
  final AchievementActivityLoader? achievementLoader;

  final ProgressState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final averages = state.averages;
    final target = averages.calorieTarget;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 112),
      children: [
        Text(l10n.statsTitle, style: context.displayStyle(size: 28)),
        const SizedBox(height: 12),
        _PeriodTabs(period: state.period),
        const SizedBox(height: 12),
        _StreakCard(state: state),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text(
                    l10n.statsCaloriesTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (averages.calories != null && target != null)
                    Text(
                      l10n.statsCaloriesAverage(
                        ProgressFormat.intDigits(
                          averages.calories!,
                          locale: l10n.localeName,
                        ),
                        ProgressFormat.intDigits(
                          target,
                          locale: l10n.localeName,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textMuted
                            : AppColors.lightTextMuted),
                      ),
                    )
                  else
                    Text(
                      l10n.statsNoTrackedDays,
                      overflow: TextOverflow.ellipsis,
                      style: context.mutedStyle(size: 12),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _CalorieChart(state: state, target: target),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(child: _WeightCard()),
              SizedBox(width: 12),
              Expanded(
                child: StatsAchievementCard(
                  uid:
                      (context.read<SessionCubit>().state
                              as SessionAuthenticated)
                          .user
                          .uid,
                  currentUid: () {
                    final s = context.read<SessionCubit>().state;
                    return s is SessionAuthenticated ? s.user.uid : null;
                  },
                  loader: achievementLoader,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          collapsedTextColor: Theme.of(context).colorScheme.onSurface,
          textColor: Theme.of(context).colorScheme.onSurface,
          title: Text(l10n.statsMacroPerformance),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.statsMacroPerformance,
                    style: context.displayStyle(size: 18),
                  ),
                  for (final (name, value, goal, coverage) in [
                    (
                      l10n.foodProtein,
                      averages.protein,
                      averages.proteinTarget,
                      state.days
                          .where((d) => d.tracked && d.protein != null)
                          .length,
                    ),
                    (
                      l10n.foodCarbs,
                      averages.carbs,
                      averages.carbsTarget,
                      state.days
                          .where((d) => d.tracked && d.carbs != null)
                          .length,
                    ),
                    (
                      l10n.foodFat,
                      averages.fat,
                      averages.fatTarget,
                      state.days
                          .where((d) => d.tracked && d.fat != null)
                          .length,
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              Text(name),
                              Text(
                                value == null
                                    ? l10n.foodUnknown
                                    : '${ProgressFormat.oneDecimal(value, locale: l10n.localeName)} ${l10n.foodGramUnit}',
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          if (value != null && goal != null && goal > 0)
                            LinearProgressIndicator(
                              value: (value / goal).clamp(0.0, 1.0),
                              minHeight: 6,
                              color: AppColors.turquoise,
                            ),
                          const SizedBox(height: 5),
                          Text(
                            l10n.statsMacroCoverage(
                              ProgressFormat.intDigits(
                                coverage.toDouble(),
                                locale: l10n.localeName,
                              ),
                              ProgressFormat.intDigits(
                                state.days.length.toDouble(),
                                locale: l10n.localeName,
                              ),
                              goal == null
                                  ? l10n.foodUnknown
                                  : ProgressFormat.oneDecimal(
                                      goal,
                                      locale: l10n.localeName,
                                    ),
                            ),
                            style: context.mutedStyle(size: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.period});

  final ProgressPeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          for (final p in ProgressPeriod.values)
            Expanded(
              child: SufraControlFeedback(
                radius: 99,
                child: GestureDetector(
                  onTap: () => context.read<ProgressCubit>().load(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: p == period ? AppColors.primaryGradient : null,
                    ),
                    child: Text(
                      p == ProgressPeriod.week
                          ? l10n.statsTabWeek
                          : l10n.statsTabMonth,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: p == period
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: p == period
                            ? Colors.white
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.textMuted
                                  : AppColors.lightTextMuted),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.state});

  final ProgressState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final last7 = state.days.length > 7
        ? state.days.sublist(state.days.length - 7)
        : state.days;
    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x80FB8C00), Color(0x4DEF4444)],
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppColors.error, AppColors.copper, Color(0xFFFDE047)],
            ).createShader(rect),
            child: const Icon(
              Icons.local_fire_department,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.statsStreakDays(
                    ProgressFormat.intDigits(
                      state.streakDays,
                      locale: l10n.localeName,
                    ),
                  ),
                  style: context.displayStyle(size: 30).copyWith(height: 1.35),
                ),
                Text(
                  l10n.statsStreakCheer,
                  style: context.mutedStyle(size: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final day in last7)
                      Expanded(
                        child: Container(
                          height: 8,
                          margin: const EdgeInsetsDirectional.only(end: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: day.tracked
                                ? const Color(0xFFFDE047)
                                : Colors.white.withValues(alpha: 0.15),
                            boxShadow: day.tracked
                                ? const [
                                    BoxShadow(
                                      color: Color(0xCCFB8C00),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieChart extends StatelessWidget {
  const _CalorieChart({required this.state, required this.target});

  final ProgressState state;
  final double? target;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = state.days;
    // Design scale: the dashed target line sits at 12% from the top, so
    // 100% of target maps to 88% of the bar area.
    const scale = 0.88;
    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          if (target != null)
            Positioned(
              top: 120 * 0.12,
              left: 0,
              right: 0,
              child: CustomPaint(painter: _DashedLinePainter()),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _Bar(
                              day: days[i],
                              target: target,
                              scale: scale,
                              delay: Duration(milliseconds: 100 * i),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          days.length == 7
                              ? weekdayLetter(l10n, days[i].date)
                              : ProgressFormat.intDigits(
                                  days[i].date.day,
                                  locale: l10n.localeName,
                                ),
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textMuted
                                : AppColors.lightTextMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.target,
    required this.scale,
    required this.delay,
  });

  final DayNutrition day;
  final double? target;
  final double scale;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final calories = day.calories;
    final t = target;
    if (!day.tracked || calories == null || t == null || t <= 0) {
      // Unknown day: no fabricated zero bar, just a faint track mark.
      return FractionallySizedBox(
        heightFactor: 0.04,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(10),
              bottom: Radius.circular(4),
            ),
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
      );
    }
    final fraction = (calories / t * scale).clamp(0.0, 1.0);
    final over = calories > t;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return FractionallySizedBox(
          heightFactor: value == 0 ? 0.02 : value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
                bottom: Radius.circular(4),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: over
                    ? const [AppColors.pinkLight, AppColors.primaryBlue]
                    : const [AppColors.cyanLight, AppColors.primaryBlue],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.turquoise.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orangeLight
      ..strokeWidth = 2;
    const dash = 8.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + dash).clamp(0, size.width).toDouble(), 0),
        paint,
      );
      x += dash * 2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WeightCard extends StatelessWidget {
  const _WeightCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weight = context.watch<WeightCubit>().state;
    final delta = weight.deltaKg;
    return GlassCard(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 128),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.statsWeightTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (delta != null)
              Row(
                children: [
                  Icon(
                    delta >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 20,
                    color: delta >= 0
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.greenLight
                              : const Color(0xFF137A3F))
                        : (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.pinkLight
                              : const Color(0xFFAE2347)),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      '${ProgressFormat.oneDecimal(delta.abs(), locale: l10n.localeName)} ${l10n.weightKg}',
                      style: context.displayStyle(
                        size: 22,
                        color: delta >= 0
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.greenLight
                                  : const Color(0xFF137A3F))
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.pinkLight
                                  : const Color(0xFFAE2347)),
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(l10n.statsNoWeightData, style: context.mutedStyle(size: 12)),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeightTrendPainter(
                  weight.logs.reversed.map((e) => e.weightKg).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightTrendPainter extends CustomPainter {
  _WeightTrendPainter(this.weights);
  final List<double> weights;
  @override
  void paint(Canvas canvas, Size size) {
    final values = weights.where((v) => v.isFinite && v > 0).toList();
    if (values.length < 2) return;
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final range = high - low;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = range == 0
          ? size.height / 2
          : 4 + (high - values[i]) / range * (size.height - 8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = AppColors.cyanLight,
    );
  }

  @override
  bool shouldRepaint(_WeightTrendPainter old) => old.weights != weights;
}
