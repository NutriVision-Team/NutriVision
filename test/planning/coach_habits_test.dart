import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_habits_screen.dart';
import 'screens_smoke_test.dart' show SmokeNutritionRepository;

void main() {
  late String owner;
  late DateTime now;
  CoachCubit make() => CoachCubit(
    userId: 'u1',
    currentUid: () => owner,
    store: SessionCoachStore(ownerUid: 'u1', currentUid: () => owner),
    nutrition: SmokeNutritionRepository(),
    locale: 'en',
    clock: () => now,
  );
  setUp(() {
    owner = 'u1';
    now = DateTime(2026, 11, 24, 23, 59);
  });
  test('explicit only, undo, deselect, unknown choice rejected', () async {
    final c = make();
    await c.load();
    expect(c.chosenHabits, isEmpty);
    expect(c.habitDone('log_meal'), false);
    expect(() => c.markHabit('log_meal', true), throwsStateError);
    expect(() => c.chooseHabit('unknown', true), throwsArgumentError);
    c.chooseHabit('log_meal', true);
    expect(c.habitDone('log_meal'), false);
    c.markHabit('log_meal', true);
    expect(c.habitDone('log_meal'), true);
    c.markHabit('log_meal', false);
    expect(c.habitDone('log_meal'), false);
    c.markHabit('log_meal', true);
    c.chooseHabit('log_meal', false);
    c.chooseHabit('log_meal', true);
    expect(c.habitDone('log_meal'), false);
    expect(c.state.entries, isEmpty);
    await c.close();
  });
  test(
    'next calendar day starts unchecked, new session empty, wrong owner blocked',
    () async {
      final c = make();
      c.chooseHabit('log_meal', true);
      c.markHabit('log_meal', true);
      now = DateTime(2026, 11, 25);
      expect(c.chosenHabits, contains('log_meal'));
      expect(c.habitDone('log_meal'), false);
      owner = 'u2';
      expect(c.chosenHabits, isEmpty);
      expect(c.habitDone('log_meal'), false);
      expect(() => c.markHabit('log_meal', true), throwsStateError);
      await c.close();
      owner = 'u1';
      final other = make();
      expect(other.chosenHabits, isEmpty);
      expect(other.habitDone('log_meal'), false);
      await other.close();
    },
  );
  test(
    'history includes explicit check-ins within inclusive dates and guards owner',
    () async {
      final c = make();
      c.chooseHabit('log_meal', true);
      c.markHabit('log_meal', true);
      now = DateTime(2026, 11, 25);
      expect(c.habitHistory(1), isEmpty);
      expect(c.habitHistory(7)['2026-11-24'], {'log_meal'});
      c.markHabit('log_meal', true);
      expect(c.habitHistory(1).length, 1);
      now = DateTime(2026, 12, 3);
      expect(c.habitHistory(7), isEmpty);
      owner = 'u2';
      expect(c.habitHistory(30), isEmpty);
      await c.close();
    },
  );
  testWidgets('choose, confirm and undo are explicit and visible', (
    tester,
  ) async {
    final c = make();
    await tester.pumpWidget(MaterialApp(home: CoachHabitsScreen(cubit: c)));
    await tester.pump();
    expect(find.text('Choose a step to track here.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('choose_log_meal')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Not checked in yet'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('complete_log_meal')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Done, confirmed by you'), findsOneWidget);
    await tester.tap(find.text('Undo check-in'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.habitDone('log_meal'), false);
    await tester.pumpWidget(const SizedBox());
    await c.close();
  });
  testWidgets('visible check-in refreshes after day changes', (tester) async {
    final c = make();
    c.chooseHabit('log_meal', true);
    c.markHabit('log_meal', true);
    await tester.pumpWidget(MaterialApp(home: CoachHabitsScreen(cubit: c)));
    expect(find.text('Done, confirmed by you'), findsOneWidget);
    now = DateTime(2026, 11, 25);
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('Not checked in yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await c.close();
  });
}
