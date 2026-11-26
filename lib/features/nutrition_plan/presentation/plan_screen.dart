import '../../../core/personalized_headings.dart';
import 'plan_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/nebula_background.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/cubit/session_cubit.dart';
import '../../profile_setup/presentation/cubit/profile_setup_cubit.dart';
import '../domain/nutrition_plan_service.dart';

/// Screen 07 — Personalized nutrition plan.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  static const String routePath = '/plan';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final setupStatus = context.watch<ProfileSetupCubit>().state.status;
    final session = context.watch<SessionCubit>().state;

    NutritionPlanResult? plan =
        setupStatus is SetupSaved &&
            session is SessionAuthenticated &&
            setupStatus.uid == session.user.uid
        ? setupStatus.plan
        : null;
    final name = session is SessionAuthenticated
        ? (session.profile?.displayName ??
              session.user.email?.split('@').first ??
              '')
        : '';

    if (plan == null) {
      // Deep-linked without a fresh calculation: offer to redo setup rather
      // than inventing numbers.
      return Scaffold(
        body: NebulaBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.homeNoGoalYet,
                    textAlign: TextAlign.center,
                    style: context.displayStyle(size: 22),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: l10n.wizardFinish,
                    onPressed: () => context.go('/setup'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 40).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        planHeading(l10n, name),
                        textAlign: TextAlign.center,
                        style: context
                            .displayStyle(size: 28)
                            .copyWith(
                              fontFamily: 'SufraBody',
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        borderColor: AppColors.orangeLight.withValues(
                          alpha: .5,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.aiPurple.withValues(alpha: 0.4),
                            AppColors.turquoise.withValues(alpha: 0.2),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical:
                                MediaQuery.textScalerOf(context).scale(13) > 18
                                ? 16
                                : 0,
                          ),
                          child: SizedBox(
                            height:
                                MediaQuery.textScalerOf(context).scale(13) > 18
                                ? 280
                                : 190,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: const PlanCalorieRings(),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${plan.dailyCalories.round()}',
                                      style: context.heroNumberStyle(size: 40),
                                    ),
                                    SizedBox(
                                      width: 104,
                                      child: Text(
                                        l10n.planDailyCalories,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.mutedStyle(size: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flex(
                        direction:
                            MediaQuery.textScalerOf(context).scale(13) > 18
                            ? Axis.vertical
                            : Axis.horizontal,
                        children: [
                          _MacroLiquidCard(
                            value: plan.proteinGrams,
                            label: l10n.planProtein,
                            color: AppColors.turquoise,
                            fill: 0.8,
                          ),
                          const SizedBox(width: 10, height: 10),
                          _MacroLiquidCard(
                            value: plan.carbsGrams,
                            label: l10n.planCarbs,
                            color: AppColors.copper,
                            fill: 0.65,
                          ),
                          const SizedBox(width: 10, height: 10),
                          _MacroLiquidCard(
                            value: plan.fatGrams,
                            label: l10n.planFat,
                            color: AppColors.purpleLight,
                            fill: 0.45,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        borderColor: AppColors.orangeLight.withValues(
                          alpha: .5,
                        ),
                        child: Column(
                          children: [
                            const ExcludeSemantics(
                              child: SizedBox(
                                height: 64,
                                width: double.infinity,
                                child: CustomPaint(painter: PlanRouteArt()),
                              ),
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: plan.estimatedWeeks > 0
                                        ? l10n.planTimeline(plan.estimatedWeeks)
                                        : l10n.planTimelineMaintain,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.planDisclaimer,
                              textAlign: TextAlign.center,
                              style: context.mutedStyle(size: 11),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 16),
                      GradientButton(
                        label: l10n.planCta,
                        height: MediaQuery.textScalerOf(context).scale(17) > 24
                            ? 96
                            : 54,
                        onPressed: () => context.go('/home'),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroLiquidCard extends StatelessWidget {
  const _MacroLiquidCard({
    required this.value,
    required this.label,
    required this.color,
    required this.fill,
  });

  final double value;
  final String label;
  final Color color;
  final double fill;

  @override
  Widget build(BuildContext context) {
    final card = GlassCard(
      borderColor: AppColors.orangeLight.withValues(alpha: .5),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Container(
            height: 86,
            width: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fill),
                duration: const Duration(seconds: 2),
                curve: Curves.easeOut,
                builder: (context, v, _) {
                  return Container(
                    height: 86 * v,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [color, color.withValues(alpha: 0.55)],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('${value.round()}', style: context.displayStyle(size: 20)),
          Text(label, style: context.mutedStyle(size: 11)),
        ],
      ),
    );
    return MediaQuery.textScalerOf(context).scale(13) > 18
        ? SizedBox(width: double.infinity, child: card)
        : Expanded(child: card);
  }
}
