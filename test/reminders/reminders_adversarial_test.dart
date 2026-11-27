import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/features/reminders/data/reminder_guard.dart';
import 'package:sufradepi/features/reminders/data/reminder_scheduler.dart';
import 'package:sufradepi/features/reminders/data/reminder_store.dart';
import 'package:sufradepi/features/reminders/domain/reminder_models.dart';
import 'package:sufradepi/features/reminders/domain/reminder_plan.dart';
import 'package:sufradepi/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:sufradepi/features/reminders/presentation/screens/reminders_host.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminders_logic_test.dart' show FakeNotifier;

/// Notifier whose native calls can be held until the test releases them.
class GatedNotifier extends FakeNotifier {
  Completer<void>? scheduleGate;
  Completer<void>? cancelGate;
  Completer<void>? permissionGate;
  int scheduleCalls = 0;

  @override
  Future<void> schedule(
    PlannedReminder r, {
    required tz.TZDateTime first,
    required ReminderTexts texts,
  }) async {
    scheduleCalls++;
    final g = scheduleGate;
    if (g != null) await g.future;
    return super.schedule(r, first: first, texts: texts);
  }

  @override
  Future<void> cancel(int id) async {
    final g = cancelGate;
    if (g != null) await g.future;
    return super.cancel(id);
  }

  @override
  Future<bool> requestPermission() async {
    final g = permissionGate;
    if (g != null) await g.future;
    return super.requestPermission();
  }
}

/// Store whose owner-marker write can be made to fail.
class FlakyStore extends ReminderStore {
  FlakyStore(super.prefs);
  bool failOwner = false;
  Completer<void>? clearOwnerGate;
  @override
  Future<void> setScheduledOwner(String? uid) async {
    if (failOwner) throw StateError('marker');
    if (uid == null && clearOwnerGate != null) await clearOwnerGate!.future;
    return super.setScheduledOwner(uid);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  late GatedNotifier n;
  late FlakyStore store;
  late ReminderScheduler sch;
  String? active;
  const texts = ReminderTexts(
    title: 't',
    water: 'w',
    weight: 'g',
    meals: {'breakfast': 'b', 'lunch': 'l', 'dinner': 'd', 'snack': 's'},
  );
  final lunch = ReminderSettings.empty.withMeal(
    'lunch',
    const MealReminder(enabled: true, minute: 840),
  );
  const tick = Duration(milliseconds: 30);

  void switchTo(String? uid) {
    active = uid;
    sch.ownerChanged();
  }

  RemindersCubit cubitFor(String uid) => RemindersCubit(
    uid: uid,
    currentUid: () => active,
    store: store,
    scheduler: sch,
    notifier: n,
    texts: () => texts,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = FlakyStore(await SharedPreferences.getInstance());
    n = GatedNotifier();
    active = 'a';
    sch = ReminderScheduler(
      notifier: n,
      location: () async => tz.getLocation('Africa/Cairo'),
      clock: () => DateTime.utc(2026, 11, 22, 7),
    )..currentUid = () => active;
  });

  test(
    'verified cancel finalization and next owner scheduling are atomic',
    () async {
      sch.prepareSync = (uid) async {
        if (store.pendingCancel) return false;
        await store.setScheduledOwner(uid);
        return !store.pendingCancel;
      };
      await sch.sync(uid: 'a', settings: lunch, texts: texts);
      store.clearOwnerGate = Completer<void>();
      final cleanup = ReminderGuard(
        store: store,
        scheduler: sch,
      ).cancelEverything();
      await Future<void>.delayed(tick);
      final next = sch.sync(uid: 'a', settings: lunch, texts: texts);
      await Future<void>.delayed(tick);
      expect(store.pendingCancel, isTrue);
      expect(n.pending, isEmpty);
      store.clearOwnerGate!.complete();
      expect(await cleanup, CleanupResult.cleaned);
      expect(await next, SyncStatus.ok);
      expect(store.scheduledOwner, 'a');
      expect(store.pendingCancel, isFalse);
      expect(n.pending, isNotEmpty);
    },
  );
  group('scheduler gate', () {
    test(
      'schedule held in native, account switch: nothing of a survives',
      () async {
        n.scheduleGate = Completer();
        final f = sch.sync(uid: 'a', settings: lunch, texts: texts);
        await Future<void>.delayed(tick);
        switchTo('b');
        n.scheduleGate!.complete();
        await f;
        expect(n.pending, isEmpty, reason: 'a must not stay scheduled for b');
      },
    );

    test('stale queued job behind a slow cancel is rejected', () async {
      n.cancelGate = Completer();
      final slow = sch.cancelAllVerified();
      final stale = sch.sync(uid: 'a', settings: lunch, texts: texts);
      switchTo(null);
      n.cancelGate!.complete();
      await slow;
      expect(await stale, SyncStatus.failed);
      expect(n.pending, isEmpty);
      expect(n.scheduleCalls, 0);
    });

    test('rapid a to null to a: only the last sync schedules', () async {
      n.cancelGate = Completer();
      final blocker = sch.cancelAllVerified();
      final s1 = sch.sync(uid: 'a', settings: lunch, texts: texts);
      switchTo(null);
      final s2 = sch.sync(
        uid: null,
        settings: ReminderSettings.empty,
        texts: texts,
      );
      switchTo('a');
      final s3 = sch.sync(uid: 'a', settings: lunch, texts: texts);
      n.cancelGate!.complete();
      await blocker;
      expect(await s1, SyncStatus.failed);
      await s2;
      expect(await s3, SyncStatus.ok);
      expect(n.pending.keys, [ReminderIds.meal('lunch')]);
    });
  });

  group('cubit', () {
    test(
      'delayed permission, account switches meanwhile: nothing saved, scheduled or owned',
      () async {
        n
          ..enabled = false
          ..permissionGate = Completer();
        final c = cubitFor('a');
        await c.load();
        final f = c.setMealTime('lunch', 840);
        await Future<void>.delayed(tick);
        switchTo('b');
        n.permissionGate!.complete();
        await f;
        expect(n.pending, isEmpty);
        expect(store.load('a').meal('lunch').minute, isNull);
        await c.close();
      },
    );

    test('pending cleanup that fails blocks scheduling and says so', () async {
      await store.setPendingCancel(true);
      n.failCancel = true;
      final c = cubitFor('a');
      await c.load();
      await c.setMealTime('lunch', 840);
      expect(n.scheduleCalls, 0);
      expect(c.state.scheduleProblem, isTrue);
      expect(store.pendingCancel, isTrue);
      await c.close();
    });

    test('pending cleanup retry succeeds, then schedules and owns', () async {
      await store.setPendingCancel(true);
      n.failCancel = true;
      final c = cubitFor('a');
      await c.load();
      n.failCancel = false;
      await c.setMealTime('lunch', 840);
      expect(store.pendingCancel, isFalse);
      expect(store.scheduledOwner, 'a');
      expect(n.pending.keys, [ReminderIds.meal('lunch')]);
      await c.close();
    });

    test(
      'owner marker write fails in a user edit: nothing scheduled',
      () async {
        final c = cubitFor('a');
        await c.load();
        store.failOwner = true;
        await c.setMealTime('lunch', 840);
        expect(n.scheduleCalls, 0);
        expect(
          c.state.scheduleProblem || c.state.notice != RemindersNotice.none,
          isTrue,
        );
        await c.close();
      },
    );

    test(
      'owner marker write fails during load/resync: no uncaught error',
      () async {
        await store.save('a', lunch);
        store.failOwner = true;
        final c = cubitFor('a');
        Object? err;
        try {
          await c.load();
        } catch (e) {
          err = e;
        }
        expect(err, isNull, reason: 'resync must handle marker failure');
        expect(n.scheduleCalls, 0);
        await c.close();
      },
    );

    test(
      'host cleanup and cubit edit overlap: owner marker still set after',
      () async {
        await store.setPendingCancel(true); // forces both to clean up
        final c = cubitFor('a');
        n.cancelGate = Completer();
        final edit = c.setMealTime('lunch', 840);
        final other = ReminderGuard(
          store: store,
          scheduler: sch,
        ).cancelEverything();
        await Future<void>.delayed(tick);
        n.cancelGate!.complete();
        await edit;
        await other;
        if (n.pending.isNotEmpty) {
          expect(
            store.scheduledOwner,
            'a',
            reason: 'alarms exist, so the marker must name their owner',
          );
        }
        await c.close();
      },
    );
  });

  group('host', () {
    Widget host(String? uid, {bool resolved = true, void Function()? onFail}) =>
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: RemindersHost(
            uid: uid,
            authResolved: resolved,
            store: store,
            scheduler: sch,
            onCleanupFailed: onFail,
            child: const SizedBox(),
          ),
        );
    Future<void> settle(WidgetTester t) => t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    Future<void> pump(WidgetTester t, Widget w) async {
      await t.runAsync(() => t.pumpWidget(w));
      await settle(t);
    }

    testWidgets('sign-out while a schedule is held in native', (t) async {
      await t.runAsync(() => store.save('a', lunch));
      n.scheduleGate = Completer();
      await pump(t, host('a'));
      active = null;
      sch.ownerChanged();
      await pump(t, host(null));
      n.scheduleGate!.complete();
      await settle(t);
      expect(n.pending, isEmpty);
      expect(store.scheduledOwner, isNull);
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a to b with a held schedule: only b ends up scheduled', (
      t,
    ) async {
      await t.runAsync(() async {
        await store.save('a', lunch);
        await store.save(
          'b',
          ReminderSettings.empty.withMeal(
            'dinner',
            const MealReminder(enabled: true, minute: 1200),
          ),
        );
      });
      n.scheduleGate = Completer();
      await pump(t, host('a'));
      active = 'b';
      sch.ownerChanged();
      await pump(t, host('b'));
      n.scheduleGate!.complete();
      await settle(t);
      await settle(t);
      expect(n.pending.keys, [ReminderIds.meal('dinner')]);
      expect(store.scheduledOwner, 'b');
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('auth resolves to signed-out: verified cleanup runs', (
      t,
    ) async {
      await t.runAsync(() async {
        await store.setScheduledOwner('a');
        await sch.sync(uid: 'a', settings: lunch, texts: texts);
      });
      active = null;
      sch.ownerChanged();
      await pump(t, host(null, resolved: false));
      expect(n.pending, isNotEmpty);
      await pump(t, host(null));
      expect(n.pending, isEmpty);
      expect(store.scheduledOwner, isNull);
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'owner marker write fails in host: nothing scheduled, no throw',
      (t) async {
        await t.runAsync(() => store.save('a', lunch));
        store.failOwner = true;
        await pump(t, host('a'));
        expect(n.scheduleCalls, 0);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}
