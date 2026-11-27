import 'reminder_scheduler.dart';
import 'reminder_store.dart';

enum CleanupResult { cleaned, failed }

/// Makes "no reminders left on the OS" something that is checked and
/// remembered, not assumed. The pending flag is written BEFORE cancelling,
/// so a crash mid-cancel is retried on the next start. It is cleared only
/// after the OS reports none of our IDs pending.
class ReminderGuard {
  ReminderGuard({required this.store, required this.scheduler});
  final ReminderStore store;
  final ReminderScheduler scheduler;

  bool get needsCleanup => store.pendingCancel;

  /// Call (awaited) from the sign-out flow BEFORE signing out, and use the
  /// result: [CleanupResult.failed] means reminders may still be scheduled.
  /// The flag stays set and RemindersHost retries until it is verified.
  Future<CleanupResult> cancelEverything() async {
    try {
      await store.setPendingCancel(true);
    } catch (_) {
      // Could not persist the flag; still try to cancel, and report the
      // outcome of the cancel itself.
    }
    final ok = await scheduler.cancelAllVerified(
      afterVerified: () async {
        await store.setScheduledOwner(null);
        await store.setPendingCancel(false);
      },
    );
    return ok ? CleanupResult.cleaned : CleanupResult.failed;
  }
}
