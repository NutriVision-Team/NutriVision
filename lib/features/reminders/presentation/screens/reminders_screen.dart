import '../../../../core/widgets/sufra_logo.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/reminder_models.dart';
import '../cubit/reminders_cubit.dart';

/// Reminder settings for water, meals and weight. The cubit is provided
/// above, bound to the signed-in uid. Nothing is on by default.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  static const routePath = '/reminders';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: BlocConsumer<RemindersCubit, RemindersState>(
          listenWhen: (a, b) => a.noticeSeq != b.noticeSeq,
          listener: (context, s) {
            final text = switch (s.notice) {
              RemindersNotice.permissionDenied => l.remindersPermissionDenied,
              RemindersNotice.scheduleFailed => l.remindersScheduleFailed,
              RemindersNotice.timezoneUnavailable =>
                l.remindersTimezoneUnavailable,
              RemindersNotice.saveFailed => l.remindersSaveFailed,
              RemindersNotice.waterFull => l.remindersWaterFull,
              RemindersNotice.none => null,
            };
            if (text != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SufraSnackBar(content: Text(text)));
            }
          },
          builder: (context, s) {
            if (!s.loaded) return const AppLoadingView();
            final cubit = context.read<RemindersCubit>();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              children: [
                Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        l.remindersTitle,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'رسالة من سفرة، وخطوة تعملها'
                      : 'A Sufra message with a next step',
                  style: context.readableDisplayStyle(size: 18),
                ),
                Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'دي معاينة للرسائل. الضغط يفتح الأداة بس، مش بيشغّل تذكير أو يسجّل حاجة.'
                      : 'Message previews. Tapping opens the tool only. It does not enable a reminder or log anything.',
                  style: context.explainStyle(
                    size: 13,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 10),
                for (final preview in <(IconData, String, String)>[
                  (Icons.water_drop_outlined, l.remindersNotifWater, '/water'),
                  (
                    Icons.restaurant_outlined,
                    l.remindersNotifMeal(l.mealLunch),
                    '/diary',
                  ),
                  (
                    Icons.monitor_weight_outlined,
                    l.remindersNotifWeight,
                    '/weight',
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      borderColor: AppColors.orangeLight.withValues(alpha: .5),
                      onTap: () => context.push(preview.$3),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const SufraLogo(size: 38),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.appName,
                                  style: context.buttonStyle(
                                    size: 15,
                                    color: AppColors.orangeLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  preview.$2,
                                  style: context.messageStyle(size: 13.5),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                if (s.permissionDenied)
                  _Banner(text: l.remindersPermissionOff, error: true),
                if (s.scheduleProblem && !s.permissionDenied)
                  _Banner(text: l.remindersScheduleFailed, error: true),
                _WaterCard(state: s, cubit: cubit),
                const SizedBox(height: 12),
                _MealsCard(state: s, cubit: cubit),
                const SizedBox(height: 12),
                _WeightCard(state: s, cubit: cubit),
                const SizedBox(height: 16),
                Text(
                  l.remindersInexactNote,
                  textAlign: TextAlign.center,
                  style: context.mutedStyle(size: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  l.remindersPrivacyNote,
                  textAlign: TextAlign.center,
                  style: context.mutedStyle(size: 12),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _fmt(BuildContext c, MinuteOfDay m) => MaterialLocalizations.of(
  c,
).formatTimeOfDay(TimeOfDay(hour: m ~/ 60, minute: m % 60));

Future<MinuteOfDay?> _pickTime(BuildContext c, MinuteOfDay initial) async {
  final t = await showTimePicker(
    context: c,
    initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
  );
  return t == null ? null : t.hour * 60 + t.minute;
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.error});
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: .14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: .4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            color: Color(0xFFFCA5A5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color color;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .2),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.copper,
      ),
    ],
  );
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({required this.state, required this.cubit});
  final RemindersState state;
  final RemindersCubit cubit;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = state.settings.water;
    Future<void> add() async {
      final m = await _pickTime(context, w.times.isEmpty ? 600 : w.times.last);
      if (m != null) await cubit.addWaterTime(m);
    }

    return GlassCard(
      borderColor: AppColors.orangeLight.withValues(alpha: .5),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF06B6D4),
            title: l.remindersWaterTitle,
            value: w.enabled,
            onChanged: state.busy
                ? null
                : (on) =>
                      on && w.times.isEmpty ? add() : cubit.setWaterEnabled(on),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in w.times)
                InputChip(
                  label: Text(_fmt(context, t)),
                  deleteIconColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: .75),
                  deleteButtonTooltipMessage: l.remindersWaterRemove,
                  onDeleted: state.busy ? null : () => cubit.removeWaterTime(t),
                  backgroundColor: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: w.enabled ? .12 : .05),
                ),
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 18),
                label: Text(l.remindersWaterAdd),
                onPressed: state.busy ? null : add,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealsCard extends StatelessWidget {
  const _MealsCard({required this.state, required this.cubit});
  final RemindersState state;
  final RemindersCubit cubit;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final names = {
      'breakfast': l.mealBreakfast,
      'lunch': l.mealLunch,
      'dinner': l.mealDinner,
      'snack': l.mealSnack,
    };
    return GlassCard(
      borderColor: AppColors.orangeLight.withValues(alpha: .5),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFB8C00).withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Color(0xFFFB8C00),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l.remindersMealsTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final type in reminderMealTypes)
            Builder(
              builder: (context) {
                final m = state.settings.meal(type);
                Future<void> pick() async {
                  final t = await _pickTime(context, m.minute ?? 480);
                  if (t != null) await cubit.setMealTime(type, t);
                }

                return Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: state.busy ? null : pick,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                names[type]!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                m.minute == null
                                    ? l.remindersNotSet
                                    : _fmt(context, m.minute!),
                                style: context.mutedStyle(size: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Switch(
                      value: m.enabled,
                      onChanged: state.busy
                          ? null
                          : (on) => on && m.minute == null
                                ? pick()
                                : cubit.setMealEnabled(type, on),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.copper,
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.state, required this.cubit});
  final RemindersState state;
  final RemindersCubit cubit;

  static String dayName(BuildContext c, int weekday) {
    // 2026-11-23 is a Monday.
    final d = DateTime(2026, 11, 22 + weekday);
    return DateFormat.EEEE(Localizations.localeOf(c).toString()).format(d);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = state.settings.weight;
    Future<void> edit() async {
      final day = await showSufraBottomSheet<int>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l.remindersPickDay,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              for (var d = 1; d <= 7; d++)
                ListTile(
                  title: Text(dayName(ctx, d)),
                  selected: d == w.weekday,
                  onTap: () => Navigator.pop(ctx, d),
                ),
            ],
          ),
        ),
      );
      if (day == null || !context.mounted) return;
      final m = await _pickTime(context, w.minute ?? 480);
      if (m != null) await cubit.setWeightSchedule(weekday: day, minute: m);
    }

    final set = w.minute != null && w.weekday != null;
    return GlassCard(
      borderColor: AppColors.orangeLight.withValues(alpha: .5),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            icon: Icons.monitor_weight_outlined,
            color: const Color(0xFF7C3AED),
            title: l.remindersWeightTitle,
            value: w.enabled,
            onChanged: state.busy
                ? null
                : (on) => on && !set ? edit() : cubit.setWeightEnabled(on),
          ),
          InkWell(
            onTap: state.busy ? null : edit,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                set
                    ? '${l.remindersWeightEvery(dayName(context, w.weekday!))} · ${_fmt(context, w.minute!)}'
                    : l.remindersNotSet,
                style: context.mutedStyle(size: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
