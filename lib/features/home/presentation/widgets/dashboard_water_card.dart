import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/progress_widgets.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../progress/data/water_weight_repository.dart';
import '../../../progress/presentation/cubit/water_cubit.dart';

class DashboardWaterCard extends StatelessWidget {
  const DashboardWaterCard({
    super.key,
    required this.uid,
    required this.repository,
    this.clock,
  });
  final String uid;
  final WaterWeightRepository repository;
  final DateTime Function()? clock;
  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(uid),
    create: (context) => WaterCubit(
      waterWeightRepository: repository,
      nutritionRepository: context.read<NutritionRepository>(),
      uid: uid,
      currentUid: () {
        final session = context.read<SessionCubit>().state;
        return session is SessionAuthenticated ? session.user.uid : null;
      },
      clock: clock,
    )..load(),
    child: BlocBuilder<WaterCubit, WaterState>(
      builder: (context, state) {
        final ar = Localizations.localeOf(context).languageCode == 'ar';
        final cubit = context.read<WaterCubit>();
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    color: AppColors.turquoise,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ar ? 'كوباية ميّه؟' : 'A glass of water?',
                      style: context.displayStyle(size: 21),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.loading)
                const LinearProgressIndicator()
              else ...[
                if (!state.failed) ...[
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    child: Text(
                      '${state.totalMl.round()} / ${state.goalMl.round()} ml',
                      key: ValueKey(state.totalMl),
                      textDirection: TextDirection.ltr,
                      style: context.displayStyle(size: 26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SufraProgressBar(fraction: state.fraction),
                  const SizedBox(height: 8),
                  Text(
                    state.goalChosen
                        ? (ar
                              ? 'هدفك المختار على الجهاز'
                              : 'Your chosen device-local goal')
                        : (ar
                              ? 'هدف افتراضي عام، مش توصية شخصية'
                              : 'General default goal, not a personal recommendation'),
                    style: context.mutedStyle(size: 12),
                  ),
                ] else
                  Text(
                    ar
                        ? 'مش قادرين نأكد آخر تحديث. إعادة المحاولة بتستخدم نفس العملية من غير تكرار.'
                        : 'The last update could not be confirmed. Retry uses the same operation to avoid duplicates.',
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (state.failed)
                      OutlinedButton(
                        onPressed: state.saving
                            ? null
                            : () => cubit.retryOrLoad(),
                        child: Text(ar ? 'حاول تاني' : 'Try again'),
                      )
                    else
                      FilledButton.icon(
                        key: const ValueKey('dashboard-water-add'),
                        onPressed: state.saving
                            ? null
                            : () => cubit.addWater(250),
                        icon: state.saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(ar ? '٢٥٠ مل' : '250 ml'),
                      ),
                    TextButton(
                      onPressed: () async {
                        await context.push('/water');
                        if (!context.mounted) return;
                        await cubit.load();
                      },
                      child: Text(ar ? 'التفاصيل والهدف' : 'Details and goal'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
