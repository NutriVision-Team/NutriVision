import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sufradepi/core/widgets/sufra_button_response.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../core/widgets/sprite_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../cubit/profile_setup_cubit.dart';

/// Screen 06 — Seven-step personal setup wizard.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  static const String routePath = '/setup';

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final data = context.read<ProfileSetupCubit>().state.data;
    _heightController.text = data.heightCm?.toStringAsFixed(0) ?? '';
    _weightController.text = data.currentWeightKg?.toStringAsFixed(0) ?? '';
    _targetController.text = data.targetWeightKg?.toStringAsFixed(0) ?? '';
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ProfileSetupCubit>();
    final session = context.read<SessionCubit>().state;
    if (session is! SessionAuthenticated) return;
    final plan = await cubit.finish(session.user.uid);
    if (!mounted) return;
    final current = context.read<SessionCubit>().state;
    if (current is! SessionAuthenticated ||
        current.user.uid != session.user.uid) {
      return;
    }
    if (plan != null) {
      await context.read<SessionCubit>().refreshProfile();
      if (mounted) context.go('/plan');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SufraSnackBar(content: Text(l10n.stateError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
      builder: (context, state) {
        final cubit = context.read<ProfileSetupCubit>();
        final saving = state.status is SetupSaving;
        final isLast = state.step == ProfileSetupState.totalSteps - 1;
        return Scaffold(
          body: NebulaBackground(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  state.step == 6 ? 36 : 20,
                  16,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.wizardStepOf(
                            state.step + 1,
                            ProfileSetupState.totalSteps,
                          ),
                          style: context.mutedStyle(),
                        ),
                        SufraControlFeedback(
                          radius: 8,
                          overlay: true,
                          child: GestureDetector(
                            onTap: state.step > 0 ? cubit.back : null,
                            child: Text(
                              l10n.wizardBack,
                              style: context.mutedStyle().copyWith(
                                color: state.step > 0
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var i = 0; i < ProfileSetupState.totalSteps; i++)
                          Expanded(
                            child: Container(
                              height: 7,
                              margin: const EdgeInsetsDirectional.only(end: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                color: i <= state.step
                                    ? AppColors.turquoise
                                    : Colors.white.withValues(alpha: 0.18),
                                boxShadow: i <= state.step
                                    ? [
                                        BoxShadow(
                                          color: AppColors.turquoise.withValues(
                                            alpha: 0.7,
                                          ),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: AnimatedSwitcher(
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [...previous, if (current != null) current],
                        ),
                        duration: const Duration(milliseconds: 300),
                        child: KeyedSubtree(
                          key: ValueKey(state.step),
                          child: _StepContent(
                            step: state.step,
                            data: state.data,
                            heightController: _heightController,
                            weightController: _weightController,
                            targetController: _targetController,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GradientButton(
                      label: isLast ? l10n.wizardFinish : l10n.wizardNext,
                      isLoading: saving,
                      onPressed: cubit.canAdvance
                          ? (isLast ? _finish : cubit.next)
                          : null,
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

class _StepContent extends StatelessWidget {
  const _StepContent({
    required this.step,
    required this.data,
    required this.heightController,
    required this.weightController,
    required this.targetController,
  });

  final int step;
  final ProfileSetupData data;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController targetController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ProfileSetupCubit>();

    switch (step) {
      case 0:
        return _StepScaffold(
          title: l10n.wizardGenderTitle,
          body: l10n.wizardGenderBody,
          child: Column(
            children: [
              _OptionCard(
                title: l10n.wizardGenderMale,
                icon: Icons.male_rounded,
                accent: AppColors.cyanLight,
                selected: data.gender == 'male',
                onTap: () => cubit.update(data.copyWith(gender: 'male')),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                title: l10n.wizardGenderFemale,
                icon: Icons.female_rounded,
                accent: AppColors.pinkLight,
                selected: data.gender == 'female',
                onTap: () => cubit.update(data.copyWith(gender: 'female')),
              ),
            ],
          ),
        );
      case 1:
        return _StepScaffold(
          title: l10n.wizardDobTitle,
          body: l10n.wizardDobBody,
          child: GlassCard(
            borderColor: AppColors.orangeLight.withValues(alpha: .5),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: data.dateOfBirth ?? DateTime(now.year - 25),
                firstDate: DateTime(now.year - 100),
                lastDate: now,
              );
              if (picked != null) {
                cubit.update(data.copyWith(dateOfBirth: picked));
              }
            },
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                const Icon(Icons.cake_outlined, color: AppColors.gold),
                Text(
                  data.dateOfBirth == null
                      ? '—'
                      : '${data.dateOfBirth!.year}/${data.dateOfBirth!.month.toString().padLeft(2, '0')}/${data.dateOfBirth!.day.toString().padLeft(2, '0')}',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: context.displayStyle(size: 22),
                ),
              ],
            ),
          ),
        );
      case 2:
        return _NumberStep(
          title: l10n.wizardHeightTitle,
          body: l10n.wizardHeightBody,
          unit: l10n.unitCm,
          controller: heightController,
          onChanged: (v) => cubit.update(
            data.copyWith(
              heightCm: double.tryParse(v),
              clearHeight: double.tryParse(v) == null,
            ),
          ),
        );
      case 3:
        return _NumberStep(
          title: l10n.wizardWeightTitle,
          body: l10n.wizardWeightBody,
          unit: l10n.unitKg,
          controller: weightController,
          onChanged: (v) => cubit.update(
            data.copyWith(
              currentWeightKg: double.tryParse(v),
              clearCurrentWeight: double.tryParse(v) == null,
            ),
          ),
        );
      case 4:
        return _NumberStep(
          title: l10n.wizardTargetTitle,
          body: l10n.wizardTargetBody,
          unit: l10n.unitKg,
          controller: targetController,
          onChanged: (v) => cubit.update(
            data.copyWith(
              targetWeightKg: double.tryParse(v),
              clearTargetWeight: double.tryParse(v) == null,
            ),
          ),
        );
      case 5:
        return _StepScaffold(
          title: l10n.wizardActivityTitle,
          body: l10n.wizardActivityBody,
          child: Column(
            children: [
              _OptionCard(
                title: l10n.activitySedentary,
                subtitle: l10n.activitySedentaryBody,
                icon: Icons.weekend_outlined,
                accent: AppColors.purpleLight,
                selected: data.activityLevel == 'sedentary',
                onTap: () =>
                    cubit.update(data.copyWith(activityLevel: 'sedentary')),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                title: l10n.activityLight,
                subtitle: l10n.activityLightBody,
                icon: Icons.directions_walk_rounded,
                accent: AppColors.cyanLight,
                selected: data.activityLevel == 'light',
                onTap: () =>
                    cubit.update(data.copyWith(activityLevel: 'light')),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                title: l10n.activityModerate,
                subtitle: l10n.activityModerateBody,
                icon: Icons.directions_run_rounded,
                accent: AppColors.greenLight,
                selected: data.activityLevel == 'moderate',
                onTap: () =>
                    cubit.update(data.copyWith(activityLevel: 'moderate')),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                title: l10n.activityActive,
                subtitle: l10n.activityActiveBody,
                icon: Icons.fitness_center_rounded,
                accent: AppColors.orangeLight,
                selected: data.activityLevel == 'active',
                onTap: () =>
                    cubit.update(data.copyWith(activityLevel: 'active')),
              ),
            ],
          ),
        );
      case 6:
      default:
        return _StepScaffold(
          title: l10n.wizardGoalTitle,
          body: l10n.wizardGoalBody,
          child: Column(
            children: [
              const _GoalFoodOrbit(),
              _GoalCard(
                title: l10n.goalLose,
                subtitle: l10n.goalLoseBody,
                accent: AppColors.greenLight,
                col: 2,
                row: 3,
                selected: data.nutritionGoal == 'lose',
                onTap: () => cubit.update(data.copyWith(nutritionGoal: 'lose')),
              ),
              const SizedBox(height: 10),
              _GoalCard(
                title: l10n.goalMaintain,
                subtitle: l10n.goalMaintainBody,
                accent: AppColors.cyanLight,
                col: 1,
                row: 2,
                selected: data.nutritionGoal == 'maintain',
                onTap: () =>
                    cubit.update(data.copyWith(nutritionGoal: 'maintain')),
              ),
              const SizedBox(height: 10),
              _GoalCard(
                title: l10n.goalGain,
                subtitle: l10n.goalGainBody,
                accent: AppColors.orangeLight,
                col: 0,
                row: 0,
                selected: data.nutritionGoal == 'gain',
                onTap: () => cubit.update(data.copyWith(nutritionGoal: 'gain')),
              ),
            ],
          ),
        );
    }
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.body,
    required this.child,
  });

  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.displayStyle(size: 30)),
          const SizedBox(height: 4),
          Text(body, style: context.mutedStyle()),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _NumberStep extends StatelessWidget {
  const _NumberStep({
    required this.title,
    required this.body,
    required this.unit,
    required this.controller,
    required this.onChanged,
  });

  final String title;
  final String body;
  final String unit;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: title,
      body: body,
      child: GlassCard(
        borderColor: AppColors.orangeLight.withValues(alpha: .5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IntrinsicWidth(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: context.displayStyle(size: 40),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: '—',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(unit, style: context.mutedStyle(size: 16)),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      gradient: selected
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.5),
                Colors.white.withValues(alpha: 0.04),
              ],
            )
          : null,
      borderColor: selected
          ? accent.withValues(alpha: 0.8)
          : AppColors.orangeLight.withValues(alpha: .4),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
            ),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? accent : Colors.white.withValues(alpha: 0.2),
            ),
            child: selected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }
}

/// The designed goal cards keep their own gradient background per option.
class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.col,
    required this.row,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final int col, row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: selected ? 0.5 : 0.22),
          Colors.white.withValues(alpha: 0.04),
        ],
      ),
      borderColor: selected
          ? accent
          : AppColors.orangeLight.withValues(alpha: .4),
      child: Row(
        children: [
          SpriteAvatar(
            asset: 'assets/images/art/spA.webp',
            col: col,
            row: row,
            size: 54,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: selected ? 1 : 0.3,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : Colors.white.withValues(alpha: 0.2),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Six original source dishes orbit without changing goal selection or data.
class _GoalFoodOrbit extends StatefulWidget {
  const _GoalFoodOrbit();
  @override
  State<_GoalFoodOrbit> createState() => _GoalFoodOrbitState();
}

class _GoalFoodOrbitState extends State<_GoalFoodOrbit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _rotation.stop();
      _rotation.value = 0;
    } else {
      _rotation.repeat();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 198,
    child: LayoutBuilder(
      builder: (context, bounds) => AnimatedBuilder(
        animation: _rotation,
        builder: (context, _) {
          final points = List.generate(
            6,
            (i) => (i, 2 * math.pi * (i / 6 + _rotation.value)),
          )..sort((a, b) => math.cos(a.$2).compareTo(math.cos(b.$2)));
          const cells = [(0, 0), (1, 2), (2, 2), (3, 3), (0, 1), (3, 1)];
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.turquoise.withValues(alpha: .5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              for (final p in points)
                Transform.translate(
                  offset: Offset(
                    math.sin(p.$2) * math.min(118, (bounds.maxWidth - 70) / 2),
                    math.cos(p.$2) * 8,
                  ),
                  child: Transform.scale(
                    scale: .65 + .35 * (math.cos(p.$2) + 1) / 2,
                    child: SpriteAvatar(
                      asset: p.$1 == 4
                          ? 'assets/images/art/spB.webp'
                          : 'assets/images/art/spA.webp',
                      col: cells[p.$1].$1,
                      row: cells[p.$1].$2,
                      size: 66,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
