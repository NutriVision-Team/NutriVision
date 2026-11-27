/// Optional health context. No field is required for basic chat.
/// External inference and durable memory are separate, revocable choices.
class HealthCoachConsent {
  const HealthCoachConsent({
    this.externalAi = false,
    this.profileContext = false,
    this.recordContext = false,
    this.conversationContext = false,
    this.durableMemory = false,
  });
  final bool externalAi;
  final bool profileContext;
  final bool recordContext;
  final bool conversationContext;
  final bool durableMemory;
}

class HealthCoachProfile {
  const HealthCoachProfile({
    this.age,
    this.heightCm,
    this.weightKg,
    this.activity,
    this.lifestyle,
    this.sleepSchedule,
    this.preferredFoods = const [],
    this.excludedFoods = const [],
    this.allergens = const [],
    this.dietaryRestrictions = const [],
    this.goals = const [],
    this.budgetDescription,
    this.mealsPerDay,
    this.preparationMinutes,
    this.disclosedConditions = const [],
    this.specialistGuidance,
  });

  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? activity;
  final String? lifestyle;
  final String? sleepSchedule;
  final List<String> preferredFoods;
  final List<String> excludedFoods;
  final List<String> allergens;
  final List<String> dietaryRestrictions;
  final List<String> goals;
  final String? budgetDescription;
  final int? mealsPerDay;
  final int? preparationMinutes;
  final List<String> disclosedConditions;
  final String? specialistGuidance;

  factory HealthCoachProfile.fromSaved(
    Map<String, Object> m, {
    List<String> goals = const [],
  }) {
    List<String> list(String k) =>
        (m[k] as List?)?.whereType<String>().toList() ?? [];
    return HealthCoachProfile(
      age: (m['age'] as num?)?.toInt(),
      heightCm: (m['heightCm'] as num?)?.toDouble(),
      weightKg: (m['weightKg'] as num?)?.toDouble(),
      activity: m['activity'] as String?,
      lifestyle: m['lifestyle'] as String?,
      sleepSchedule: m['sleepSchedule'] as String?,
      preferredFoods: list('preferredFoods'),
      excludedFoods: list('excludedFoods'),
      allergens: list('allergens'),
      dietaryRestrictions: list('dietaryRestrictions'),
      goals: goals,
      budgetDescription: m['budget'] as String?,
      mealsPerDay: (m['mealsPerDay'] as num?)?.toInt(),
      preparationMinutes: (m['preparationMinutes'] as num?)?.toInt(),
      disclosedConditions: list('conditions'),
      specialistGuidance: m['specialistGuidance'] as String?,
    );
  }

  /// Deliberately excludes account identifiers, email and bearer tokens.
  Map<String, Object> toContext() => {
    if (age != null) 'age': age!,
    if (heightCm != null) 'heightCm': heightCm!,
    if (weightKg != null) 'weightKg': weightKg!,
    if (activity != null) 'activity': activity!,
    if (lifestyle != null) 'lifestyle': lifestyle!,
    if (sleepSchedule != null) 'sleepSchedule': sleepSchedule!,
    if (preferredFoods.isNotEmpty) 'preferredFoods': preferredFoods,
    if (excludedFoods.isNotEmpty) 'excludedFoods': excludedFoods,
    if (allergens.isNotEmpty) 'allergens': allergens,
    if (dietaryRestrictions.isNotEmpty)
      'dietaryRestrictions': dietaryRestrictions,
    if (goals.isNotEmpty) 'goals': goals,
    if (budgetDescription != null) 'budget': budgetDescription!,
    if (mealsPerDay != null) 'mealsPerDay': mealsPerDay!,
    if (preparationMinutes != null) 'preparationMinutes': preparationMinutes!,
    if (disclosedConditions.isNotEmpty) 'conditions': disclosedConditions,
    if (specialistGuidance != null) 'specialistGuidance': specialistGuidance!,
  };
}

/// Verified facts only. Null nutrition is preserved as unknown by callers.
class CoachRecordFact {
  const CoachRecordFact({
    required this.key,
    required this.value,
    required this.source,
    this.date,
    this.unit,
  });
  final String key;
  final Object? value;
  final String source;
  final String? date, unit;
  Map<String, Object?> toContext() => {
    'key': key,
    'value': value,
    'source': source,
    if (date != null) 'date': date,
    if (unit != null) 'unit': unit,
  };
}

class CoachContextBuilder {
  const CoachContextBuilder();

  Map<String, Object> build({
    required HealthCoachConsent consent,
    required HealthCoachProfile profile,
    List<CoachRecordFact> facts = const [],
    List<String> recentConversation = const [],
    List<String> approvedMemories = const [],
  }) {
    if (!consent.externalAi) throw StateError('External AI consent required');
    return {
      if (consent.profileContext) 'profile': profile.toContext(),
      if (consent.recordContext)
        'facts': facts
            .where(
              (fact) =>
                  const {
                    'logged_energy',
                    'logged_protein',
                    'logged_carbohydrate',
                    'logged_fat',
                    'logged_fiber',
                    'logged_water',
                  }.contains(fact.key) &&
                  const {'diary', 'water_log'}.contains(fact.source) &&
                  fact.date != null &&
                  RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fact.date!) &&
                  const {'kcal', 'g', 'ml'}.contains(fact.unit) &&
                  (fact.value == null ||
                      (fact.value is num &&
                          (fact.value as num).isFinite &&
                          (fact.value as num) >= 0)),
            )
            .take(6)
            .map((fact) => fact.toContext())
            .toList(),
      if (consent.conversationContext)
        'recentConversation': recentConversation.reversed
            .take(8)
            .toList()
            .reversed
            .map((text) => text.length > 1000 ? text.substring(0, 1000) : text)
            .toList(),
      // Durable external memory is not part of the reviewed session scope.
    };
  }
}

/// Only stable built-in IDs are localized. Free text is preserved verbatim.
abstract final class CoachGoalLabels {
  static const ids = {'food_variety', 'meal_routine'};
  static String label(String value, bool ar) => switch (value) {
    'food_variety' => ar ? 'تنويع الأكل' : 'Food variety',
    'meal_routine' => ar ? 'تنظيم الوجبات' : 'Meal routine',
    _ => value,
  };
}
