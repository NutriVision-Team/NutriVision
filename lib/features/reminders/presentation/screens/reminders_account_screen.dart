import '../../../../core/widgets/nebula_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../data/reminder_runtime.dart';
import '../cubit/reminders_cubit.dart';
import 'reminder_texts.dart';
import 'reminders_screen.dart';

class RemindersAccountScreen extends StatelessWidget {
  const RemindersAccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    if (session is! SessionAuthenticated) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final runtime = context.read<ReminderRuntime>();
    return BlocProvider(
      key: ValueKey(session.user.uid),
      create: (_) => RemindersCubit(
        uid: session.user.uid,
        currentUid: () {
          final s = context.read<SessionCubit>().state;
          return s is SessionAuthenticated ? s.user.uid : null;
        },
        store: runtime.store,
        scheduler: runtime.scheduler,
        notifier: runtime.notifier,
        texts: () => reminderTextsFor(AppLocalizations.of(context)),
      )..load(),
      child: NebulaBackground(
        child: RemindersScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }
}
