import 'reminder_store.dart';
import 'reminder_notifier.dart';
import 'reminder_scheduler.dart';

class ReminderRuntime {
  ReminderRuntime(this.store, {ReminderNotifier? notifier})
    : notifier = notifier ?? LocalReminderNotifier() {
    scheduler = ReminderScheduler(notifier: this.notifier);
    scheduler.prepareSync = (uid) async {
      if (store.pendingCancel ||
          (store.scheduledOwner != null && store.scheduledOwner != uid)) {
        return false;
      }
      try {
        await store.setScheduledOwner(uid);
        return !store.pendingCancel;
      } catch (_) {
        return false;
      }
    };
  }
  final ReminderStore store;
  final ReminderNotifier notifier;
  late final ReminderScheduler scheduler;
}
