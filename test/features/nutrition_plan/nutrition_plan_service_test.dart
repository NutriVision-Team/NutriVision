import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/nutrition_plan/domain/nutrition_plan_service.dart';

void main() {
  const service = NutritionPlanService();
  final reference = DateTime(2026, 11, 22);

  NutritionPlanInput baseInput({
    String gender = 'male',
    DateTime? dob,
    double height = 175,
    double weight = 90,
    double target = 80,
    String activity = 'moderate',
    String goal = 'lose',
  }) {
    return NutritionPlanInput(
      gender: gender,
      dateOfBirth: dob ?? DateTime(2000, 8, 7),
      heightCm: height,
      currentWeightKg: weight,
      targetWeightKg: target,
      activityLevel: activity,
      nutritionGoal: goal,
      referenceDate: reference,
    );
  }

  test('age calculation handles birthdays correctly', () {
    expect(service.ageAt(DateTime(2000, 8, 7), reference), 26);
    expect(service.ageAt(DateTime(2000, 12, 31), reference), 25);
  });

  test('Mifflin-St Jeor BMR for men and women', () {
    // 10*80 + 6.25*175 - 5*26 + 5 = 800 + 1093.75 - 130 + 5 = 1768.75
    final male = service.bmr(
      gender: 'male',
      weightKg: 80,
      heightCm: 175,
      age: 26,
    );
    expect(male, closeTo(1768.75, 0.01));
    final female = service.bmr(
      gender: 'female',
      weightKg: 80,
      heightCm: 175,
      age: 26,
    );
    expect(female, closeTo(1768.75 - 166, 0.01));
  });

  test('weight loss subtracts 500 kcal from TDEE', () {
    final plan = service.compute(baseInput(weight: 80, target: 75));
    // BMR 1768.75 * 1.55 = 2741.5625; minus 500 = 2241.56 -> 2242
    expect(plan.dailyCalories, 2242);
    expect(plan.estimatedWeeks, 10); // 5kg / 0.5kg per week
  });

  test('maintenance keeps TDEE and reports no timeline', () {
    final plan = service.compute(baseInput(goal: 'maintain', target: 90));
    expect(plan.dailyCalories, (1868.75 * 1.55).round());
    expect(plan.estimatedWeeks, 0);
  });

  test('weight gain adds 300 kcal', () {
    final plan = service.compute(
      baseInput(goal: 'gain', weight: 60, target: 70),
    );
    // BMR: 10*60 + 6.25*175 - 5*26 + 5 = 1568.75; *1.55 = 2431.5625; +300 = 2731.56
    expect(plan.dailyCalories, 2732);
    expect(plan.estimatedWeeks, 40); // 10kg / 0.25kg per week
  });

  test('calories never drop below the safe floor', () {
    final plan = service.compute(
      baseInput(
        gender: 'female',
        height: 120,
        weight: 30,
        activity: 'sedentary',
      ),
    );
    expect(plan.dailyCalories, greaterThanOrEqualTo(1200));
  });

  test('macros are internally consistent with calories', () {
    final plan = service.compute(baseInput());
    final macroCalories =
        plan.proteinGrams * 4 + plan.carbsGrams * 4 + plan.fatGrams * 9;
    // Carbs absorb rounding, so allow a small tolerance.
    expect(macroCalories, closeTo(plan.dailyCalories, 60));
  });

  test('rejects out-of-range profile values', () {
    expect(
      () => service.compute(baseInput(height: 100)),
      throwsA(isA<NutritionPlanException>()),
    );
    expect(
      () => service.compute(baseInput(weight: 500)),
      throwsA(isA<NutritionPlanException>()),
    );
    expect(
      () => service.compute(baseInput(dob: DateTime(2020, 1, 1))),
      throwsA(isA<NutritionPlanException>()),
    );
  });

  test('rejects unknown activity level and goal', () {
    expect(
      () => service.compute(baseInput(activity: 'extreme')),
      throwsA(isA<NutritionPlanException>()),
    );
    expect(
      () => service.compute(baseInput(goal: 'shred')),
      throwsA(isA<NutritionPlanException>()),
    );
  });
}
