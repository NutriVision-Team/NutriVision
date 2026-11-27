import 'package:flutter/services.dart';
import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../data/repositories/nutrition_repository.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../data/water_weight_repository.dart';
import '../cubit/water_cubit.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

import '../progress_format.dart';
import '../widgets/progress_nav.dart';
import '../widgets/water_glass.dart';

/// Screen — مية النهاردة (design p-Water): animated glass, quick-add
/// buttons, custom slider and the trailing-week intake bars. The HTML's
/// weather-based "+200 ml hot day" note has no data source and is
/// intentionally not rendered until such a contract exists.
class WaterScreen extends StatelessWidget {
  const WaterScreen({super.key, this.waterWeightRepository});

  static const String routePath = '/water';

  /// Test injection point. Production wiring defaults to the Firestore
  /// store; the lead may instead register a RepositoryProvider.
  final WaterWeightRepository? waterWeightRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final session = context.read<SessionCubit>().state;
        final uid = session is SessionAuthenticated ? session.user.uid : '';
        return WaterCubit(
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
      child: const _WaterView(),
    );
  }
}

class _WaterView extends StatelessWidget {
  const _WaterView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: MediaQuery.textScalerOf(context).scale(11) <= 15,
      body: NebulaBackground(
        child: SafeArea(
          child: BlocBuilder<WaterCubit, WaterState>(
            builder: (context, state) {
              if (state.loading && state.entries.isEmpty) {
                return const AppLoadingView();
              }
              if (state.failed && state.entries.isEmpty) {
                return AppErrorView(
                  onRetry: () => context.read<WaterCubit>().retryOrLoad(),
                );
              }
              return _WaterContent(state: state);
            },
          ),
        ),
      ),
      bottomNavigationBar: const ProgressNavBar(currentIndex: 2),
    );
  }
}

class _WaterContent extends StatelessWidget {
  const _WaterContent({required this.state});

  final WaterState state;

  Future<void> _chooseGoal(BuildContext context) async {
    final cubit = context.read<WaterCubit>(), l = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: state.goalMl.toStringAsFixed(0),
    );
    final route = DialogRoute<double>(
      context: context,
      builder: (c) => SufraAlertDialog(
        title: Text(l.waterGoalChoose),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.waterGoalLocalHint),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  suffixText: Localizations.localeOf(c).languageCode == 'ar'
                      ? 'مل'
                      : 'ml',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value == null ||
                  !value.isFinite ||
                  value <= 0 ||
                  value > 20000) {
                ScaffoldMessenger.of(c).showSnackBar(
                  SufraSnackBar(content: Text(l.waterGoalInvalid)),
                );
                return;
              }
              Navigator.pop(c, value);
            },
            child: Text(l.weightLogSave),
          ),
        ],
      ),
    );
    final value = await Navigator.of(context).push(route);
    await route.completed;
    controller.dispose();
    if (value == null || !context.mounted) return;
    try {
      await cubit.chooseGoal(value);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SufraSnackBar(content: Text(l.stateRetry)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Text(
          l10n.waterScreenTitle,
          style: context.readableDisplayStyle(size: 28),
        ),
        if (state.failed)
          TextButton.icon(
            onPressed: () => context.read<WaterCubit>().retryOrLoad(),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.stateRetry),
          ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 236,
            child: WaterGlass(fraction: state.fraction),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              l10n.waterCupsOf(
                ProgressFormat.intDigits(
                  state.goalCups.round(),
                  locale: l10n.localeName,
                ),
                ProgressFormat.intDigits(
                  state.cups.floor(),
                  locale: l10n.localeName,
                ),
              ),
              textAlign: TextAlign.center,
              style: context.readableDisplayStyle(size: 30),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.waterMlOf(
                ProgressFormat.intDigits(state.goalMl, locale: l10n.localeName),
                ProgressFormat.intDigits(
                  state.totalMl,
                  locale: l10n.localeName,
                ),
              ),
              style: context.mutedStyle(size: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: LinearProgressIndicator(
                value: state.fraction,
                minHeight: 8,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(AppColors.turquoise),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const _AddButtons(),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            state.goalChosen
                ? l10n.waterGoalChosenNote
                : l10n.waterGoalDefaultNote,
            style: context.mutedStyle(size: 12),
          ),
        ),
        const SizedBox(height: 8),
        _WeekBars(
          weekMl: state.weekMl,
          weekDates: state.weekDates,
          goalMl: state.goalMl,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: state.saving ? null : () => _chooseGoal(context),
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.waterGoalChoose),
        ),
        TextButton.icon(
          onPressed: () => context.push('/reminders'),
          icon: const Icon(Icons.notifications_outlined),
          label: Text(l10n.remindersTitle),
        ),
      ],
    );
  }
}

class _AddButtons extends StatefulWidget {
  const _AddButtons();

  @override
  State<_AddButtons> createState() => _AddButtonsState();
}

class _AddButtonsState extends State<_AddButtons> {
  bool _customOpen = false;
  double _customMl = 150;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WaterCubit>();
    final saving = context.watch<WaterCubit>().state.saving;
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _WaterButton(
              label: l10n.waterAdd250,
              filled: true,
              onTap: saving ? null : () => cubit.addWater(250),
            ),
            _WaterButton(
              label: l10n.waterAdd500,
              filled: true,
              onTap: saving ? null : () => cubit.addWater(500),
            ),
            _WaterButton(
              label: l10n.waterAddCustom,
              onTap: () => setState(() => _customOpen = !_customOpen),
            ),
          ],
        ),
        if (_customOpen) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Slider(
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  value: _customMl,
                  onChanged: (v) => setState(() => _customMl = v),
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  l10n.waterMlValue(
                    ProgressFormat.intDigits(
                      _customMl,
                      locale: l10n.localeName,
                    ),
                  ),
                  style: context.mutedStyle(size: 13),
                ),
              ),
              _WaterButton(
                label: l10n.waterAddConfirm,
                onTap: saving ? null : () => cubit.addWater(_customMl),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WaterButton extends StatelessWidget {
  const _WaterButton({required this.label, this.onTap, this.filled = false});

  final String label;
  final VoidCallback? onTap;

  /// Design: quick-add buttons are solid cyan with dark text and a cyan
  /// glow; the custom toggle stays translucent.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: filled
            ? AppColors.cyanLight
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          borderRadius: BorderRadius.circular(99),
          child: IntrinsicWidth(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: filled
                    ? null
                    : Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.18),
                      ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF06B6D4,
                          ).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: filled
                      ? const Color(0xFF0A1022)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({
    required this.weekMl,
    required this.weekDates,
    required this.goalMl,
  });
  final List<double> weekMl;
  final List<String> weekDates;
  final double goalMl;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.waterWeekRecordedTitle,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.textScalerOf(context).scale(11) > 15
                  ? weekMl.length * 108.0
                  : MediaQuery.sizeOf(context).width - 64,
              child: SizedBox(
                height: MediaQuery.textScalerOf(context).scale(11) > 15
                    ? 156
                    : 118,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var i = 0; i < weekMl.length; i++)
                      Builder(
                        builder: (context) {
                          final date = i < weekDates.length
                              ? DateTime.tryParse(weekDates[i])
                              : null;
                          final day = date == null ? '' : weekdayName(l, date);
                          final amount = l.waterMlValue(
                            ProgressFormat.intDigits(
                              weekMl[i],
                              locale: l.localeName,
                            ),
                          );
                          return Semantics(
                            label: day,
                            value: amount,
                            child: Tooltip(
                              message: '$day: $amount',
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: 92,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: _WeekBar(
                                        fraction: goalMl > 0
                                            ? (weekMl[i] / goalMl).clamp(0, 1)
                                            : 0,
                                        delay: Duration(milliseconds: 100 * i),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(day, style: context.mutedStyle(size: 9)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({required this.fraction, required this.delay});
  final double fraction;
  final Duration delay;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction),
      duration: reduced ? Duration.zero : const Duration(seconds: 1) + delay,
      curve: reduced
          ? Curves.linear
          : Interval(
              delay.inMilliseconds / (1000 + delay.inMilliseconds),
              1,
              curve: Curves.easeOut,
            ),
      builder: (context, value, _) => Container(
        width: 26,
        height: value > 0 ? 92 * value : 3,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(13),
            bottom: Radius.circular(4),
          ),
          color: fraction == 0
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .18)
              : null,
          gradient: fraction == 0
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.cyanLight, AppColors.primaryBlue],
                ),
        ),
      ),
    );
  }
}
