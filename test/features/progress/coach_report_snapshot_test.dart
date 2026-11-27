import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/progress/export/coach_report_snapshot.dart';

void main() {
  test(
    'built-in goal IDs localize, free text stays exact and singular grammar',
    () {
      final s = CoachReportSnapshot(
        ownerUid: 'u',
        goals: ['food_variety', 'meal_routine', 'تنويع الأكل', 'my own goal'],
        checkins: {
          '2026-11-25': {'log_meal'},
        },
      );
      expect(s.goalLabels(false), [
        'Food variety',
        'Meal routine',
        'تنويع الأكل',
        'my own goal',
      ]);
      expect(s.goalLabels(true).first, 'تنويع الأكل');
      expect(s.summary(false), '1 check-in across 1 day in this period');
    },
  );
  test('snapshot immutable, owner-bound and selected-range only', () {
    final goals = ['food variety'];
    final habits = ['log_meal'];
    final marks = <String, Set<String>>{
      '2026-11-25': {'log_meal'},
      '2026-11-24': {'prepare_meal'},
      '2026-10-01': {'log_meal'},
    };
    final s = CoachReportSnapshot(
      ownerUid: 'u1',
      goals: goals,
      habits: habits,
      checkins: marks,
    );
    goals.clear();
    habits.clear();
    marks['2026-11-25']!.clear();
    expect(s.goals, ['food variety']);
    expect(s.habits, ['log_meal']);
    expect(s.forOwner('u2'), isNull);
    expect(s.forOwner(null), isNull);
    expect(s.forOwner('u1'), same(s));
    for (final dates in [
      <String>{'2026-11-25'},
      <String>{'2026-11-24', '2026-11-25'},
      <String>{'2026-11-01', '2026-11-24', '2026-11-25'},
    ]) {
      final range = s.forDates(dates);
      expect(range.confirmations, dates.length == 1 ? 1 : 2);
      expect(range.checkins.containsKey('2026-10-01'), false);
    }
    expect(s.forDates({'2026-11-23'}).checkins, isEmpty);
    expect(
      () => s.checkins['2026-11-25']!.add('other'),
      throwsUnsupportedError,
    );
  });
}
