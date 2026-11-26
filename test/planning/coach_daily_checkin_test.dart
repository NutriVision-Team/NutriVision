import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'package:sufradepi/features/coach/domain/coach_daily_checkin.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_daily_checkin_screen.dart';
import 'screens_smoke_test.dart' show SmokeNutritionRepository;

void main() {
  late String owner;
  late DateTime now;
  late CoachCubit c;
  setUp(() {
    owner = 'u1';
    now = DateTime(2026, 11, 25);
    c = CoachCubit(
      userId: 'u1',
      currentUid: () => owner,
      store: SessionCoachStore(ownerUid: 'u1', currentUid: () => owner),
      nutrition: SmokeNutritionRepository(),
      locale: 'en',
      clock: () => now,
    );
  });
  tearDown(() async => c.close());
  test(
    'optional unknowns explicit zero bounds owner rollover and disposal',
    () {
      expect(c.dailyCheckin.empty, true);
      c.updateDailyCheckin(
        const CoachDailyCheckin(
          activityMinutes: 0,
          sleepHours: 7.5,
          feeling: 'okay',
        ),
      );
      expect(c.dailyCheckin.activityMinutes, 0);
      expect(c.dailyCheckin.sleepHours, 7.5);
      expect(
        () =>
            c.updateDailyCheckin(const CoachDailyCheckin(activityMinutes: -1)),
        throwsArgumentError,
      );
      expect(
        () => c.updateDailyCheckin(const CoachDailyCheckin(sleepHours: 25)),
        throwsArgumentError,
      );
      expect(
        () => c.updateDailyCheckin(CoachDailyCheckin(sleepHours: double.nan)),
        throwsArgumentError,
      );
      expect(
        () =>
            c.updateDailyCheckin(const CoachDailyCheckin(feeling: 'diagnosed')),
        throwsArgumentError,
      );
      now = DateTime(2026, 11, 26);
      expect(c.dailyCheckin.empty, true);
      c.updateDailyCheckin(const CoachDailyCheckin(feeling: 'good'));
      owner = 'u2';
      expect(c.dailyCheckin.empty, true);
      expect(
        () => c.updateDailyCheckin(const CoachDailyCheckin(feeling: 'good')),
        throwsStateError,
      );
    },
  );
  testWidgets(
    'Arabic digits saved only on explicit session button, clear removes notes',
    (t) async {
      await t.pumpWidget(MaterialApp(home: CoachDailyCheckinScreen(cubit: c)));
      await t.enterText(find.byKey(const ValueKey('daily_activity')), '٣٠');
      await t.enterText(find.byKey(const ValueKey('daily_sleep')), '٧٫٥');
      expect(c.dailyCheckin.empty, true);
      await t.tap(find.byKey(const ValueKey('daily_feeling_okay')));
      await t.pump();
      final save = find.byKey(const ValueKey('daily_save'));
      await t.ensureVisible(save);
      await t.pump();
      await t.tap(save);
      await t.pump();
      expect(c.dailyCheckin.activityMinutes, 30);
      expect(c.dailyCheckin.sleepHours, 7.5);
      expect(c.dailyCheckin.feeling, 'okay');
      await t.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: CoachDailyCheckinScreen(cubit: c),
        ),
      );
      await t.pump();
      final clear = find.byKey(const ValueKey('daily_clear'));
      await t.ensureVisible(clear);
      await t.pump();
      await t.tap(clear);
      await t.pump();
      expect(c.dailyCheckin.empty, true);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('midnight never saves yesterday fields into today', (t) async {
    await t.pumpWidget(MaterialApp(home: CoachDailyCheckinScreen(cubit: c)));
    await t.enterText(find.byKey(const ValueKey('daily_activity')), '20');
    now = DateTime(2026, 11, 26);
    final save = find.byKey(const ValueKey('daily_save'));
    await t.ensureVisible(save);
    await t.pump();
    await t.tap(save);
    await t.pump();
    expect(c.dailyCheckin.empty, true);
    expect(
      find.text('The day changed. Review today before saving.'),
      findsOneWidget,
    );
    await t.pumpWidget(const SizedBox());
  });
}
