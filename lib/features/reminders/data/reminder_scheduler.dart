import 'dart:async';

import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_models.dart';
import '../domain/reminder_plan.dart';
import 'reminder_notifier.dart';

enum SyncStatus {
  ok,
  nothingToSchedule,
  permissionDenied,
  timezoneUnavailable,
  failed,
}

/// Turns settings into OS schedules. One call replaces the whole feature's
/// schedule for one account: IDs that are not planned are cancelled (that
/// is how disabling, removing a time and switching accounts all cancel
/// correctly), planned IDs are re-scheduled in place.
class ReminderScheduler {
  ReminderScheduler({
    required this.notifier,
    Future<tz.Location> Function()? location,
    DateTime Function()? clock,
  }) : _location = location ?? deviceLocation,
       _clock = clock ?? DateTime.now;

  final ReminderNotifier notifier;
  final Future<tz.Location> Function() _location;
  final DateTime Function() _clock;
  Future<void> _queue = Future.value();
  String? Function()? currentUid;
  Future<bool> Function(String? uid)? prepareSync;
  int _ownerVersion = 0;
  void ownerChanged() {
    _ownerVersion++;
  }

  bool _active(String? uid, int version) =>
      version == _ownerVersion && (currentUid == null || currentUid!() == uid);

  Future<T> _enqueue<T>(Future<T> Function() job, T onError) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await job());
      } catch (_) {
        completer.complete(onError);
      }
    });
    return completer.future;
  }

  /// Serialized: two quick edits can never interleave cancel/schedule.
  Future<SyncStatus> sync({
    required String? uid,
    required ReminderSettings settings,
    required ReminderTexts texts,
  }) {
    final version = _ownerVersion;
    return _enqueue(() async {
      if (!_active(uid, version)) return SyncStatus.failed;
      if (prepareSync != null && !await prepareSync!(uid)) {
        return SyncStatus.failed;
      }
      if (!_active(uid, version)) return SyncStatus.failed;
      return _sync(uid, settings, texts, version);
    }, SyncStatus.failed);
  }

  /// Cancels every reminder ID, then asks the OS what is still pending.
  /// True only when that check shows none left. A cancel that throws, or a
  /// pending list that cannot be read, is false, never a guessed success.
  Future<bool> cancelAllVerified({Future<void> Function()? afterVerified}) =>
      _enqueue(() async {
        var ok = true;
        for (final id in ReminderIds.all) {
          try {
            await notifier.cancel(id);
          } catch (_) {
            ok = false;
          }
        }
        try {
          final left = await notifier.pendingIds();
          if (ReminderIds.all.any(left.contains)) ok = false;
        } catch (_) {
          ok = false;
        }
        if (ok && afterVerified != null) {
          await afterVerified();
        }
        return ok;
      }, false);

  Future<SyncStatus> _sync(
    String? uid,
    ReminderSettings s,
    ReminderTexts texts,
    int version,
  ) async {
    final plan = (uid == null || uid.isEmpty)
        ? <PlannedReminder>[]
        : planReminders(s, texts);
    final planned = {for (final p in plan) p.id};
    for (final id in ReminderIds.all) {
      if (!planned.contains(id)) await notifier.cancel(id);
    }
    if (plan.isEmpty) return SyncStatus.nothingToSchedule;

    if (!await notifier.areNotificationsEnabled()) {
      for (final id in planned) {
        await notifier.cancel(id);
      }
      return SyncStatus.permissionDenied;
    }
    final tz.Location location;
    try {
      location = await _location();
    } catch (_) {
      return SyncStatus.timezoneUnavailable;
    }
    if (!_active(uid, version)) return SyncStatus.failed;
    final now = tz.TZDateTime.from(_clock(), location);
    var failed = false;
    for (final r in plan) {
      try {
        if (!_active(uid, version)) return SyncStatus.failed;
        await notifier.cancel(r.id);
        if (!_active(uid, version)) return SyncStatus.failed;
        await notifier.schedule(
          r,
          first: nextOccurrence(r, location, now),
          texts: texts,
        );
      } catch (_) {
        failed = true;
      }
    }
    if (!_active(uid, version)) {
      for (final id in ReminderIds.all) {
        await notifier.cancel(id);
      }
      return SyncStatus.failed;
    }
    // A successful plugin call is not proof the OS retained every reminder.
    // Report failure when pending IDs cannot be verified, never show a false
    // scheduled state after a platform silently drops an alarm.
    try {
      final pending = await notifier.pendingIds();
      if (!planned.every(pending.contains)) failed = true;
    } catch (_) {
      failed = true;
    }
    if (!_active(uid, version)) {
      for (final id in ReminderIds.all) {
        await notifier.cancel(id);
      }
      return SyncStatus.failed;
    }
    return failed ? SyncStatus.failed : SyncStatus.ok;
  }
}
