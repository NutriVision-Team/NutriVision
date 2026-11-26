import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/coach/domain/coach_progress_comparison.dart';
import 'weekly_personal_review_test.dart' show m;

void main() {
  test(
    'next action uses records and explicit check-ins, never awards success',
    () {
      final base = m('detailed', '2026-11-25');
      final detailed = MealEntryModel.fromMap('detailed', {
        ...base.toMap(),
        'createdAt': null,
        'updatedAt': null,
        'items': [
          {
            'foodId': 'rice',
            'foodName': 'rice',
            'weightInGrams': 100,
            'calories': 130,
            'quantity': 1,
            'unit': 'g',
          },
        ],
      });
      final noCheck = CoachProgressComparison(
        todayKey: '2026-11-25',
        days: 7,
        meals: [detailed],
        checkins: {},
      );
      expect(noCheck.nextAction, 'checkin');
      final checked = CoachProgressComparison(
        todayKey: '2026-11-25',
        days: 7,
        meals: [detailed],
        checkins: {
          '2026-11-25': {'log_meal'},
        },
      );
      expect(checked.nextAction, 'plan');
      expect(checked.current.ingredientFoods, 1);
    },
  );
  test('adjacent inclusive weeks exclude future and older records', () {
    final c = CoachProgressComparison(
      todayKey: '2026-11-25',
      days: 7,
      meals: [
        m('a', '2026-11-25'),
        m('b', '2026-11-19'),
        m('c', '2026-11-18'),
        m('d', '2026-11-12'),
        m('old', '2026-11-11'),
        m('future', '2026-11-26'),
      ],
      checkins: {
        '2026-11-25': {'log_meal', 'unknown'},
        '2026-11-19': {'prepare_meal'},
        '2026-11-18': {'log_meal'},
        '2026-11-11': {'log_meal'},
      },
    );
    expect(c.current.loggedDays, 2);
    expect(c.previous.loggedDays, 2);
    expect(c.currentConfirmations, 2);
    expect(c.previousConfirmations, 1);
    expect(c.range(false), '2026-11-19 / 2026-11-25');
    expect(c.range(true), '2026-11-12 / 2026-11-18');
    expect(c.nextAction, 'ingredients');
  });
  test('empty is an empty record, not proof of failed habits', () {
    final c = CoachProgressComparison(
      todayKey: '2026-11-25',
      days: 30,
      meals: [],
      checkins: {},
    );
    expect(c.nextAction, 'diary');
    expect(c.previous.records, isEmpty);
    expect(c.current.measuredAverage((m) => m.totalFiber).average, isNull);
    expect(c.range(true), '2026-09-27 / 2026-10-26');
  });
  test('invalid windows rejected and calendar month crossing works', () {
    expect(
      () => CoachProgressComparison(
        todayKey: '2026-11-25',
        days: 0,
        meals: [],
        checkins: {},
      ),
      throwsArgumentError,
    );
    final c = CoachProgressComparison(
      todayKey: '2026-03-01',
      days: 1,
      meals: [m('x', '2026-02-28')],
      checkins: {},
    );
    expect(c.previous.loggedDays, 1);
    expect(c.current.loggedDays, 0);
  });
}
