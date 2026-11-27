import 'dart:math' as math;

/// Deterministic personal nutrition plan calculation.
///
/// Formula (documented, no AI involved):
/// - BMR: Mifflin-St Jeor
///   - male:   10·kg + 6.25·cm − 5·age + 5
///   - female: 10·kg + 6.25·cm − 5·age − 161
/// - TDEE = BMR × activity factor
/// - Goal adjustment: lose −500 kcal, maintain +0, gain +300 kcal,
///   clamped to a safe 1200..4000 kcal band.
/// - Macros: protein from goal-specific g/kg of current weight,
///   fat fixed at 25% of calories, carbs take the remainder.
class NutritionPlanResult {
  const NutritionPlanResult({
    required this.dailyCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.estimatedWeeks,
  });

  final double dailyCalories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  /// Indicative weeks to reach the target; 0 when maintaining.
  final int estimatedWeeks;
}

class NutritionPlanInput {
  NutritionPlanInput({
    required this.gender,
    required this.dateOfBirth,
    required this.heightCm,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.nutritionGoal,
    DateTime? referenceDate,
  }) : referenceDate = referenceDate ?? DateTime.now();

  final String gender; // 'male' | 'female'
  final DateTime dateOfBirth;
  final double heightCm;
  final double currentWeightKg;
  final double targetWeightKg;
  final String activityLevel; // sedentary|light|moderate|active
  final String nutritionGoal; // lose|maintain|gain
  final DateTime referenceDate;
}

class NutritionPlanException implements Exception {
  const NutritionPlanException(this.message);
  final String message;
  @override
  String toString() => 'NutritionPlanException: $message';
}

class NutritionPlanService {
  const NutritionPlanService();

  static const double _minCalories = 1200;
  static const double _maxCalories = 4000;

  static const Map<String, double> _activityFactors = {
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'active': 1.725,
  };

  /// Protein grams per kg of current body weight by goal.
  static const Map<String, double> _proteinPerKg = {
    'lose': 1.8,
    'maintain': 1.2,
    'gain': 2.0,
  };

  /// Expected weekly weight change rate (kg/week) by goal.
  static const Map<String, double> _weeklyRateKg = {'lose': 0.5, 'gain': 0.25};

  int ageAt(DateTime dateOfBirth, DateTime reference) {
    var age = reference.year - dateOfBirth.year;
    final hadBirthday =
        reference.month > dateOfBirth.month ||
        (reference.month == dateOfBirth.month &&
            reference.day >= dateOfBirth.day);
    if (!hadBirthday) age--;
    return age;
  }

  double bmr({
    required String gender,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender == 'female' ? base - 161 : base + 5;
  }

  NutritionPlanResult compute(NutritionPlanInput input) {
    final age = ageAt(input.dateOfBirth, input.referenceDate);

    // Validated profile constraints.
    if (age < 10 || age > 100) {
      throw const NutritionPlanException('Age must be between 10 and 100.');
    }
    if (input.heightCm < 120 || input.heightCm > 230) {
      throw const NutritionPlanException(
        'Height must be between 120 and 230 cm.',
      );
    }
    if (input.currentWeightKg < 30 || input.currentWeightKg > 300) {
      throw const NutritionPlanException(
        'Weight must be between 30 and 300 kg.',
      );
    }
    if (input.targetWeightKg < 30 || input.targetWeightKg > 300) {
      throw const NutritionPlanException(
        'Target weight must be between 30 and 300 kg.',
      );
    }
    final factor = _activityFactors[input.activityLevel];
    if (factor == null) {
      throw NutritionPlanException(
        'Unknown activity level: ${input.activityLevel}',
      );
    }
    if (!_proteinPerKg.containsKey(input.nutritionGoal)) {
      throw NutritionPlanException('Unknown goal: ${input.nutritionGoal}');
    }

    final bmrValue = bmr(
      gender: input.gender,
      weightKg: input.currentWeightKg,
      heightCm: input.heightCm,
      age: age,
    );
    var calories = bmrValue * factor;
    switch (input.nutritionGoal) {
      case 'lose':
        calories -= 500;
      case 'gain':
        calories += 300;
    }
    calories = calories.clamp(_minCalories, _maxCalories);

    final protein = _proteinPerKg[input.nutritionGoal]! * input.currentWeightKg;
    final fat = calories * 0.25 / 9;
    final carbs = math.max(0.0, (calories - protein * 4 - fat * 9) / 4);

    var weeks = 0;
    if (input.nutritionGoal != 'maintain') {
      final delta = (input.targetWeightKg - input.currentWeightKg).abs();
      weeks = (delta / _weeklyRateKg[input.nutritionGoal]!).ceil();
    }

    return NutritionPlanResult(
      dailyCalories: calories.roundToDouble(),
      proteinGrams: protein.roundToDouble(),
      carbsGrams: carbs.roundToDouble(),
      fatGrams: fat.roundToDouble(),
      estimatedWeeks: weeks,
    );
  }
}
