import '../../domain/recorded_meal_candidates.dart';
import '../../../alternatives/domain/food_preference_filter.dart';
import '../../domain/planner_food_choices.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../data/models/meal_plan_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../data/planner_repository.dart';
import '../../domain/weekly_plan_generator.dart';

@immutable
class PlannerState {
  const PlannerState({
    required this.status,
    required this.weekStart,
    this.plan,
    this.selectedDayIndex = 0,
    this.saving = false,
    this.missingTarget = false,
    this.constraintIssue,
    this.noAlternative = false,
    this.includeRecordedMeals = false,
    this.recordedCandidateCount,
  });

  final PlannerStatus status;
  final DateTime weekStart;
  final MealPlanModel? plan;
  final int selectedDayIndex;
  final bool saving;

  /// True when no active profile with a measured calorie target exists, so
  /// generation is honestly impossible until setup is completed.
  final bool missingTarget;
  // review: clinician/age constraint. unsupported: unknown dietary label.
  final String? constraintIssue;
  final bool noAlternative;
  final bool includeRecordedMeals;
  final int? recordedCandidateCount;

  PlannerState copyWith({
    PlannerStatus? status,
    MealPlanModel? plan,
    int? selectedDayIndex,
    bool? saving,
    bool? missingTarget,
    bool clearPlan = false,
    String? constraintIssue,
    bool clearConstraintIssue = false,
    bool? noAlternative,
    bool? includeRecordedMeals,
    int? recordedCandidateCount,
  }) => PlannerState(
    status: status ?? this.status,
    weekStart: weekStart,
    plan: clearPlan ? null : plan ?? this.plan,
    selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
    saving: saving ?? this.saving,
    missingTarget: missingTarget ?? this.missingTarget,
    noAlternative: noAlternative ?? this.noAlternative,
    includeRecordedMeals: includeRecordedMeals ?? this.includeRecordedMeals,
    recordedCandidateCount:
        recordedCandidateCount ?? this.recordedCandidateCount,
    constraintIssue: clearConstraintIssue
        ? null
        : constraintIssue ?? this.constraintIssue,
  );

  List<MealPlanMealModel> mealsForDay(int dayIndex) {
    final day = SufraDateUtils.shiftDays(weekStart, dayIndex);
    final key = _keyOf(day);
    final meals = plan?.meals ?? const <MealPlanMealModel>[];
    final dayMeals = meals
        .where(
          (m) =>
              (m.dateKey ?? WeeklyPlanGenerator.dateKeyOfMealId(m.mealId)) ==
              key,
        )
        .toList();
    dayMeals.sort(
      (a, b) => plannerSlots
          .indexOf(a.mealType)
          .compareTo(plannerSlots.indexOf(b.mealType)),
    );
    return dayMeals;
  }

  double caloriesForDay(int dayIndex) =>
      mealsForDay(dayIndex).fold(0.0, (sum, m) => sum + m.calories);

  static String _keyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

enum PlannerStatus { loading, ready, error }

/// Loads, generates and edits the current week's persisted plan. A plan is
/// only ever shown after it has actually been saved.
class PlannerCubit extends Cubit<PlannerState> {
  PlannerCubit({
    required this.userId,
    this.currentUid,
    required this.repository,
    required this.nutrition,
    required this.generator,
    required DateTime today,
    int Function()? seedProvider,
    this.foodChoices = const PlannerFoodChoices(),
  }) : _seedProvider = seedProvider ?? _defaultSeed,
       super(
         PlannerState(
           status: PlannerStatus.loading,
           weekStart: WeeklyPlanGenerator.weekStartOf(today),
           // Today's index inside its Saturday-first week.
           selectedDayIndex: SufraDateUtils.startOfDay(today)
               .difference(WeeklyPlanGenerator.weekStartOf(today))
               .inDays
               .clamp(0, 6),
         ),
       );

  final String userId;
  final String? Function()? currentUid;
  bool get inactive =>
      isClosed ||
      userId.isEmpty ||
      (currentUid != null && currentUid!() != userId);
  void assertActive() {
    if (inactive) throw StateError('Account no longer active');
  }

  @override
  void emit(PlannerState state) {
    if (!inactive) super.emit(state);
  }

  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }

  final PlannerRepository repository;
  final NutritionRepository nutrition;
  final WeeklyPlanGenerator generator;
  final PlannerFoodChoices foodChoices;
  PlannerFoodChoices get activeFoodChoices =>
      foodChoices.appliesTo(userId) ? foodChoices : const PlannerFoodChoices();
  final int Function() _seedProvider;

  static int _defaultSeed() => DateTime.now().microsecondsSinceEpoch;

  int _generation = 0;
  bool _generating = false;
  List<String> _profileAllergies = const [];
  List<String> _dietaryPreferences = const [];

  void setIncludeRecordedMeals(bool enabled) {
    if (!inactive && !state.saving) {
      emit(state.copyWith(includeRecordedMeals: enabled));
    }
  }

  Future<void> load() async {
    assertActive();
    final myGeneration = ++_generation;
    emit(state.copyWith(status: PlannerStatus.loading));
    try {
      if (userId.trim().isEmpty) throw ArgumentError.value(userId, 'userId');
      final plan = await repository.getPlan(
        userId,
        WeeklyPlanGenerator.planIdFor(state.weekStart),
      );
      final target = await _activeTarget();
      if (inactive || myGeneration != _generation) return;
      emit(
        state.copyWith(
          status: PlannerStatus.ready,
          plan: plan,
          clearPlan: plan == null,
          missingTarget: target == null,
        ),
      );
    } catch (_) {
      if (inactive || myGeneration != _generation) return;
      emit(state.copyWith(status: PlannerStatus.error));
    }
  }

  Future<double?> _activeTarget() async {
    assertActive();
    _profileAllergies = const [];
    _dietaryPreferences = const [];
    final profiles = await nutrition.getNutritionProfiles(userId);
    assertActive();
    for (final profile in profiles) {
      if (profile.isActive &&
          profile.dailyCalorieTarget.isFinite &&
          profile.dailyCalorieTarget > 0) {
        _profileAllergies = profile.allergies;
        _dietaryPreferences = [
          ...profile.dietaryPreferences,
          ...activeFoodChoices.dietaryPreferences,
        ];
        final today = DateTime.now();
        final age =
            today.year -
            profile.dateOfBirth.year -
            ((today.month < profile.dateOfBirth.month ||
                    (today.month == profile.dateOfBirth.month &&
                        today.day < profile.dateOfBirth.day))
                ? 1
                : 0);
        final issue =
            profile.healthRestrictions.any((v) => v.trim().isNotEmpty) ||
                activeFoodChoices.requiresProfessionalReview ||
                age < 18
            ? 'review'
            : (activeFoodChoices.mealsPerDay != null &&
                  !const [3, 4].contains(activeFoodChoices.mealsPerDay))
            ? 'mealCount'
            : _dietaryPreferences.any(
                (v) => !FoodPreferenceFilter.supportsDiet(v),
              )
            ? 'unsupported'
            : null;
        emit(
          state.copyWith(
            constraintIssue: issue,
            clearConstraintIssue: issue == null,
          ),
        );
        return profile.dailyCalorieTarget;
      }
    }
    emit(state.copyWith(clearConstraintIssue: true));
    return null;
  }

  /// Generates and persists a fresh plan for the displayed week. Nothing is
  /// shown before the save succeeds.
  Future<bool> generate({List<String> allergies = const []}) async {
    if (inactive || state.saving || _generating) return false;
    _generating = true;
    final myGeneration = _generation;
    emit(state.copyWith(saving: true));
    try {
      final target = await _activeTarget();
      if (inactive || myGeneration != _generation) return false;
      if (state.constraintIssue != null) {
        emit(state.copyWith(saving: false));
        return false;
      }
      if (target == null) {
        emit(state.copyWith(missingTarget: true, saving: false));
        return false;
      }
      final recorded = state.includeRecordedMeals
          ? RecordedMealCandidates.build(
              ownerUid: userId,
              asOf: DateTime.now(),
              records: await nutrition.getMealEntries(userId),
              catalog: generator.eligible,
              allergies: [
                ..._profileAllergies,
                ...activeFoodChoices.allergens,
                ...allergies,
              ],
              exclusions: activeFoodChoices.excluded,
              dietaryPreferences: _dietaryPreferences,
            )
          : <MealPlanMealModel>[];
      if (inactive || myGeneration != _generation) return false;
      final plan = generator.generate(
        recordedMeals: recorded,
        mealsPerDay: activeFoodChoices.mealsPerDay ?? 4,
        weekStart: state.weekStart,
        dailyCalorieTarget: target,
        seed: _seedProvider(),
        allergies: {
          ..._profileAllergies,
          ...activeFoodChoices.allergens,
          ...allergies,
        }.toList(),
        preferredFoods: activeFoodChoices.preferred,
        excludedFoods: activeFoodChoices.excluded,
        dietaryPreferences: _dietaryPreferences,
      );
      assertActive();
      await repository.savePlan(userId, plan);
      assertActive();
      final saved = await repository.getPlan(userId, plan.planId);
      if (inactive || myGeneration != _generation) return false;
      if (saved == null || saved.planId != plan.planId) {
        throw StateError('Plan save not confirmed');
      }
      emit(
        state.copyWith(
          status: PlannerStatus.ready,
          plan: saved,
          saving: false,
          missingTarget: false,
          recordedCandidateCount: state.includeRecordedMeals
              ? recorded.length
              : null,
        ),
      );
      return true;
    } catch (_) {
      if (!inactive && myGeneration == _generation) {
        emit(state.copyWith(saving: false));
      }
      return false;
    } finally {
      _generating = false;
    }
  }

  void selectDay(int index) {
    if (index < 0 || index > 6) return;
    emit(state.copyWith(selectedDayIndex: index));
  }

  /// Replaces one slot meal with a newly generated one and persists.
  Future<void> replaceMeal(String mealId) async {
    assertActive();
    final plan = state.plan;
    if (plan == null || state.saving) return;
    final index = plan.meals.indexWhere((m) => m.mealId == mealId);
    if (index < 0) return;
    final dateKey =
        plan.meals[index].dateKey ??
        WeeklyPlanGenerator.dateKeyOfMealId(mealId);
    if (dateKey == null) return;
    final day = DateTime.parse('${dateKey}T00:00:00');
    final editGeneration = _generation;
    final refreshedTarget = await _activeTarget();
    if (inactive ||
        editGeneration != _generation ||
        !identical(state.plan, plan) ||
        state.saving ||
        state.constraintIssue != null ||
        refreshedTarget == null) {
      return;
    }
    final replacement = generator.generateMeal(
      day: day,
      mealType: plan.meals[index].mealType,
      previousFoodIds: plan.meals[index].foods,
      mealsPerDay: activeFoodChoices.mealsPerDay ?? 4,
      dailyCalorieTarget: plan.dailyCalorieTarget,
      seed: _seedProvider(),
      excludedFoodIds: {
        ...generator.excludedByAllergy(activeFoodChoices.excluded),
        ...generator.excludedByConstraints(
          allergies: [..._profileAllergies, ...activeFoodChoices.allergens],
          dietaryPreferences: _dietaryPreferences,
        ),
      },
      preferredFoods: activeFoodChoices.preferred,
    );
    if (replacement == null) {
      emit(state.copyWith(noAlternative: true));
      return;
    }
    emit(state.copyWith(noAlternative: false));
    final meals = [...plan.meals];
    meals[index] = replacement;
    await _persist(plan, meals);
  }

  Future<void> removeMeal(String mealId) async {
    assertActive();
    final plan = state.plan;
    if (plan == null || state.saving) return;
    final meals = plan.meals.where((m) => m.mealId != mealId).toList();
    if (meals.length == plan.meals.length) return;
    await _persist(plan, meals);
  }

  /// Adds a generated meal to an empty slot of the selected day.
  Future<void> addMeal(String mealType) async {
    assertActive();
    final plan = state.plan;
    if (plan == null ||
        state.saving ||
        (activeFoodChoices.mealsPerDay == 3 && mealType == 'snack')) {
      return;
    }
    final day = SufraDateUtils.shiftDays(
      state.weekStart,
      state.selectedDayIndex,
    );
    final id = WeeklyPlanGenerator.mealIdFor(day, mealType);
    if (plan.meals.any((m) => m.mealId == id)) return;
    final editGeneration = _generation;
    final refreshedTarget = await _activeTarget();
    if (inactive ||
        editGeneration != _generation ||
        !identical(state.plan, plan) ||
        state.saving ||
        state.constraintIssue != null ||
        refreshedTarget == null) {
      return;
    }
    final meal = generator.generateMeal(
      day: day,
      mealType: mealType,
      mealsPerDay: activeFoodChoices.mealsPerDay ?? 4,
      dailyCalorieTarget: plan.dailyCalorieTarget,
      seed: _seedProvider(),
      excludedFoodIds: {
        ...generator.excludedByAllergy(activeFoodChoices.excluded),
        ...generator.excludedByConstraints(
          allergies: [..._profileAllergies, ...activeFoodChoices.allergens],
          dietaryPreferences: _dietaryPreferences,
        ),
      },
      preferredFoods: activeFoodChoices.preferred,
    );
    if (meal == null) return;
    await _persist(plan, [...plan.meals, meal]);
  }

  Future<void> _persist(
    MealPlanModel plan,
    List<MealPlanMealModel> meals,
  ) async {
    assertActive();
    final myGeneration = _generation;
    emit(state.copyWith(saving: true));
    try {
      final updated = MealPlanModel(
        planId: plan.planId,
        title: plan.title,
        startDate: plan.startDate,
        endDate: plan.endDate,
        status: plan.status,
        dailyCalorieTarget: plan.dailyCalorieTarget,
        meals: meals,
        generatedBy: plan.generatedBy,
        createdAt: plan.createdAt,
      );
      await repository.savePlan(userId, updated);
      if (inactive || myGeneration != _generation) return;
      assertActive();
      final saved = await repository.getPlan(userId, updated.planId);
      if (inactive || myGeneration != _generation) return;
      if (saved == null || saved.planId != updated.planId) {
        throw StateError('Plan edit save not confirmed');
      }
      emit(state.copyWith(plan: saved, saving: false));
    } catch (_) {
      if (inactive || myGeneration != _generation) return;
      emit(state.copyWith(saving: false));
    }
  }
}
