import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/meal_log/domain/meal_budget_preview.dart';

void main() {
  test('budget is comparison only, preserves over-target sign', () {
    final p = MealBudgetPreview.calculate(
      target: 2000,
      consumed: 1800,
      meal: 300,
    )!;
    expect(p.before, 200);
    expect(p.after, -100);
  });
  test('missing or invalid inputs never become zero targets', () {
    for (final v in <double?>[null, 0, -1, double.nan, double.infinity]) {
      expect(
        MealBudgetPreview.calculate(target: v, consumed: 420, meal: 100),
        isNull,
      );
    }
    expect(
      MealBudgetPreview.calculate(target: 2000, consumed: 420, meal: null),
      isNull,
    );
  });
  test('known zero meal remains valid', () {
    expect(
      MealBudgetPreview.calculate(target: 2000, consumed: 420, meal: 0)!.after,
      1580,
    );
  });
}
