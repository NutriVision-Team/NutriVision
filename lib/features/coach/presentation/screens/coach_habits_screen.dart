import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../cubit/coach_cubit.dart';

/// Explicit session choices/check-ins. Never infers completion from meal logs.
class CoachHabitsScreen extends StatefulWidget {
  const CoachHabitsScreen({super.key, required this.cubit});
  final CoachCubit cubit;
  @override
  State<CoachHabitsScreen> createState() => _CoachHabitsScreenState();
}

class _CoachHabitsScreenState extends State<CoachHabitsScreen>
    with WidgetsBindingObserver {
  CoachCubit get cubit => widget.cubit;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final labels = <String, String>{
      'log_meal': ar ? 'أسجّل وجبة واحدة' : 'Log one meal',
      'prepare_meal': ar ? 'أجهّز لوجبة جاية' : 'Prepare for a coming meal',
      'review_ingredients': ar
          ? 'أراجع مكونات وجبة'
          : 'Review a meal\'s ingredients',
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ar ? 'خطوة النهاردة' : 'Today\'s step',
          style: context.readableDisplayStyle(size: 20),
        ),
      ),
      body: NebulaBackground(
        child: SafeArea(
          child: BlocBuilder<CoachCubit, CoachState>(
            bloc: cubit,
            builder: (context, state) {
              final chosen = cubit.chosenHabits;
              final done = chosen.where(cubit.habitDone).length;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    ar
                        ? 'اختار حاجة بسيطة تناسبك. مفيش تقييم ولا عقوبة لو فاتتك.'
                        : 'Choose a small step that suits you. No score or penalty for missing it.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ar
                        ? 'للجلسة فقط إلا لو حفظتها بنفسك من الحفظ في حسابي.'
                        : 'Session-only unless you explicitly save in your account.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in labels.entries)
                        FilterChip(
                          key: ValueKey('choose_${e.key}'),
                          label: Text(e.value),
                          selected: chosen.contains(e.key),
                          onSelected: (v) => cubit.chooseHabit(e.key, v),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (chosen.isEmpty)
                    Text(
                      ar
                          ? 'اختار خطوة عشان تتابعها هنا.'
                          : 'Choose a step to track here.',
                    )
                  else ...[
                    Text(
                      ar
                          ? 'إنت أكدت $done من ${chosen.length} النهاردة'
                          : 'You checked in $done of ${chosen.length} today',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    for (final id in chosen)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                labels[id]!,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cubit.habitDone(id)
                                    ? (ar
                                          ? 'تم بتأكيدك'
                                          : 'Done, confirmed by you')
                                    : (ar
                                          ? 'لسه ما أكدتش'
                                          : 'Not checked in yet'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                key: ValueKey('complete_$id'),
                                onPressed: () =>
                                    cubit.markHabit(id, !cubit.habitDone(id)),
                                child: Text(
                                  cubit.habitDone(id)
                                      ? (ar
                                            ? 'ارجع عن التأكيد'
                                            : 'Undo check-in')
                                      : (ar
                                            ? 'عملتها النهاردة'
                                            : 'I did this today'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
