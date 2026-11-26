import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/features/reminders/data/reminder_guard.dart';
import 'package:sufradepi/features/reminders/data/reminder_scheduler.dart';
import 'package:sufradepi/features/reminders/data/reminder_store.dart';
import 'package:sufradepi/features/reminders/domain/reminder_models.dart';
import 'package:sufradepi/features/reminders/domain/reminder_plan.dart';
import 'package:sufradepi/features/reminders/presentation/screens/reminders_host.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminders_logic_test.dart' show FakeNotifier;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  late FakeNotifier n;
  late ReminderStore store;
  late ReminderScheduler sch;
  late ReminderGuard guard;
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = ReminderStore(await SharedPreferences.getInstance());
    n = FakeNotifier();
    sch = ReminderScheduler(
      notifier: n,
      location: () async => tz.getLocation('Africa/Cairo'),
      clock: () => DateTime.utc(2026, 11, 22, 7),
    );
    guard = ReminderGuard(store: store, scheduler: sch);
  });

  group('guard', () {
    test('verified cancel clears pending flag and owner', () async {
      await sch.sync(uid: 'a', settings: lunch, texts: texts);
      await store.setScheduledOwner('a');
      expect(await guard.cancelEverything(), CleanupResult.cleaned);
      expect(n.pending, isEmpty);
      expect(store.pendingCancel, isFalse);
      expect(store.scheduledOwner, isNull);
    });
    test('cancel throws: failed, flag stays set, nothing faked', () async {
      await sch.sync(uid: 'a', settings: lunch, texts: texts);
      n.failCancel = true;
      expect(await guard.cancelEverything(), CleanupResult.failed);
      expect(store.pendingCancel, isTrue);
      expect(n.pending, isNotEmpty);
    });
    test('cancel returns but OS still pending: failed', () async {
      await sch.sync(uid: 'a', settings: lunch, texts: texts);
      n.ghostPending = true;
      expect(await guard.cancelEverything(), CleanupResult.failed);
      expect(store.pendingCancel, isTrue);
    });
    test('pending list unreadable: failed, not assumed clean', () async {
      n.failPendingRead = true;
      expect(await guard.cancelEverything(), CleanupResult.failed);
      expect(store.pendingCancel, isTrue);
    });
    test('retry after failure succeeds and clears', () async {
      await sch.sync(uid: 'a', settings: lunch, texts: texts);
      n.failCancel = true;
      await guard.cancelEverything();
      n.failCancel = false;
      expect(guard.needsCleanup, isTrue);
      expect(await guard.cancelEverything(), CleanupResult.cleaned);
      expect(guard.needsCleanup, isFalse);
      expect(n.pending, isEmpty);
    });
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
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    Future<void> pump(WidgetTester t, Widget w) async {
      await t.runAsync(() => t.pumpWidget(w));
      await settle(t);
    }

    testWidgets('auth unresolved: nothing cancelled or scheduled', (t) async {
      await t.runAsync(() => store.save('a', lunch));
      await t.runAsync(() => sch.sync(uid: 'a', settings: lunch, texts: texts));
      n.log.clear();
      await pump(t, host(null, resolved: false));
      expect(n.log, isEmpty, reason: 'null uid before auth is not sign-out');
      expect(n.pending, isNotEmpty);
      await pump(t, host('a'));
      expect(n.pending.keys, [ReminderIds.meal('lunch')]);
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('failed cancel on sign-out: reported, retried on resume', (
      t,
    ) async {
      await t.runAsync(() => store.save('a', lunch));
      var failures = 0;
      await pump(t, host('a', onFail: () => failures++));
      await t.runAsync(() => store.setScheduledOwner('a'));
      n.failCancel = true;
      await pump(t, host(null, onFail: () => failures++));
      expect(failures, 1);
      expect(store.pendingCancel, isTrue);
      expect(n.pending, isNotEmpty, reason: 'honestly still scheduled');
      // while unverified, a new account must not get a schedule on top
      await pump(t, host('b', onFail: () => failures++));
      expect(failures, 2);
      expect(
        n.pending.values.every((v) => v.$1.id == ReminderIds.meal('lunch')),
        isTrue,
      );
      // recovery
      n.failCancel = false;
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.runAsync(
        () async =>
            t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      await settle(t);
      expect(store.pendingCancel, isFalse);
      expect(n.pending, isEmpty, reason: 'b has nothing saved');
      expect(store.scheduledOwner, 'b');
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('cold start after process death: unfinished cleanup first', (
      t,
    ) async {
      await t.runAsync(() => sch.sync(uid: 'a', settings: lunch, texts: texts));
      await t.runAsync(() => store.setPendingCancel(true));
      await t.runAsync(() => store.setScheduledOwner('a'));
      await pump(t, host('b'));
      expect(n.pending, isEmpty);
      expect(store.pendingCancel, isFalse);
      expect(store.scheduledOwner, 'b');
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('owner mismatch without flag is cleaned before scheduling', (
      t,
    ) async {
      await t.runAsync(() => store.save('b', lunch));
      await t.runAsync(() => sch.sync(uid: 'a', settings: lunch, texts: texts));
      await t.runAsync(() => store.setScheduledOwner('a'));
      n.log.clear();
      await pump(t, host('b'));
      expect(n.log.indexOf('cancel ${ReminderIds.all.first}'), 0);
      expect(n.pending.keys, [ReminderIds.meal('lunch')]);
      expect(store.scheduledOwner, 'b');
      await t.pumpWidget(const SizedBox.shrink());
    });
  });
}
