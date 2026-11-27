import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/reminder_notifier.dart';
import '../../data/reminder_guard.dart';
import '../../data/reminder_scheduler.dart';
import '../../data/reminder_store.dart';
import '../../domain/reminder_models.dart';

enum RemindersNotice {
  none,
  permissionDenied,
  scheduleFailed,
  timezoneUnavailable,
  saveFailed,
  waterFull,
}

class RemindersState {
  const RemindersState({
    this.settings = ReminderSettings.empty,
    this.loaded = false,
    this.busy = false,
    this.permissionDenied = false,
    this.scheduleProblem = false,
    this.notice = RemindersNotice.none,
    this.noticeSeq = 0,
  });
  final ReminderSettings settings;
  final bool loaded;
  final bool busy;

  /// Reminders are switched on but the system blocks notifications.
  final bool permissionDenied;

  /// Switched on, but the OS schedule could not be set (see notice).
  final bool scheduleProblem;
  final RemindersNotice notice;
  final int noticeSeq;

  RemindersState copyWith({
    ReminderSettings? settings,
    bool? loaded,
    bool? busy,
    bool? permissionDenied,
    bool? scheduleProblem,
    RemindersNotice? notice,
  }) => RemindersState(
    settings: settings ?? this.settings,
    loaded: loaded ?? this.loaded,
    busy: busy ?? this.busy,
    permissionDenied: permissionDenied ?? this.permissionDenied,
    scheduleProblem: scheduleProblem ?? this.scheduleProblem,
    notice: notice ?? RemindersNotice.none,
    noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
  );
}

/// Bound to one signed-in uid. All changes go: validate, ask permission in
/// context only when something is being switched ON, persist, then sync the
/// OS schedule. Switching OFF never prompts and always cancels.
class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit({
    required this.uid,
    required this.currentUid,
    required this.store,
    required this.scheduler,
    required this.notifier,
    required this.texts,
  }) : super(const RemindersState());

  final String uid;
  final String? Function() currentUid;
  final ReminderStore store;
  final ReminderScheduler scheduler;
  final ReminderNotifier notifier;

  /// Current-language texts. Evaluated at each sync.
  final ReminderTexts Function() texts;

  bool get _active => !isClosed && uid.isNotEmpty && currentUid() == uid;

  Future<void> load() async {
    if (!_active) return;
    final s = store.load(uid);
    emit(state.copyWith(settings: s, loaded: true));
    await resync();
  }

  /// Re-applies saved settings (start, resume, language or timezone change).
  /// Never prompts for permission.
  Future<void> resync() async {
    if (!_active) return;
    try {
      if (store.pendingCancel ||
          (store.scheduledOwner != null && store.scheduledOwner != uid)) {
        final cleanup = await ReminderGuard(
          store: store,
          scheduler: scheduler,
        ).cancelEverything();
        if (cleanup == CleanupResult.failed) {
          if (_active) {
            emit(
              state.copyWith(
                scheduleProblem: true,
                notice: RemindersNotice.scheduleFailed,
              ),
            );
          }
          return;
        }
      }
      if (!_active) return;
      await store.setScheduledOwner(uid);
      if (!_active) return;
      final status = await scheduler.sync(
        uid: uid,
        settings: state.settings,
        texts: texts(),
      );
      if (!_active) return;
      emit(_afterSync(status));
    } catch (_) {
      if (_active) {
        emit(
          state.copyWith(
            busy: false,
            scheduleProblem: true,
            notice: RemindersNotice.scheduleFailed,
          ),
        );
      }
    }
  }

  RemindersState _afterSync(SyncStatus status) => state.copyWith(
    busy: false,
    permissionDenied: status == SyncStatus.permissionDenied,
    scheduleProblem:
        status == SyncStatus.failed || status == SyncStatus.timezoneUnavailable,
  );

  Future<void> _apply(ReminderSettings next, {required bool turningOn}) async {
    if (!_active || state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      if (turningOn && !await notifier.areNotificationsEnabled()) {
        if (!await notifier.requestPermission()) {
          if (_active) {
            emit(
              state.copyWith(
                busy: false,
                permissionDenied: true,
                notice: RemindersNotice.permissionDenied,
              ),
            );
          }
          return;
        }
      }
      if (!_active) return;
      try {
        await store.save(uid, next);
      } catch (_) {
        if (_active) {
          emit(state.copyWith(busy: false, notice: RemindersNotice.saveFailed));
        }
        return;
      }
      if (!_active) return;
      emit(state.copyWith(settings: next, permissionDenied: false));
      if (store.pendingCancel ||
          (store.scheduledOwner != null && store.scheduledOwner != uid)) {
        final cleanup = await ReminderGuard(
          store: store,
          scheduler: scheduler,
        ).cancelEverything();
        if (cleanup == CleanupResult.failed) {
          if (_active) {
            emit(
              state.copyWith(
                busy: false,
                scheduleProblem: true,
                notice: RemindersNotice.scheduleFailed,
              ),
            );
          }
          return;
        }
      }
      if (!_active) return;
      await store.setScheduledOwner(uid);
      if (!_active) return;
      final status = await scheduler.sync(
        uid: uid,
        settings: next,
        texts: texts(),
      );
      if (!_active) return;
      final s = _afterSync(status);
      emit(
        status == SyncStatus.failed
            ? s.copyWith(notice: RemindersNotice.scheduleFailed)
            : status == SyncStatus.timezoneUnavailable
            ? s.copyWith(notice: RemindersNotice.timezoneUnavailable)
            : s,
      );
    } catch (_) {
      if (_active) {
        emit(
          state.copyWith(busy: false, notice: RemindersNotice.scheduleFailed),
        );
      }
    }
  }

  // Water -------------------------------------------------------------

  Future<void> setWaterEnabled(bool on) {
    final w = state.settings.water;
    if (on && w.times.isEmpty) return Future.value(); // needs a time first
    return _apply(
      state.settings.copyWith(water: w.copyWith(enabled: on)),
      turningOn: on,
    );
  }

  Future<void> addWaterTime(MinuteOfDay minute) {
    final w = state.settings.water;
    if (!isValidMinute(minute) || w.times.contains(minute)) {
      return Future.value();
    }
    if (w.times.length >= maxWaterTimes) {
      emit(state.copyWith(notice: RemindersNotice.waterFull));
      return Future.value();
    }
    final times = [...w.times, minute]..sort();
    return _apply(
      state.settings.copyWith(
        water: WaterReminders(enabled: true, times: times),
      ),
      turningOn: true,
    );
  }

  Future<void> removeWaterTime(MinuteOfDay minute) {
    final w = state.settings.water;
    final times = [
      for (final t in w.times)
        if (t != minute) t,
    ];
    return _apply(
      state.settings.copyWith(
        water: WaterReminders(
          enabled: w.enabled && times.isNotEmpty,
          times: times,
        ),
      ),
      turningOn: false,
    );
  }

  // Meals -------------------------------------------------------------

  Future<void> setMealEnabled(String type, bool on) {
    final m = state.settings.meal(type);
    if (!reminderMealTypes.contains(type) || (on && m.minute == null)) {
      return Future.value();
    }
    return _apply(
      state.settings.withMeal(
        type,
        MealReminder(enabled: on, minute: m.minute),
      ),
      turningOn: on,
    );
  }

  Future<void> setMealTime(String type, MinuteOfDay minute) {
    if (!reminderMealTypes.contains(type) || !isValidMinute(minute)) {
      return Future.value();
    }
    return _apply(
      state.settings.withMeal(
        type,
        MealReminder(enabled: true, minute: minute),
      ),
      turningOn: true,
    );
  }

  // Weight ------------------------------------------------------------

  Future<void> setWeightEnabled(bool on) {
    final w = state.settings.weight;
    if (on && (w.minute == null || w.weekday == null)) return Future.value();
    return _apply(
      state.settings.copyWith(
        weight: WeightReminder(
          enabled: on,
          minute: w.minute,
          weekday: w.weekday,
        ),
      ),
      turningOn: on,
    );
  }

  Future<void> setWeightSchedule({
    required int weekday,
    required MinuteOfDay minute,
  }) {
    if (weekday < 1 || weekday > 7 || !isValidMinute(minute)) {
      return Future.value();
    }
    return _apply(
      state.settings.copyWith(
        weight: WeightReminder(enabled: true, minute: minute, weekday: weekday),
      ),
      turningOn: true,
    );
  }
}
