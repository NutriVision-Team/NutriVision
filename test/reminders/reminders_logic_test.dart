import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/features/reminders/data/reminder_notifier.dart';
import 'package:sufradepi/features/reminders/data/reminder_scheduler.dart';
import 'package:sufradepi/features/reminders/data/reminder_store.dart';
import 'package:sufradepi/features/reminders/domain/reminder_models.dart';
import 'package:sufradepi/features/reminders/domain/reminder_plan.dart';
import 'package:sufradepi/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const texts = ReminderTexts(
  title: 'سفرة',
  water: 'وقت المية',
  weight: 'وقت تسجل وزنك',
  meals: {
    'breakfast': 'الفطار',
    'lunch': 'الغدا',
    'dinner': 'العشا',
    'snack': 'سناك',
  },
);

class FakeNotifier implements ReminderNotifier {
  bool enabled = true;
  bool grant = true;
  int prompts = 0;
  bool failSchedule = false;
  bool failCancel = false;
  bool failPendingRead = false;
  bool dropSchedules = false;
  bool ghostPending = false; // cancel 'succeeds' but alarm stays
  final Map<int, (PlannedReminder, tz.TZDateTime)> pending = {};
  final List<String> log = [];

  @override
  Future<bool> areNotificationsEnabled() async => enabled;
  @override
  Future<bool> requestPermission() async {
    prompts++;
    if (grant) enabled = true;
    return enabled;
  }

  @override
  Future<void> schedule(
    PlannedReminder r, {
    required tz.TZDateTime first,
    required ReminderTexts texts,
  }) async {
    if (failSchedule) throw StateError('x');
    log.add('schedule ${r.id}');
    if (!dropSchedules) pending[r.id] = (r, first);
  }

  @override
  Future<void> cancel(int id) async {
    if (failCancel) throw StateError('cancel');
    log.add('cancel $id');
    if (!ghostPending) pending.remove(id);
  }

  @override
  Future<Set<int>> pendingIds() async {
    if (failPendingRead) throw StateError('read');
    return pending.keys.toSet();
  }
}

void main() {
  tzdata.initializeTimeZones();
  final cairo = tz.getLocation('Africa/Cairo');

  test(
    'scheduler does not claim OS schedule if platform drops it or cannot verify',
    () async {
      final n = FakeNotifier()..dropSchedules = true;
      final scheduler = ReminderScheduler(
        notifier: n,
        location: () async => cairo,
      );
      final settings = ReminderSettings.empty.withMeal(
        'lunch',
        const MealReminder(enabled: true, minute: 840),
      );
      expect(
        await scheduler.sync(uid: 'a', settings: settings, texts: texts),
        SyncStatus.failed,
      );
      n
        ..dropSchedules = false
        ..failPendingRead = true;
      expect(
        await scheduler.sync(uid: 'a', settings: settings, texts: texts),
        SyncStatus.failed,
      );
      n.failPendingRead = false;
      expect(
        await scheduler.sync(uid: 'a', settings: settings, texts: texts),
        SyncStatus.ok,
      );
    },
  );
  group('ids and plan', () {
    test('ids are stable, unique, in range', () {
      expect(ReminderIds.meal('breakfast'), 710200);
      expect(ReminderIds.meal('snack'), 710203);
      expect(ReminderIds.water(0), 710100);
      expect(ReminderIds.all.toSet().length, ReminderIds.all.length);
      expect(ReminderIds.all.length, 12 + 4 + 1);
      expect(() => ReminderIds.meal('brunch'), throwsArgumentError);
      expect(() => ReminderIds.water(12), throwsRangeError);
    });
    test('nothing is planned until enabled with a time', () {
      expect(planReminders(ReminderSettings.empty, texts), isEmpty);
      final s = ReminderSettings.empty.withMeal(
        'lunch',
        const MealReminder(enabled: true),
      );
      expect(planReminders(s, texts), isEmpty);
    });
    test(
      'plan: water sorted unique slots, meal, weekly weight, generic bodies',
      () {
        final s = ReminderSettings(
          water: const WaterReminders(enabled: true, times: [900, 600, 600]),
          meals: {'dinner': const MealReminder(enabled: true, minute: 1200)},
          weight: const WeightReminder(
            enabled: true,
            minute: 480,
            weekday: DateTime.friday,
          ),
        );
        final p = planReminders(s, texts);
        expect(p.map((e) => (e.id, e.minute)), [
          (710100, 600),
          (710101, 900),
          (710201 + 1, 1200),
          (710300, 480),
        ]);
        expect(p.last.weekday, 5);
        for (final r in p) {
          expect(
            RegExp(r'\d').hasMatch(r.body),
            isFalse,
            reason: 'no values in lock-screen text',
          );
          expect(ReminderPayload.kindOf(r.payload), r.kind);
        }
      },
    );
    test('payload parsing', () {
      expect(ReminderPayload.kindOf('x'), isNull);
      expect(ReminderPayload.kindOf(null), isNull);
      expect(
        ReminderPayload.kindOf(ReminderPayload.meal('lunch')),
        ReminderKind.meal,
      );
    });
  });

  group('nextOccurrence', () {
    PlannedReminder daily(int m) => PlannedReminder(
      id: 1,
      kind: ReminderKind.water,
      minute: m,
      body: '',
      payload: '',
    );
    test('later today vs tomorrow', () {
      final now = tz.TZDateTime(cairo, 2026, 11, 22, 9);
      expect(
        nextOccurrence(daily(600), cairo, now),
        tz.TZDateTime(cairo, 2026, 11, 22, 10),
      );
      expect(
        nextOccurrence(daily(540), cairo, now),
        tz.TZDateTime(cairo, 2026, 11, 23, 9),
      ); // equal is not after
      expect(
        nextOccurrence(daily(480), cairo, now),
        tz.TZDateTime(cairo, 2026, 11, 23, 8),
      );
    });
    test('weekly lands on the weekday', () {
      final r = PlannedReminder(
        id: 2,
        kind: ReminderKind.weight,
        minute: 480,
        weekday: DateTime.friday,
        body: '',
        payload: '',
      );
      final now = tz.TZDateTime(cairo, 2026, 11, 22, 9); // Sunday
      final d = nextOccurrence(r, cairo, now);
      expect(d.weekday, DateTime.friday);
      expect(d, tz.TZDateTime(cairo, 2026, 11, 27, 8));
    });
    test('wall-clock time survives a DST change', () {
      // Egypt springs forward on the last Friday of April.
      final before = tz.TZDateTime(cairo, 2026, 4, 20, 12);
      final d = nextOccurrence(daily(480), cairo, before);
      expect((d.hour, d.minute), (8, 0));
      final after = nextOccurrence(
        daily(480),
        cairo,
        tz.TZDateTime(cairo, 2026, 4, 30, 12),
      );
      expect((after.hour, after.minute), (8, 0));
      expect(after.timeZoneOffset != d.timeZoneOffset, isTrue);
    });
    test('same instant, different device zone, different first time', () {
      final ny = tz.getLocation('America/New_York');
      final instant = DateTime.utc(2026, 11, 22, 7); // 09:00 Cairo, 02:00 NY
      final c = nextOccurrence(
        daily(600),
        cairo,
        tz.TZDateTime.from(instant, cairo),
      );
      final n = nextOccurrence(daily(600), ny, tz.TZDateTime.from(instant, ny));
      expect(c.toUtc() != n.toUtc(), isTrue);
    });
  });

  group('settings json', () {
    test('roundtrip', () {
      final s = ReminderSettings(
        water: const WaterReminders(enabled: true, times: [600, 900]),
        meals: {'lunch': const MealReminder(enabled: true, minute: 840)},
        weight: const WeightReminder(enabled: true, minute: 480, weekday: 6),
      );
      final r = ReminderSettings.fromJson(s.toJson());
      expect(r.water.times, [600, 900]);
      expect(r.meal('lunch').minute, 840);
      expect(r.weight.weekday, 6);
      expect(r.anyEnabled, isTrue);
    });
    test('corrupt or incomplete data becomes off, never a guess', () {
      expect(ReminderSettings.fromJson('not json').anyEnabled, isFalse);
      expect(ReminderSettings.fromJson(null).anyEnabled, isFalse);
      expect(ReminderSettings.fromJson('[]').anyEnabled, isFalse);
      final r = ReminderSettings.fromJson(
        '{"water":{"enabled":true,"times":[99999,-1,"x"]},"meals":{"lunch":{"enabled":true},"brunch":{"enabled":true,"minute":5}},"weight":{"enabled":true,"minute":10}}',
      );
      expect(r.water.enabled, isFalse);
      expect(r.meal('lunch').enabled, isFalse);
      expect(r.meals.containsKey('brunch'), isFalse);
      expect(r.weight.enabled, isFalse);
    });
    test('store is per account', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ReminderStore(await SharedPreferences.getInstance());
      await store.save(
        'a',
        ReminderSettings.empty.withMeal(
          'lunch',
          const MealReminder(enabled: true, minute: 800),
        ),
      );
      expect(store.load('a').meal('lunch').enabled, isTrue);
      expect(store.load('b').anyEnabled, isFalse);
      expect(store.load('').anyEnabled, isFalse);
    });
  });

  group('scheduler', () {
    late FakeNotifier n;
    late ReminderScheduler sch;
    final now = DateTime.utc(2026, 11, 22, 7);
    setUp(() {
      n = FakeNotifier();
      sch = ReminderScheduler(
        notifier: n,
        location: () async => cairo,
        clock: () => now,
      );
    });
    final lunch = ReminderSettings.empty.withMeal(
      'lunch',
      const MealReminder(enabled: true, minute: 840),
    );

    test('schedules planned, first fire is local wall-clock', () async {
      expect(
        await sch.sync(uid: 'a', settings: lunch, texts: texts),
        SyncStatus.ok,
      );
      final (r, first) = n.pending[ReminderIds.meal('lunch')]!;
      expect(r.body, 'الغدا');
      expect((first.hour, first.minute), (14, 0));
      expect(n.pending.length, 1);
    });
    test('reschedule replaces the same id, no duplicates', () async {
      await sch.sync(uid: 'a', settings: lunch, texts: texts);
      final moved = lunch.withMeal(
        'lunch',
        const MealReminder(enabled: true, minute: 900),
      );
      await sch.sync(uid: 'a', settings: moved, texts: texts);
      expect(n.pending.length, 1);
      expect(n.pending[ReminderIds.meal('lunch')]!.$2.hour, 15);
    });
    test('disable cancels exactly that id', () async {
      final both = lunch.withMeal(
        'dinner',
        const MealReminder(enabled: true, minute: 1200),
      );
      await sch.sync(uid: 'a', settings: both, texts: texts);
      final off = both.withMeal(
        'lunch',
        const MealReminder(enabled: false, minute: 840),
      );
      expect(
        await sch.sync(uid: 'a', settings: off, texts: texts),
        SyncStatus.ok,
      );
      expect(n.pending.keys, [ReminderIds.meal('dinner')]);
    });
    test('removing a water time frees its slot', () async {
      final w = ReminderSettings(
        water: const WaterReminders(enabled: true, times: [600, 900]),
      );
      await sch.sync(uid: 'a', settings: w, texts: texts);
      expect(n.pending.length, 2);
      await sch.sync(
        uid: 'a',
        settings: ReminderSettings(
          water: const WaterReminders(enabled: true, times: [900]),
        ),
        texts: texts,
      );
      expect(n.pending.keys, [ReminderIds.water(0)]);
      expect(n.pending.values.single.$1.minute, 900);
    });
    test(
      'sign-out or account switch cancels everything of the old account',
      () async {
        await sch.sync(uid: 'a', settings: lunch, texts: texts);
        expect(await sch.cancelAllVerified(), isTrue);
        expect(n.pending, isEmpty);
        await sch.sync(uid: 'a', settings: lunch, texts: texts);
        await sch.sync(
          uid: 'b',
          settings: ReminderSettings.empty,
          texts: texts,
        );
        expect(n.pending, isEmpty);
      },
    );
    test('permission off: nothing stays scheduled, status says so', () async {
      await sch.sync(uid: 'a', settings: lunch, texts: texts);
      n.enabled = false;
      expect(
        await sch.sync(uid: 'a', settings: lunch, texts: texts),
        SyncStatus.permissionDenied,
      );
      expect(n.pending, isEmpty);
    });
    test('timezone unresolved: no guessed schedule, existing kept', () async {
      await sch.sync(uid: 'a', settings: lunch, texts: texts);
      final bad = ReminderScheduler(
        notifier: n,
        location: () async => throw StateError('tz'),
        clock: () => now,
      );
      expect(
        await bad.sync(uid: 'a', settings: lunch, texts: texts),
        SyncStatus.timezoneUnavailable,
      );
      expect(n.pending.length, 1);
    });
    test('schedule failure is reported', () async {
      n.failSchedule = true;
      expect(
        await sch.sync(uid: 'a', settings: lunch, texts: texts),
        SyncStatus.failed,
      );
    });
    test('quick consecutive syncs are serialized', () async {
      final a = sch.sync(uid: 'a', settings: lunch, texts: texts);
      final b = sch.sync(
        uid: 'a',
        settings: ReminderSettings.empty,
        texts: texts,
      );
      await Future.wait([a, b]);
      expect(n.pending, isEmpty);
    });
  });

  group('cubit', () {
    late FakeNotifier n;
    late ReminderStore store;
    late ReminderScheduler sch;
    String? current;
    RemindersCubit make({String uid = 'a'}) => RemindersCubit(
      uid: uid,
      currentUid: () => current,
      store: store,
      scheduler: sch,
      notifier: n,
      texts: () => texts,
    );
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = ReminderStore(await SharedPreferences.getInstance());
      n = FakeNotifier()..enabled = false;
      sch = ReminderScheduler(
        notifier: n,
        location: () async => tz.getLocation('Africa/Cairo'),
        clock: () => DateTime.utc(2026, 11, 22, 7),
      );
      current = 'a';
    });

    test('loading with nothing saved never prompts', () async {
      final c = make();
      await c.load();
      expect(n.prompts, 0);
      expect(c.state.settings.anyEnabled, isFalse);
      await c.close();
    });
    test('permission is asked only when switching something on', () async {
      final c = make();
      await c.load();
      await c.setMealTime('lunch', 840);
      expect(n.prompts, 1);
      expect(n.pending.length, 1);
      await c.setMealTime('dinner', 1200);
      expect(n.prompts, 1, reason: 'already granted');
      await c.setMealEnabled('lunch', false);
      expect(n.pending.keys, [ReminderIds.meal('dinner')]);
      await c.close();
    });
    test('denied: nothing saved or scheduled, notice and banner', () async {
      n.grant = false;
      final c = make();
      await c.load();
      await c.setWeightSchedule(weekday: 5, minute: 480);
      expect(c.state.notice, RemindersNotice.permissionDenied);
      expect(c.state.permissionDenied, isTrue);
      expect(c.state.settings.anyEnabled, isFalse);
      expect(store.load('a').anyEnabled, isFalse);
      expect(n.pending, isEmpty);
      await c.close();
    });
    test(
      'disabling works even when permission was revoked, without prompting',
      () async {
        final c = make();
        await c.load();
        await c.addWaterTime(600);
        n.enabled = false;
        final before = n.prompts;
        await c.setWaterEnabled(false);
        expect(n.prompts, before);
        expect(n.pending, isEmpty);
        expect(store.load('a').water.enabled, isFalse);
        expect(store.load('a').water.times, [600]);
        await c.close();
      },
    );
    test('toggle on without a time is a no-op; water cap', () async {
      final c = make();
      await c.load();
      await c.setWaterEnabled(true);
      await c.setMealEnabled('lunch', true);
      await c.setWeightEnabled(true);
      expect(c.state.settings.anyEnabled, isFalse);
      expect(n.prompts, 0);
      for (var i = 0; i < 12; i++) {
        await c.addWaterTime(300 + i * 60);
      }
      await c.addWaterTime(1300);
      expect(c.state.notice, RemindersNotice.waterFull);
      expect(c.state.settings.water.times.length, 12);
      await c.close();
    });
    test('persisted settings are re-applied on load (restart)', () async {
      final c = make();
      await c.load();
      await c.setMealTime('breakfast', 480);
      await c.close();
      n.pending.clear(); // OS lost them
      final c2 = make();
      await c2.load();
      expect(n.pending.keys, [ReminderIds.meal('breakfast')]);
      await c2.close();
    });
    test(
      'account switch: old cubit does nothing; new account sees its own settings',
      () async {
        final c = make();
        await c.load();
        await c.setMealTime('lunch', 840);
        current = 'b';
        await c.setMealTime('dinner', 1200);
        expect(store.load('a').meal('dinner').enabled, isFalse);
        final cb = make(uid: 'b');
        await cb.load();
        expect(cb.state.settings.anyEnabled, isFalse);
        expect(
          n.pending,
          isEmpty,
          reason: 'b has none, a was cancelled by b sync',
        );
        await c.close();
        await cb.close();
      },
    );
    test('schedule failure keeps the choice but flags a problem', () async {
      final c = make();
      await c.load();
      n.enabled = true;
      n.failSchedule = true;
      await c.setMealTime('lunch', 840);
      expect(c.state.notice, RemindersNotice.scheduleFailed);
      expect(c.state.scheduleProblem, isTrue);
      expect(c.state.settings.meal('lunch').enabled, isTrue);
      await c.close();
    });
  });
}
