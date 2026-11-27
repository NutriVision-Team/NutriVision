/// Session-only choices carried on explicit navigation. Never external context.
class PlannerFoodChoices {
  const PlannerFoodChoices({
    this.ownerUid = '',
    this.preferred = const [],
    this.excluded = const [],
    this.allergens = const [],
    this.dietaryPreferences = const [],
    this.requiresProfessionalReview = false,
    this.mealsPerDay,
  });
  final String ownerUid;
  final List<String> preferred, excluded, allergens, dietaryPreferences;
  final bool requiresProfessionalReview;
  final int? mealsPerDay;
  bool appliesTo(String uid) => ownerUid.isNotEmpty && uid == ownerUid;
}
