import '../../export/coach_report_snapshot.dart';
import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:clock/clock.dart' as time;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../data/models/nutrition_profile_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../data/water_weight_repository.dart';
import '../../domain/day_nutrition.dart';
import '../../export/report_pdf.dart';
import '../../export/nutrition_report_data.dart';
import '../cubit/progress_cubit.dart';
import '../cubit/weight_cubit.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

import '../progress_format.dart';

/// Selected-range report preview, daily, weekly, monthly or custom.
/// The light
/// record-based report preview with user-controlled PDF export and share.
class ExportReportScreen extends StatelessWidget {
  const ExportReportScreen({super.key, this.waterWeightRepository, this.coach});

  static const String routePath = '/report/export';

  final WaterWeightRepository? waterWeightRepository;
  final CoachReportSnapshot? coach;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final session = context.read<SessionCubit>().state;
            final uid = session is SessionAuthenticated ? session.user.uid : '';
            return ProgressCubit(
              nutritionRepository: context.read<NutritionRepository>(),
              userRepository: context.read<UserRepository>(),
              uid: uid,
              currentUid: () {
                final s = context.read<SessionCubit>().state;
                return s is SessionAuthenticated ? s.user.uid : null;
              },
            )..load(ProgressPeriod.week);
          },
        ),
        BlocProvider(
          create: (context) {
            final session = context.read<SessionCubit>().state;
            final uid = session is SessionAuthenticated ? session.user.uid : '';
            return WeightCubit(
              waterWeightRepository:
                  waterWeightRepository ??
                  FirestoreWaterWeightRepository(FirebaseFirestore.instance),
              nutritionRepository: context.read<NutritionRepository>(),
              uid: uid,
              currentUid: () {
                final s = context.read<SessionCubit>().state;
                return s is SessionAuthenticated ? s.user.uid : null;
              },
            )..load(
              rangeStart: SufraDateUtils.shiftDays(
                SufraDateUtils.startOfDay(time.clock.now()),
                -6,
              ),
              rangeEnd: time.clock.now(),
            );
          },
        ),
      ],
      child: _ExportView(coach: coach),
    );
  }
}

class _ExportView extends StatefulWidget {
  const _ExportView({this.coach});
  final CoachReportSnapshot? coach;

  @override
  State<_ExportView> createState() => _ExportViewState();
}

class _ExportViewState extends State<_ExportView> {
  final _boundaryKey = GlobalKey();
  bool _exporting = false;
  DateTimeRange? _range;
  String _preset = 'week';
  Future<void> _choosePreset(String preset) async {
    final end = SufraDateUtils.startOfDay(time.clock.now());
    final start = preset == 'day'
        ? end
        : preset == 'month'
        ? DateTime(end.year, end.month, 1)
        : SufraDateUtils.shiftDays(end, -6);
    final range = DateTimeRange(start: start, end: end);
    setState(() {
      _preset = preset;
      _range = range;
    });
    await Future.wait([
      context.read<ProgressCubit>().loadRange(range.start, range.end),
      context.read<WeightCubit>().load(
        rangeStart: range.start,
        rangeEnd: range.end,
      ),
    ]);
  }

  Future<void> _export(NutritionReportData data) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final session = context.read<SessionCubit>();
      final owner = session.state;
      if (owner is! SessionAuthenticated) return;
      await ReportPdfExporter.shareNative(
        data,
        canShare: () {
          final state = session.state;
          return mounted &&
              state is SessionAuthenticated &&
              state.user.uid == owner.user.uid;
        },
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SufraSnackBar(content: Text(AppLocalizations.of(context).stateError)),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: BlocBuilder<ProgressCubit, ProgressState>(
            builder: (context, progress) {
              final weight = context.watch<WeightCubit>().state;
              if (progress.loading && progress.days.isEmpty) {
                return const AppLoadingView();
              }
              if (progress.failed) {
                return AppErrorView(
                  onRetry: () {
                    final cubit = context.read<ProgressCubit>();
                    if (_range == null) {
                      cubit.load(ProgressPeriod.week);
                    } else {
                      cubit.loadRange(_range!.start, _range!.end);
                    }
                  },
                );
              }
              if (weight.failed) {
                return AppErrorView(
                  onRetry: () => context.read<WeightCubit>().load(
                    rangeStart: _range?.start,
                    rangeEnd: _range?.end,
                  ),
                );
              }
              final allDays = progress.days;
              final days14 = _range == null
                  ? allDays
                  : allDays
                        .where(
                          (d) =>
                              !d.date.isBefore(_range!.start) &&
                              !d.date.isAfter(_range!.end),
                        )
                        .toList();
              final keys = days14.map((d) => d.dateKey).toSet();
              final session = context.watch<SessionCubit>().state;
              final coach = widget.coach
                  ?.forOwner(
                    session is SessionAuthenticated ? session.user.uid : null,
                  )
                  ?.forDates(keys);
              final rangeLogs = weight.logs
                  .where((w) => keys.contains(w.dateKey))
                  .toList();
              final rangeWeight = WeightState(
                logs: rangeLogs,
                activeProfile: weight.activeProfile,
              );
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final entry in <String, String>{
                          'day': l10n.localeName.startsWith('ar')
                              ? 'يومي'
                              : 'Daily',
                          'week': l10n.localeName.startsWith('ar')
                              ? 'أسبوعي'
                              : 'Weekly',
                          'month': l10n.localeName.startsWith('ar')
                              ? 'شهري'
                              : 'Monthly',
                        }.entries)
                          ChoiceChip(
                            label: Text(entry.value),
                            selected: _preset == entry.key,
                            onSelected:
                                _exporting || progress.loading || weight.loading
                                ? null
                                : (_) => _choosePreset(entry.key),
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(l10n.exportSelectRange),
                    onPressed: _exporting || progress.loading || allDays.isEmpty
                        ? null
                        : () async {
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(1970),
                              lastDate: time.clock.now(),
                              initialDateRange:
                                  _range ??
                                  DateTimeRange(
                                    start: days14.first.date,
                                    end: days14.last.date,
                                  ),
                            );
                            if (context.mounted && mounted && range != null) {
                              if (DateTime.utc(
                                        range.end.year,
                                        range.end.month,
                                        range.end.day,
                                      )
                                      .difference(
                                        DateTime.utc(
                                          range.start.year,
                                          range.start.month,
                                          range.start.day,
                                        ),
                                      )
                                      .inDays >
                                  365) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SufraSnackBar(
                                    content: Text(l10n.exportRangeLimit),
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                _range = range;
                                _preset = 'custom';
                              });
                              final nutrition = context.read<ProgressCubit>(),
                                  weights = context.read<WeightCubit>();
                              await Future.wait([
                                nutrition.loadRange(range.start, range.end),
                                weights.load(
                                  rangeStart: range.start,
                                  rangeEnd: range.end,
                                ),
                              ]);
                            }
                          },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: RepaintBoundary(
                        key: _boundaryKey,
                        child: _ReportCard(
                          days: days14,
                          weight: rangeWeight,
                          hydrationGoalMl: progress.hydrationGoalMl,
                          displayName: progress.userProfile?.displayName,
                          coach: coach,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: l10n.exportPdfButton,
                            gradient: AppColors.primaryGradient,
                            onTap:
                                _exporting || progress.loading || weight.loading
                                ? null
                                : () => _export(
                                    NutritionReportData(
                                      days: days14,
                                      coach: coach,
                                      weight: rangeWeight,
                                      l10n: l10n,
                                      hydrationGoalMl: progress.hydrationGoalMl,
                                      displayName:
                                          progress.userProfile?.displayName,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: l10n.localeName.startsWith('ar')
                                ? 'مشاركة الملف'
                                : 'Share file',
                            gradient: AppColors.copperGradient,
                            darkText: true,
                            onTap:
                                _exporting || progress.loading || weight.loading
                                ? null
                                : () => _export(
                                    NutritionReportData(
                                      days: days14,
                                      coach: coach,
                                      weight: rangeWeight,
                                      l10n: l10n,
                                      hydrationGoalMl: progress.hydrationGoalMl,
                                      displayName:
                                          progress.userProfile?.displayName,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.gradient,
    this.darkText = false,
    this.onTap,
  });

  final String label;
  final Gradient gradient;
  final bool darkText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GradientButton(
    label: label,
    onPressed: onTap,
    gradient: gradient,
    textColor: darkText ? AppColors.darkBackground : Colors.white,
    fontSize: 14,
    height: 26 + MediaQuery.textScalerOf(context).scale(20),
    borderRadius: 24,
    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
    labelAlign: TextAlign.center,
  );
}

/// The light "paper" report card (design p-Export inner card).
class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.days,
    required this.weight,
    this.hydrationGoalMl,
    this.displayName,
    this.coach,
  });

  final CoachReportSnapshot? coach;
  final List<DayNutrition> days;
  final WeightState weight;
  final double? hydrationGoalMl;
  final String? displayName;

  static const _ink = Color(0xFF0A1022);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final averages = NutritionAverages.of(days);
    final profile = weight.activeProfile;
    final tracked = averages.trackedDays;
    final adherencePct = NutritionAverages.percent(
      averages.calories,
      averages.calorieTarget,
    );
    final delta = weight.deltaKg;
    final current = weight.currentWeight;
    final target = weight.targetWeight;
    final goalLoss = (current != null && target != null)
        ? (current - target)
        : null;
    final height = profile?.heightCm;
    final bmi = (height != null && current != null && height > 0)
        ? current / ((height / 100) * (height / 100))
        : null;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFEEF3FA)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.exportTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  Text(
                    days.isEmpty
                        ? l10n.exportSubtitle
                        : '${days.first.dateKey} - ${days.last.dateKey}',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  l10n.exportPdfBadge,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (coach != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.localeName.startsWith('ar')
                  ? 'أهداف وخطوات اخترتها'
                  : 'Your chosen goals and steps',
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
            if (coach!.goals.isNotEmpty)
              Text(
                coach!
                    .goalLabels(l10n.localeName.startsWith('ar'))
                    .join(l10n.localeName.startsWith('ar') ? '، ' : ', '),
                style: const TextStyle(color: _ink),
              ),
            for (final habit in coach!.habits)
              Text(
                CoachReportSnapshot.label(
                  habit,
                  l10n.localeName.startsWith('ar'),
                ),
                style: const TextStyle(color: _ink),
              ),
            Text(
              l10n.localeName.startsWith('ar')
                  ? '${coach!.summary(true)}. تأكيدك أنت، مش تقييم للالتزام.'
                  : '${coach!.summary(false)}. Self-reported, not an adherence score.',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          _patientCard(l10n, profile, displayName, bmi, goalLoss),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final large = MediaQuery.textScalerOf(context).scale(11) > 18;
              if (large) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _statBox(
                      l10n.reportAverageCalories,
                      averages.calories == null
                          ? '—'
                          : ProgressFormat.intDigits(
                              averages.calories!,
                              locale: l10n.localeName,
                            ),
                      const Color(0xFF1565C0),
                      expanded: false,
                    ),

                    _statBox(
                      l10n.localeName.startsWith('ar')
                          ? 'السعرات مقارنة بالهدف'
                          : 'Calories vs target',
                      adherencePct == null
                          ? '—'
                          : '${ProgressFormat.intDigits(adherencePct, locale: l10n.localeName)}%',
                      const Color(0xFF16A34A),
                      expanded: false,
                    ),

                    _statBox(
                      l10n.statsWeightTitle,
                      delta == null
                          ? '—'
                          : (delta >= 0
                                ? '▼${ProgressFormat.oneDecimal(delta, locale: l10n.localeName)}'
                                : '▲${ProgressFormat.oneDecimal(-delta, locale: l10n.localeName)}'),
                      const Color(0xFFEA580C),
                      expanded: false,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  _statBox(
                    l10n.reportAverageCalories,
                    averages.calories == null
                        ? '—'
                        : ProgressFormat.intDigits(
                            averages.calories!,
                            locale: l10n.localeName,
                          ),
                    const Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 8),
                  _statBox(
                    l10n.localeName.startsWith('ar')
                        ? 'السعرات مقارنة بالهدف'
                        : 'Calories vs target',
                    adherencePct == null
                        ? '—'
                        : '${ProgressFormat.intDigits(adherencePct, locale: l10n.localeName)}%',
                    const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  _statBox(
                    l10n.statsWeightTitle,
                    delta == null
                        ? '—'
                        : (delta >= 0
                              ? '▼${ProgressFormat.oneDecimal(delta, locale: l10n.localeName)}'
                              : '▲${ProgressFormat.oneDecimal(-delta, locale: l10n.localeName)}'),
                    const Color(0xFFEA580C),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            '${l10n.exportMacrosTitle} ${l10n.exportMacrosHint}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          _macroBar(
            l10n,
            l10n.exportProteinLabel,
            averages.protein,
            averages.proteinTarget,
            const Color(0xFF06B6D4),
          ),
          const SizedBox(height: 6),
          _macroBar(
            l10n,
            l10n.exportCarbsLabel,
            averages.carbs,
            averages.carbsTarget,
            const Color(0xFFFB8C00),
          ),
          const SizedBox(height: 6),
          _macroBar(
            l10n,
            l10n.exportFatLabel,
            averages.fat,
            averages.fatTarget,
            const Color(0xFF16A34A),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.exportTrackingDays(
              ProgressFormat.intDigits(days.length, locale: l10n.localeName),
            ),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: Container(
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: day.tracked
                          ? const Color(0xFF06B6D4)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.statsCaloriesTitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '0 - ${ProgressFormat.intDigits(days.map((d) => d.calories ?? 0).fold<double>(0, (a, b) => a > b ? a : b), locale: l10n.localeName)} kcal',
              style: const TextStyle(fontSize: 10, color: _muted),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in days)
                    Expanded(
                      child: Tooltip(
                        message:
                            '${day.dateKey}: ${day.calories == null ? l10n.foodUnknown : ProgressFormat.intDigits(day.calories!, locale: l10n.localeName)}',
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          height: day.calories == null
                              ? 3
                              : (day.calories! /
                                        (days
                                            .map((d) => d.calories ?? 0)
                                            .fold<double>(
                                              1,
                                              (a, b) => a > b ? a : b,
                                            )) *
                                        58)
                                    .clamp(3, 58),
                          decoration: BoxDecoration(
                            color: day.calories == null
                                ? _line
                                : const Color(0xFF06B6D4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (days.isNotEmpty)
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    days.first.dateKey,
                    style: const TextStyle(fontSize: 9, color: _muted),
                  ),
                  Text(
                    days.last.dateKey,
                    style: const TextStyle(fontSize: 9, color: _muted),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Text(
            hydrationGoalMl == null
                ? l10n.waterGoalDefaultNote
                : l10n.waterGoalChosenNote,
            style: const TextStyle(fontSize: 10, color: _muted),
          ),
          Text(
            '${ProgressFormat.intDigits(hydrationGoalMl ?? 2000, locale: l10n.localeName)} ml',
            style: const TextStyle(fontSize: 10, color: _muted),
            textDirection: TextDirection.ltr,
          ),
          Text(
            l10n.exportLoggedWater,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final day in days.where(
                (d) => d.waterMl.isFinite && d.waterMl > 0,
              ))
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${day.dateKey}: ${ProgressFormat.intDigits(day.waterMl, locale: l10n.localeName)}',
                    style: const TextStyle(fontSize: 10, color: _muted),
                  ),
                ),
              if (!days.any((d) => d.waterMl.isFinite && d.waterMl > 0))
                Text(
                  l10n.exportNoWaterRecord,
                  style: const TextStyle(fontSize: 10, color: _muted),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.exportWeightHistory,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          if (weight.logs.isEmpty)
            Text(
              l10n.exportNoWeightHistory,
              style: const TextStyle(fontSize: 10, color: _muted),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                for (final log in weight.logs.reversed)
                  Text(
                    '${log.dateKey}: ${ProgressFormat.oneDecimal(log.weightKg, locale: l10n.localeName)}',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 10, color: _muted),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          Text(
            l10n.exportReviewPointsTitle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          ..._reviewPoints(l10n, tracked, days, averages),
          const SizedBox(height: 10),
          Text(
            l10n.progressUnknownNote,
            style: const TextStyle(fontSize: 10, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _patientCard(
    AppLocalizations l10n,
    NutritionProfileModel? profile,
    String? name,
    double? bmi,
    double? goalLoss,
  ) {
    final displayName = (name == null || name.isEmpty) ? '—' : name;
    final dob = profile?.dateOfBirth;
    final now = time.clock.now();
    final age = dob == null
        ? null
        : now.year -
              dob.year -
              ((now.month < dob.month ||
                      (now.month == dob.month && now.day < dob.day))
                  ? 1
                  : 0);
    final height = profile?.heightCm;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, size: 36, color: Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    displayName,
                    if (age != null)
                      l10n.exportYearsOld(
                        ProgressFormat.intDigits(age, locale: l10n.localeName),
                      ),
                    if (height != null)
                      l10n.exportCmLabel(
                        ProgressFormat.intDigits(
                          height,
                          locale: l10n.localeName,
                        ),
                      ),
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12, color: _ink),
                ),
                Text(
                  [
                    if (goalLoss != null && goalLoss > 0)
                      l10n.exportGoalLoss(
                        ProgressFormat.oneDecimal(
                          goalLoss,
                          locale: l10n.localeName,
                        ),
                      ),
                    if (bmi != null)
                      l10n.exportBmiLabel(
                        ProgressFormat.oneDecimal(bmi, locale: l10n.localeName),
                      ),
                  ].join(' · '),
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(
    String label,
    String value,
    Color color, {
    bool expanded = true,
  }) {
    final number = Text(
      value,
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontFamily: AppTheme.displayFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
    final box = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _muted)),
          if (expanded)
            FittedBox(fit: BoxFit.scaleDown, child: number)
          else
            number,
        ],
      ),
    );
    return expanded
        ? Expanded(child: box)
        : Padding(padding: const EdgeInsets.only(bottom: 8), child: box);
  }

  Widget _macroBar(
    AppLocalizations l10n,
    String label,
    double? avg,
    double? target,
    Color color,
  ) {
    final pct = NutritionAverages.percent(avg, target);
    return Row(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Text(
            label,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: const TextStyle(fontSize: 12, color: _ink),
          ),
        ),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LayoutBuilder(
              builder: (context, c) {
                final ratio = pct == null ? null : pct / 100;
                final scale = ratio == null || ratio <= 1.2 ? 1.2 : ratio;
                return SizedBox(
                  height: 12,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _line,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                      if (ratio != null)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: c.maxWidth * (ratio / scale).clamp(0, 1),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      if (target != null && target > 0)
                        Positioned(
                          left: (c.maxWidth / scale).clamp(0, c.maxWidth - 2),
                          top: 0,
                          bottom: 0,
                          width: 2,
                          child: const ColoredBox(color: _ink),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: Text(
            pct == null
                ? '—'
                : '${ProgressFormat.intDigits(pct, locale: l10n.localeName)}%',
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.end,
            softWrap: false,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: AppTheme.displayFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: _ink,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _reviewPoints(
    AppLocalizations l10n,
    int trackedDays,
    List<DayNutrition> days,
    NutritionAverages averages,
  ) {
    final points = <Widget>[];
    // Rule-derived, data-backed review points only.
    var sodiumStreak = 0;
    var maxSodiumStreak = 0;
    final sodiumValues = days
        .where((d) => d.tracked && d.sodium != null)
        .map((d) => d.sodium!)
        .toList();
    if (sodiumValues.length >= 4) {
      final mean = sodiumValues.reduce((a, b) => a + b) / sodiumValues.length;
      for (final d in days) {
        final s = d.sodium;
        if (d.tracked && s != null && s > mean * 1.25) {
          sodiumStreak++;
          if (sodiumStreak > maxSodiumStreak) maxSodiumStreak = sodiumStreak;
        } else {
          sodiumStreak = 0;
        }
      }
    }
    if (maxSodiumStreak >= 3) {
      points.add(_reviewDot(const Color(0xFFEF4444), l10n.exportReviewSodium));
    }
    final waterOk =
        hydrationGoalMl != null &&
        days.isNotEmpty &&
        days.last.waterMl >= hydrationGoalMl!;
    if (waterOk) {
      points.add(_reviewDot(const Color(0xFF22C55E), l10n.exportReviewWaterOk));
    }
    if (points.isEmpty) {
      points.add(
        const Text('—', style: TextStyle(fontSize: 12, color: _muted)),
      );
    }
    return points;
  }

  Widget _reviewDot(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12, color: _ink)),
        ],
      ),
    );
  }
}
