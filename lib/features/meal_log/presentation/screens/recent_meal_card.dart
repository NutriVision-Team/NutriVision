import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/interactive_food_bowl.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../cubit/recent_meals_cubit.dart';

class RecentMealCard extends StatelessWidget {
  const RecentMealCard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>();
    final state = session.state;
    if (state is! SessionAuthenticated) return const SizedBox.shrink();
    return BlocProvider(
      key: ValueKey(state.user.uid),
      create: (context) => RecentMealsCubit(
        repository: context.read<NutritionRepository>(),
        uid: state.user.uid,
        currentUid: () {
          final current = session.state;
          return current is SessionAuthenticated ? current.user.uid : null;
        },
      )..load(),
      child: const _RecentMealBody(),
    );
  }
}

class _RecentMealBody extends StatelessWidget {
  const _RecentMealBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<RecentMealsCubit, RecentMealsState>(
      listener: (context, state) {
        if (state.status == RecentMealsStatus.saved) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SufraSnackBar(content: Text(l10n.logHubRelogDone)));
          final session = context.read<SessionCubit>().state;
          if (session is SessionAuthenticated) {
            context.read<HomeCubit>().load(session.user.uid);
          }
        }
      },
      builder: (context, state) {
        final cubit = context.read<RecentMealsCubit>();
        if (state.status == RecentMealsStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final meal = state.meal;
        if (meal == null) {
          if (state.status != RecentMealsStatus.failure) {
            return const SizedBox.shrink();
          }
          return TextButton.icon(
            onPressed: cubit.load,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.stateRetry),
          );
        }
        final saving = state.status == RecentMealsStatus.saving;
        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.logHubRecentTitle),
            Text(
              l10n.logHubRecentMeal(meal.title, meal.totalCalories.round()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (state.status == RecentMealsStatus.failure)
              Text(
                l10n.stateError,
                style: const TextStyle(color: Colors.orange),
              ),
          ],
        );
        final action = saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: cubit.relog,
                child: Text(
                  state.status == RecentMealsStatus.failure
                      ? l10n.stateRetry
                      : l10n.logHubRelog,
                ),
              );
        return GlassCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(14) > 21;
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const InteractiveFoodBowl(size: 46),
                        const SizedBox(width: 12),
                        Expanded(child: info),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: action,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  const InteractiveFoodBowl(size: 46),
                  const SizedBox(width: 12),
                  Expanded(child: info),
                  const SizedBox(width: 4),
                  action,
                ],
              );
            },
          ),
        );
      },
    );
  }
}
