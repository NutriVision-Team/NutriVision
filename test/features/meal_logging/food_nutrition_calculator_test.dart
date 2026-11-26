import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/meal_logging/domain/food_nutrition_calculator.dart';

void main() {
  const calculator = FoodNutritionCalculator();

  const baladiBread = NutrientsPer100g(
    energyKcal: 244,
    proteinG: 8.9,
    fatG: 0.6,
    carbohydrateG: 54.8,
    fiberG: 0.8,
  );

  test('100g reference amount returns the source values', () {
    final totals = calculator.calculate([
      const FoodPortion(
        foodId: 'bread_baladi_brown',
        quantityGrams: 100,
        per100g: baladiBread,
      ),
    ]);
    expect(totals.energyKcal, closeTo(244, 1e-9));
    expect(totals.proteinG, closeTo(8.9, 1e-9));
  });

  test('half portion halves every nutrient', () {
    final totals = calculator.calculate([
      const FoodPortion(
        foodId: 'bread_baladi_brown',
        quantityGrams: 50,
        per100g: baladiBread,
      ),
    ]);
    expect(totals.energyKcal, closeTo(122, 1e-9));
    expect(totals.carbohydrateG, closeTo(27.4, 1e-9));
  });

  test('double portion doubles every nutrient', () {
    final totals = calculator.calculate([
      const FoodPortion(
        foodId: 'bread_baladi_brown',
        quantityGrams: 200,
        per100g: baladiBread,
      ),
    ]);
    expect(totals.energyKcal, closeTo(488, 1e-9));
    expect(totals.fatG, closeTo(1.2, 1e-9));
  });

  test('multiple ingredients are summed', () {
    const cheese = NutrientsPer100g(
      energyKcal: 300,
      proteinG: 20,
      fatG: 24,
      carbohydrateG: 2,
    );
    final totals = calculator.calculate([
      const FoodPortion(
        foodId: 'bread',
        quantityGrams: 100,
        per100g: baladiBread,
      ),
      const FoodPortion(foodId: 'cheese', quantityGrams: 30, per100g: cheese),
    ]);
    expect(totals.energyKcal, closeTo(244 + 90, 1e-9));
    expect(totals.proteinG, closeTo(8.9 + 6, 1e-9));
  });

  test('null nutrient stays null and marks the result incomplete', () {
    final totals = calculator.calculate([
      const FoodPortion(
        foodId: 'bread_baladi_brown',
        quantityGrams: 100,
        per100g: baladiBread, // sugars/sodium unknown
      ),
    ]);
    expect(totals.sugarsG, isNull);
    expect(totals.sodiumMg, isNull);
    expect(totals.isComplete, isFalse);
    // Known nutrients are still calculated, never replaced by zero.
    expect(totals.proteinG, isNotNull);
  });

  test('serving count multiplies the portion', () {
    final totals = calculator.calculate([
      const FoodPortion(
        foodId: 'bread_baladi_brown',
        quantityGrams: 100,
        per100g: baladiBread,
        servings: 2,
      ),
    ]);
    expect(totals.energyKcal, closeTo(488, 1e-9));
  });

  test('empty input returns zero calories and complete', () {
    final totals = calculator.calculate(const []);
    expect(totals.energyKcal, 0);
    expect(totals.isComplete, isTrue);
  });
}
