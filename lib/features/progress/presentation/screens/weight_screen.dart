import '../../../../core/utils/decimal_input.dart';
import '../../../../data/models/nutrition_profile_model.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import '../../../../data/models/weight_log_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../widgets/goal_ring.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../data/water_weight_repository.dart';
import '../cubit/weight_cubit.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

import '../progress_format.dart';
import '../widgets/weight_journey.dart';

/// Screen — وزنك (design p-Weight): current weight + goal ring, journey
/// path toward the target, weekly logging dots and the log-today CTA.
/// Not part of the HTML bottom nav; reached by push navigation.
class WeightScreen extends StatelessWidget {
  const WeightScreen({super.key, this.waterWeightRepository});

  static const String routePath = '/weight';

  final WaterWeightRepository? waterWeightRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
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
        )..load();
      },
      child: const _WeightView(),
    );
  }
}

class _WeightView extends StatelessWidget {
  const _WeightView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: BlocBuilder<WeightCubit, WeightState>(
            builder: (context, state) {
              if (state.loading) return const AppLoadingView();
              if (state.failed && state.logs.isEmpty) {
                return AppErrorView(
                  onRetry: () => context.read<WeightCubit>().retryOrLoad(),
                );
              }
              return _WeightContent(state: state);
            },
          ),
        ),
      ),
    );
  }
}

class _WeightContent extends StatelessWidget {
  const _WeightContent({required this.state});

  final WeightState state;

  Future<void> _editGoal(BuildContext context) async {
    final cubit = context.read<WeightCubit>();
    final profile = cubit.state.activeProfile;
    if (profile == null) return;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final controller = TextEditingController(
      text: profile.targetWeightKg.toString(),
    );
    var goal = profile.nutritionGoal;
    NutritionProfileModel? preview;
    String? error;
    final route = DialogRoute<NutritionProfileModel>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => SufraAlertDialog(
          title: Text(
            ar ? 'هدفك ووزنك' : 'Your goal and weight',
            style: context.readableDisplayStyle(size: 22),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ar
                      ? 'آخر وزن مسجل: ${cubit.state.currentWeight} كجم. الحفظ يحدّث أهداف التغذية، ومش بيمسح سجلات الوزن القديمة.'
                      : 'Latest weight: ${cubit.state.currentWeight} kg. Saving updates nutrition targets, never past weight logs.',
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: goal,
                  isExpanded: true,
                  items: [
                    for (final v in ['lose', 'maintain', 'gain'])
                      DropdownMenuItem(
                        value: v,
                        child: Text(
                          ar
                              ? {
                                  'lose': 'أنزّل وزني',
                                  'maintain': 'أثبت وزني',
                                  'gain': 'أزوّد وزني',
                                }[v]!
                              : v,
                        ),
                      ),
                  ],
                  onChanged: (v) => setDialog(() {
                    goal = v!;
                    preview = null;
                    error = null;
                  }),
                ),
                TextField(
                  key: const ValueKey('goal-target'),
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: ar
                        ? 'الوزن المستهدف بالكيلو'
                        : 'Target weight in kg',
                  ),
                  onChanged: (_) => setDialog(() {
                    preview = null;
                    error = null;
                  }),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: const TextStyle(color: AppColors.orangeLight),
                  ),
                if (preview != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      ar
                          ? 'معاينة تقديرية: ${preview!.dailyCalorieTarget.round()} سعر يوميًا. الحساب بالمعادلة الموجودة في التطبيق، مش توصية طبية.'
                          : 'Estimated preview: ${preview!.dailyCalorieTarget.round()} kcal/day. Calculated by the existing app formula, not medical advice.',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(ar ? 'إلغاء' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (preview != null) {
                  Navigator.pop(context, preview);
                  return;
                }
                try {
                  final number = parseDecimalInput(controller.text);
                  if (number == null) throw StateError('Invalid');
                  setDialog(() {
                    preview = cubit.previewGoal(number, goal);
                    error = null;
                  });
                } catch (_) {
                  setDialog(
                    () => error = ar
                        ? 'راجع الوزن واتجاه الهدف. السن الأقل من 18 أو القيود الصحية تحتاج مراجعة مختص.'
                        : 'Check target and goal direction. Minors or health restrictions need professional review.',
                  );
                }
              },
              child: Text(
                preview == null
                    ? (ar ? 'معاينة' : 'Preview')
                    : (ar ? 'احفظ الهدف' : 'Save goal'),
              ),
            ),
          ],
        ),
      ),
    );
    final selected = await Navigator.of(context).push(route);
    await route.completed;
    controller.dispose();
    if (selected == null || !context.mounted) return;
    final saved = await cubit.saveGoal(selected);
    if (!context.mounted) return;
    if (saved) {
      final session = context.read<SessionCubit>().state;
      if (session is SessionAuthenticated) {
        try {
          await context.read<HomeCubit>().load(session.user.uid);
        } catch (_) {}
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SufraSnackBar(
          content: Text(
            saved
                ? (ar ? 'اتحفظ الهدف' : 'Goal saved')
                : (ar
                      ? 'الحفظ ما اتأكدش. جرّب تاني.'
                      : 'Save not confirmed. Try again.'),
          ),
        ),
      );
    }
  }

  Future<void> _logWeight(
    BuildContext context, {
    WeightLogModel? existing,
  }) async {
    final cubit = context.read<WeightCubit>();
    final controller = TextEditingController(
      text: existing?.weightKg.toString(),
    );
    var recordedAt = existing?.recordedAt ?? DateTime.now();
    final route = DialogRoute<double>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return SufraAlertDialog(
          title: Text(
            l10n.weightLogTitle,
            style: context.readableDisplayStyle(size: 22),
          ),
          content: StatefulBuilder(
            builder: (context, setDialog) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9٠-٩۰-۹.٫,]'),
                    ),
                  ],
                  decoration: InputDecoration(hintText: l10n.weightLogHint),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(recordedAt.toIso8601String().substring(0, 10)),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1970),
                      lastDate: DateTime.now(),
                      initialDate: recordedAt,
                    );
                    if (d != null && context.mounted) {
                      setDialog(
                        () => recordedAt = DateTime(d.year, d.month, d.day, 12),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final value = parseDecimalInput(controller.text);
                if (value == null ||
                    !value.isFinite ||
                    value <= 0 ||
                    value > 1000) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SufraSnackBar(content: Text(l10n.weightLogInvalid)),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              child: Text(l10n.weightLogSave),
            ),
          ],
        );
      },
    );
    final saved = await Navigator.of(context).push(route);
    await route.completed;
    controller.dispose();
    if (saved != null) {
      if (existing == null) {
        await cubit.addWeight(saved, recordedAt: recordedAt);
      } else {
        await cubit.changeRecord(
          WeightLogModel(
            weightId: existing.weightId,
            weightKg: saved,
            recordedAt: recordedAt,
            dateKey: recordedAt.toIso8601String().substring(0, 10),
            note: existing.note,
            createdAt: existing.createdAt,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = state.currentWeight;
    final target = state.targetWeight;
    final delta = state.deltaKg;
    final hasBaseline =
        state.logs.length >= 2 &&
        state.logs.first.recordedAt.isAfter(state.logs.last.recordedAt);
    final fraction = hasBaseline ? state.goalFraction : null;
    final remaining = (current != null && target != null)
        ? (current - target).abs()
        : null;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.weightScreenTitle,
                      style: context.readableDisplayStyle(size: 28),
                    ),
                    Text(l10n.weightSubtitle, style: context.mutedStyle()),
                    if (state.activeProfile != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: state.saving
                              ? null
                              : () => _editGoal(context),
                          icon: const Icon(Icons.flag_outlined),
                          label: Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? 'عدّل هدفك'
                                : 'Edit your goal',
                          ),
                        ),
                      ),
                    if (state.failed)
                      TextButton.icon(
                        onPressed: () =>
                            context.read<WeightCubit>().retryOrLoad(),
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.stateRetry),
                      ),
                    const SizedBox(height: 12),
                    GlassCard(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x4D4ADE80), Color(0x1F06B6D4)],
                      ),
                      child: Builder(
                        builder: (context) {
                          final compact =
                              constraints.maxWidth < 360 ||
                              MediaQuery.textScalerOf(context).scale(13) > 19;
                          final ring = GoalRing(
                            fraction: fraction ?? 0,
                            size: 132,
                            strokeWidth: 12,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    fraction == null
                                        ? '—'
                                        : '${ProgressFormat.intDigits(fraction * 100, locale: l10n.localeName)}%',
                                    style: context.displayStyle(size: 26),
                                  ),
                                  Text(
                                    fraction == null
                                        ? ''
                                        : l10n.weightProgressBaselineLabel,
                                    style: context.mutedStyle(size: 11),
                                  ),
                                ],
                              ),
                            ),
                          );
                          final info = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.weightCurrent,
                                style: context.mutedStyle(size: 13),
                              ),
                              if (current != null)
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            '${ProgressFormat.oneDecimal(current, locale: l10n.localeName)} ',
                                        style: context.displayStyle(size: 40),
                                      ),
                                      TextSpan(
                                        text: l10n.weightKg,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  l10n.statsNoWeightData,
                                  style: context.mutedStyle(size: 13),
                                ),
                              if (delta != null && delta != 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: delta > 0
                                        ? AppColors.greenLight
                                        : AppColors.pinkLight,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        delta > 0
                                            ? Icons.arrow_downward_rounded
                                            : Icons.arrow_upward_rounded,
                                        size: 14,
                                        color: AppColors.darkBackground,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          (delta > 0
                                                  ? l10n.weightLighterBy(
                                                      ProgressFormat.oneDecimal(
                                                        delta,
                                                        locale: l10n.localeName,
                                                      ),
                                                    )
                                                  : l10n.weightHeavierBy(
                                                      ProgressFormat.oneDecimal(
                                                        -delta,
                                                        locale: l10n.localeName,
                                                      ),
                                                    ))
                                              .replaceFirst(
                                                RegExp(r'^[▼▲]\s*'),
                                                '',
                                              ),
                                          style: const TextStyle(
                                            color: AppColors.darkBackground,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                          return compact
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Center(child: ring),
                                    const SizedBox(height: 14),
                                    info,
                                  ],
                                )
                              : Row(
                                  children: [
                                    ring,
                                    const SizedBox(width: 14),
                                    Expanded(child: info),
                                  ],
                                );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            fraction == null
                                ? l10n.weightHistoryNeeded
                                : l10n.weightLoadedProgress,
                            style: context.mutedStyle(size: 13),
                          ),
                          if (fraction != null) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 14,
                              runSpacing: 8,
                              children: [
                                for (final pair in [
                                  (
                                    const Color(0xFFFB8C00),
                                    l10n.weightBaselineDetail(
                                      ProgressFormat.oneDecimal(
                                        state.logs.last.weightKg,
                                        locale: l10n.localeName,
                                      ),
                                      '\u2066${state.logs.last.dateKey}\u2069',
                                    ),
                                  ),
                                  (
                                    const Color(0xFF06B6D4),
                                    l10n.weightCurrentDetail(
                                      ProgressFormat.oneDecimal(
                                        current!,
                                        locale: l10n.localeName,
                                      ),
                                    ),
                                  ),
                                  (
                                    const Color(0xFFFDBA74),
                                    l10n.weightTargetDetail(
                                      ProgressFormat.oneDecimal(
                                        target!,
                                        locale: l10n.localeName,
                                      ),
                                    ),
                                  ),
                                ])
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 12,
                                        color: pair.$1,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          pair.$2,
                                          style: context.mutedStyle(size: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            ExcludeSemantics(
                              child: WeightJourney(
                                fraction: fraction,
                                currentLabel: '',
                                goalLabel: '',
                                hereLabel: '',
                              ),
                            ),
                          ] else ...[
                            if (current != null)
                              Text(
                                l10n.weightCurrentDetail(
                                  ProgressFormat.oneDecimal(
                                    current,
                                    locale: l10n.localeName,
                                  ),
                                ),
                                style: context.mutedStyle(size: 13),
                              ),
                            if (target != null)
                              Text(
                                l10n.weightTargetDetail(
                                  ProgressFormat.oneDecimal(
                                    target,
                                    locale: l10n.localeName,
                                  ),
                                ),
                                style: context.mutedStyle(size: 13),
                              ),
                            const SizedBox(height: 16),
                            Icon(
                              Icons.monitor_weight_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x59FB8C00), Color(0x0AFFFFFF)],
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 76),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 34,
                              color: AppColors.orangeLight,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'ar'
                                        ? 'متابعتك ليها قيمة'
                                        : 'Your check-ins matter',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    remaining == null
                                        ? l10n.weightSubtitle
                                        : l10n.weightToNextMilestone(
                                            ProgressFormat.oneDecimal(
                                              remaining,
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
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (var i = 0; i < 7; i++)
                          Expanded(
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              child: Column(
                                children: [
                                  Text(
                                    i < state.weekDates.length
                                        ? weekdayLetter(
                                            l10n,
                                            state.weekDates[i],
                                          )
                                        : '',
                                    style: context.mutedStyle(size: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          i < state.weekLogged.length &&
                                              state.weekLogged[i]
                                          ? AppColors.greenLight
                                          : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.25),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(height: 6),
                    GradientButton(
                      label: l10n.weightLogCta,
                      onPressed: state.saving
                          ? null
                          : () => _logWeight(context),
                      height:
                          26 +
                          MediaQuery.textScalerOf(context).scale(24) +
                          (MediaQuery.textScalerOf(context).scale(24) > 36
                              ? 34
                              : 0),
                      fontSize: 18,
                      borderRadius: 99,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      labelAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (state.logs.isNotEmpty)
              ExpansionTile(
                title: Text(l10n.exportWeightHistory),
                children: [
                  for (final log in state.logs)
                    ListTile(
                      title: Text(
                        '${ProgressFormat.oneDecimal(log.weightKg, locale: l10n.localeName)} ${l10n.unitKg}',
                        textDirection: TextDirection.ltr,
                      ),
                      subtitle: FittedBox(
                        alignment: AlignmentDirectional.centerStart,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          log.dateKey,
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                      trailing: context.read<WeightCubit>().canEditRecords
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: l10n.mealEdit,
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: state.saving
                                      ? null
                                      : () =>
                                            _logWeight(context, existing: log),
                                ),
                                IconButton(
                                  tooltip: l10n.mealDelete,
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: state.saving
                                      ? null
                                      : () async {
                                          final cubit = context
                                              .read<WeightCubit>();
                                          final yes = await showSufraDialog<bool>(
                                            context: context,
                                            builder: (c) => SufraAlertDialog(
                                              title: Text(
                                                l10n.mealDelete,
                                                style: context
                                                    .readableDisplayStyle(
                                                      size: 20,
                                                    ),
                                              ),
                                              content: Text(
                                                '${log.dateKey} · ${log.weightKg} ${l10n.unitKg}',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(c, false),
                                                  child: Text(
                                                    l10n.actionCancel,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(c, true),
                                                  child: Text(l10n.mealDelete),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (yes == true) {
                                            await cubit.changeRecord(
                                              log,
                                              delete: true,
                                            );
                                          }
                                        },
                                ),
                              ],
                            )
                          : null,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
