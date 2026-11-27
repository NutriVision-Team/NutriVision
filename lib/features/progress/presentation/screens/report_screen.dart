import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/viewport_reveal.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/day_nutrition.dart';
import '../cubit/progress_cubit.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

import '../progress_format.dart';
import '../widgets/progress_nav.dart';
import 'export_report_screen.dart';

/// Screen — التقرير (design p-Report): week summary rings, daily
/// commitment cells, water cups and meal distribution, plus a computed
/// sugar insight. Reached from the home "what you ate today" card.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  static const String routePath = '/report';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
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
      child: const _ReportView(),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              return _ReportContent(state: state);
            },
          ),
        ),
      ),
      bottomNavigationBar: const ProgressNavBar(currentIndex: 2),
      floatingActionButton: MediaQuery.textScalerOf(context).scale(12) > 16
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExportReportScreen()),
              ),
              backgroundColor: AppColors.primaryBlue,
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0,
              disabledElevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide.none,
              ),
              icon: const Icon(
                Icons.picture_as_pdf_outlined,
                color: Colors.white,
              ),
              label: Text(
                l10n.exportPdfBadge,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.state});

  final ProgressState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final averages = state.averages;
    final caloriePct = NutritionAverages.percent(
      averages.calories,
      averages.calorieTarget,
    );
    final proteinPct = NutritionAverages.percent(
      averages.protein,
      averages.proteinTarget,
    );
    final week = state.days.length > 7
        ? state.days.sublist(state.days.length - 7)
        : state.days;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 100),
      children: [
        if (MediaQuery.textScalerOf(context).scale(12) > 16)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExportReportScreen()),
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(l10n.exportPdfBadge),
            ),
          ),
        Text(l10n.reportTitle, style: context.readableDisplayStyle(size: 28)),
        Text(l10n.reportSubtitle, style: context.mutedStyle()),
        Text(
          l10n.reportLoggedCoverage(averages.trackedDays, state.days.length),
          style: context.mutedStyle(),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ring = _Rings(
                caloriePct: caloriePct,
                proteinPct: proteinPct,
                centerValue: averages.calories,
              );
              final legend = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legend(
                    context,
                    AppColors.cyanLight,
                    caloriePct == null
                        ? l10n.reportUnknownCalories
                        : l10n.reportRingCalories(
                            ProgressFormat.intDigits(
                              caloriePct,
                              locale: l10n.localeName,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  _legend(
                    context,
                    AppColors.orangeLight,
                    proteinPct == null
                        ? l10n.reportUnknownProtein
                        : l10n.reportRingProtein(
                            ProgressFormat.intDigits(
                              proteinPct,
                              locale: l10n.localeName,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  _legend(
                    context,
                    const Color(0xFFC4B5FD),
                    averages.fiber == null
                        ? l10n.reportUnknownFiber
                        : '${l10n.reportRecordedFiber}: ${ProgressFormat.oneDecimal(averages.fiber!, locale: l10n.localeName)} ${l10n.foodGramUnit}',
                  ),
                ],
              );
              if (MediaQuery.textScalerOf(context).scale(12) > 18 ||
                  constraints.maxWidth < 280) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [ring, const SizedBox(height: 12), legend],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ring,
                  const SizedBox(width: 12),
                  Expanded(child: legend),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.reportDailyCommitment,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final day in week)
                    Expanded(child: _CommitmentCell(day: day)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (MediaQuery.textScalerOf(context).scale(12) > 18)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WaterCard(days: week),
              const SizedBox(height: 12),
              const _DistributionCard(),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _WaterCard(days: week)),
              const SizedBox(width: 12),
              const Expanded(child: _DistributionCard()),
            ],
          ),
        const SizedBox(height: 12),
        _SugarInsight(days: week),
        const SizedBox(height: 12),
        ExpansionTile(
          collapsedTextColor: Theme.of(context).colorScheme.onSurface,
          textColor: Theme.of(context).colorScheme.onSurface,
          title: Text(l10n.reportMeasuredAverages),
          children: [
            if (state.days.isNotEmpty)
              Text(
                l10n.reportRangeLabel(
                  '\u2066${state.days.first.dateKey}\u2069',
                  '\u2066${state.days.last.dateKey}\u2069',
                ),
                style: context.mutedStyle(),
              ),
            _RecordedAverages(days: state.days),
          ],
        ),
      ],
    );
  }

  Widget _legend(BuildContext context, Color color, String text) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text.replaceAllMapped(
              RegExp(r'[0-9٠-٩۰-۹.,٫]+[%٪]'),
              (m) => '\u2066${m[0]}\u2069',
            ),
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _Rings extends StatelessWidget {
  const _Rings({
    required this.caloriePct,
    required this.proteinPct,
    required this.centerValue,
  });

  final double? caloriePct;
  final double? proteinPct;
  final double? centerValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 150,
      height: 150,
      child: ViewportReveal(
        builder: (context, visible) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: visible ? 1 : 0),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 850),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => CustomPaint(
            painter: _RingsPainter(
              outer: (caloriePct ?? 0) / 100 * value,
              middle: (proteinPct ?? 0) / 100 * value,
              trackColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: .10),
            ),
            child: child,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(34),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerValue == null
                          ? '—'
                          : ProgressFormat.intDigits(
                              centerValue!,
                              locale: l10n.localeName,
                            ),
                      style: context.readableDisplayStyle(size: 20),
                    ),
                    Text(
                      l10n.reportAverageCalories,
                      style: context.mutedStyle(size: 10),
                    ),
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

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.outer,
    required this.middle,
    required this.trackColor,
  });

  final double outer;
  final double middle;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    void ring(double radius, double fraction, Color color) {
      final track = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = trackColor;
      canvas.drawCircle(center, radius, track);
      if (fraction <= 0) return;
      final progress = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction.clamp(0.0, 1.0),
        false,
        progress,
      );
    }

    ring(66, outer, AppColors.turquoise);
    ring(50, middle, AppColors.copper);
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) =>
      oldDelegate.outer != outer ||
      oldDelegate.middle != middle ||
      oldDelegate.trackColor != trackColor;
}

class _CommitmentCell extends StatelessWidget {
  const _CommitmentCell({required this.day});

  final DayNutrition day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Recording is neutral. Calories above or below a target never earn a
    // success/failure color and a missing day is not a failure.
    final color = day.tracked
        ? AppColors.cyanLight
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15);
    return Column(
      children: [
        AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 600),
          key: ValueKey('report-recorded-${day.dateKey}'),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Semantics(
            label: weekdayName(l10n, day.date),
            child: Text(
              weekdayLetter(l10n, day.date),
              style: context.mutedStyle(size: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({required this.days});

  final List<DayNutrition> days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const cupMl = 250.0;
    final goalMl =
        context.watch<ProgressCubit>().state.hydrationGoalMl ?? 2000.0;
    final latest = days.isEmpty ? 0.0 : days.last.waterMl;
    final cups = (latest / cupMl).floor();
    final goalCups = (goalMl / cupMl).round().clamp(1, 80);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reportWaterToday,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 0,
            runSpacing: 6,
            children: [
              for (var i = 0; i < goalCups; i++)
                Container(
                  width: 12,
                  height: 28,
                  margin: const EdgeInsetsDirectional.only(end: 3),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                      bottom: Radius.circular(9),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.cyanLight.withValues(
                          alpha: i < cups ? 1 : 0.2,
                        ),
                        AppColors.primaryBlue.withValues(
                          alpha: i < cups ? 1 : 0.2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.reportWaterCupsOf(
              ProgressFormat.intDigits(goalCups, locale: l10n.localeName),
              ProgressFormat.intDigits(cups, locale: l10n.localeName),
            ),
            style: context.mutedStyle(size: 12),
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<ProgressCubit>().state;
    // Meal-type distribution is aggregated locally from owned
    // MealEntryModel.mealType records over the current window; an empty
    // ring means no meal entries in the window, not zero meals eaten.
    return GlassCard(
      child: Column(
        children: [
          Text(
            l10n.reportMealDistribution,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          _MealDonut(counts: state.mealTypeCounts),
          const SizedBox(height: 8),
          if (state.mealTypeCounts.values.fold<int>(0, (a, b) => a + b) == 0)
            Text(
              l10n.reportNoMeals,
              textAlign: TextAlign.center,
              style: context.mutedStyle(size: 12),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 5,
              alignment: WrapAlignment.center,
              children: [
                for (final entry in state.mealTypeCounts.entries)
                  if (entry.value > 0)
                    Text(
                      '${switch (entry.key) {
                        'breakfast' => l10n.mealBreakfast,
                        'lunch' => l10n.mealLunch,
                        'dinner' => l10n.mealDinner,
                        'snack' => l10n.mealSnack,
                        _ => l10n.reportOtherMeals,
                      }}: ${ProgressFormat.intDigits(entry.value, locale: l10n.localeName)}',
                      style: context.mutedStyle(size: 11),
                    ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Donut of meal-type shares using the design's three colors
/// (breakfast green, lunch orange, dinner purple); snacks and any other
/// recorded type share a neutral gray. Empty ring when nothing logged.
class _MealDonut extends StatelessWidget {
  const _MealDonut({required this.counts});

  final Map<String, int> counts;

  static const _segments = [
    ('breakfast', Color(0xFF4ADE80)),
    ('lunch', Color(0xFFFB8C00)),
    ('dinner', Color(0xFFA78BFA)),
  ];
  static const _other = Color(0xFF8B93A8);

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final parts = <(Color, double)>[
      for (final (type, color) in _segments)
        if ((counts[type] ?? 0) > 0) (color, (counts[type] ?? 0).toDouble()),
    ];
    final known = parts.fold<double>(0, (a, p) => a + p.$2);
    final rest = total - known;
    if (rest > 0) parts.add((_other, rest.toDouble()));
    return SizedBox(
      width: 76,
      height: 76,
      child: CustomPaint(
        painter: _DonutPainter(
          parts: parts,
          empty: total == 0,
          trackColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: .15),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.parts,
    required this.empty,
    required this.trackColor,
  });

  final List<(Color, double)> parts;
  final bool empty;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    const stroke = 12.0;
    if (empty) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = trackColor,
      );
      return;
    }
    final total = parts.fold<double>(0, (a, p) => a + p.$2);
    var start = -math.pi / 2;
    for (final (color, value) in parts) {
      final sweep = (value / total) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
          ..color = color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class _SugarInsight extends StatelessWidget {
  const _SugarInsight({required this.days});

  final List<DayNutrition> days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Computed insight: a tracked day whose measured sugar is at least
    // 35% above the other tracked days' average. No fabricated alerts.
    double? spikePct;
    int? spikeDay;
    final trackedSugars = days
        .where((d) => d.tracked && d.sugar != null)
        .map((d) => d.sugar!)
        .toList();
    if (trackedSugars.length >= 3) {
      for (var i = 0; i < days.length; i++) {
        final d = days[i];
        final s = d.sugar;
        if (!d.tracked || s == null) continue;
        final others = [
          for (var j = 0; j < days.length; j++)
            if (j != i && days[j].tracked && days[j].sugar != null)
              days[j].sugar!,
        ];
        if (others.isEmpty) continue;
        final avg = others.reduce((a, b) => a + b) / others.length;
        if (avg > 0 && s > avg * 1.35) {
          spikePct = (s / avg - 1) * 100;
          spikeDay = i;
        }
      }
    }
    if (spikePct == null || spikeDay == null) {
      return const SizedBox.shrink();
    }
    final dayName = weekdayName(l10n, days[spikeDay].date);
    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x59FB7185), Color(0x0AFFFFFF)],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 40,
            color: AppColors.pinkLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reportSugarAlertTitle(dayName),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  l10n.reportSugarAlertBody(
                    ProgressFormat.intDigits(spikePct, locale: l10n.localeName),
                  ),
                  style: context.mutedStyle(size: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordedAverages extends StatelessWidget {
  const _RecordedAverages({required this.days});
  final List<DayNutrition> days;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), a = NutritionAverages.of(days);
    final metrics =
        <
          ({
            String name,
            double? value,
            double? Function(DayNutrition) read,
            String unit,
          })
        >[
          (
            name: l.exportProteinLabel,
            value: a.protein,
            read: (d) => d.protein,
            unit: l.foodGramUnit,
          ),
          (
            name: l.exportCarbsLabel,
            value: a.carbs,
            read: (d) => d.carbs,
            unit: l.foodGramUnit,
          ),
          (
            name: l.exportFatLabel,
            value: a.fat,
            read: (d) => d.fat,
            unit: l.foodGramUnit,
          ),
          (
            name: l.foodFiber,
            value: a.fiber,
            read: (d) => d.fiber,
            unit: l.foodGramUnit,
          ),
        ];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.reportMeasuredAverages,
            style: context.readableDisplayStyle(size: 17),
          ),
          for (final m in metrics)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      Text(
                        m.name,
                        style: context.readableDisplayStyle(size: 16),
                      ),
                      Text(
                        '${m.value == null ? '—' : ProgressFormat.oneDecimal(m.value!, locale: l.localeName)} ${m.unit}',
                        style: context.readableDisplayStyle(size: 16),
                      ),
                    ],
                  ),
                  Text(
                    l.reportMetricCoverage(
                      ProgressFormat.intDigits(
                        days
                            .where((d) => d.tracked && m.read(d) != null)
                            .length,
                        locale: l.localeName,
                      ),
                      ProgressFormat.intDigits(
                        days.length,
                        locale: l.localeName,
                      ),
                    ),
                    style: context.mutedStyle(size: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
