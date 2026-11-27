import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/features/planner/domain/planner_food_choices.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/meal_plan_model.dart';
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'package:sufradepi/features/planner/domain/weekly_plan_generator.dart';
import 'package:sufradepi/features/planner/data/planner_repository.dart';
import 'package:sufradepi/features/planner/presentation/cubit/planner_cubit.dart';
import '../features/progress/progress_test.dart' show FakeNutritionRepository;
import 'plan_generator_test.dart' show catalog;

class PendingProfile extends FakeNutritionRepository {
  final pending = Completer<List<NutritionProfileModel>>();
  @override
  Future<List<NutritionProfileModel>> getNutritionProfiles(String uid) =>
      pending.future;
}

class CountingNutrition extends FakeNutritionRepository {
  int mealReads = 0;
  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async {
    mealReads++;
    return super.getMealEntries(uid, dateKey: dateKey);
  }
}

class PlanMemory implements PlannerRepository {
  MealPlanModel? value;
  int writes = 0;
  bool drop = false;
  @override
  Future<MealPlanModel?> getPlan(String uid, String id) async => value;
  @override
  Future<void> savePlan(String uid, MealPlanModel plan) async {
    writes++;
    if (!drop) value = plan;
  }
}

NutritionProfileModel profile({
  List<String> healthRestrictions = const [],
  List<String> dietaryPreferences = const [],
}) => NutritionProfileModel(
  profileId: 'p',
  healthRestrictions: healthRestrictions,
  dietaryPreferences: dietaryPreferences,
  gender: 'male',
  dateOfBirth: DateTime(2000),
  heightCm: 180,
  currentWeightKg: 90,
  targetWeightKg: 80,
  activityLevel: 'sedentary',
  nutritionGoal: 'lose',
  dailyCalorieTarget: 2000,
  proteinTarget: 120,
  carbsTarget: 220,
  fatTarget: 65,
  allergies: const ['بيض'],
);
void main() {
  test('concurrent generation submits only once', () async {
    final nutrition = PendingProfile(), store = PlanMemory();
    final c = PlannerCubit(
      userId: 'u1',
      currentUid: () => 'u1',
      repository: store,
      nutrition: nutrition,
      generator: WeeklyPlanGenerator(catalog: catalog()),
      today: DateTime(2026, 11, 22),
    );
    final a = c.generate();
    expect(await c.generate(), false);
    nutrition.pending.complete([profile()]);
    expect(await a, true);
    expect(store.writes, 1);
    expect(c.state.plan!.meals.expand((m) => m.foods), isNot(contains('egg1')));
    await c.close();
  });
  test('account switch during target lookup cannot save', () async {
    var uid = 'u1';
    final nutrition = PendingProfile(), store = PlanMemory();
    final c = PlannerCubit(
      userId: 'u1',
      currentUid: () => uid,
      repository: store,
      nutrition: nutrition,
      generator: WeeklyPlanGenerator(catalog: catalog()),
      today: DateTime(2026, 11, 22),
    );
    final pending = c.generate();
    uid = 'u2';
    nutrition.pending.complete([profile()]);
    expect(await pending, false);
    expect(store.writes, 0);
    await c.close();
  });
  test('close during target lookup cannot save or emit', () async {
    final nutrition = PendingProfile(), store = PlanMemory();
    final c = PlannerCubit(
      userId: 'u1',
      repository: store,
      nutrition: nutrition,
      generator: WeeklyPlanGenerator(catalog: catalog()),
      today: DateTime(2026, 11, 22),
    );
    final pending = c.generate();
    await c.close();
    nutrition.pending.complete([profile()]);
    expect(await pending, false);
    expect(store.writes, 0);
  });
  test('absent readback is not reported as saved', () async {
    final nutrition = FakeNutritionRepository()..activeProfile = profile();
    final store = PlanMemory()..drop = true;
    final c = PlannerCubit(
      userId: 'u1',
      repository: store,
      nutrition: nutrition,
      generator: WeeklyPlanGenerator(catalog: catalog()),
      today: DateTime(2026, 11, 22),
    );
    expect(await c.generate(), false);
    expect(c.state.plan, isNull);
    expect(c.state.saving, false);
    await c.close();
  });
  test('reloading absent plan clears the previous visible plan', () async {
    final nutrition = FakeNutritionRepository()..activeProfile = profile();
    final store = PlanMemory();
    final c = PlannerCubit(
      userId: 'u1',
      repository: store,
      nutrition: nutrition,
      generator: WeeklyPlanGenerator(catalog: catalog()),
      today: DateTime(2026, 11, 22),
    );
    expect(await c.generate(), true);
    store.value = null;
    await c.load();
    expect(c.state.plan, isNull);
    await c.close();
  });
  test('an edit uses readback and does not claim a dropped removal', () async {
    final nutrition = FakeNutritionRepository()..activeProfile = profile();
    final store = PlanMemory();
    final c = PlannerCubit(
      userId: 'u1',
      repository: store,
      nutrition: nutrition,
      generator: WeeklyPlanGenerator(catalog: catalog()),
      today: DateTime(2026, 11, 22),
    );
    expect(await c.generate(), true);
    final id = c.state.plan!.meals.first.mealId;
    store.drop = true;
    await c.removeMeal(id);
    expect(c.state.plan!.meals.any((m) => m.mealId == id), true);
    store.drop = false;
    await c.removeMeal(id);
    expect(c.state.plan!.meals.any((m) => m.mealId == id), false);
    await c.close();
  });
  test('session choices are owner scoped and preserved for edits', () async {
    for (final owner in ['u1', 'another']) {
      final nutrition = FakeNutritionRepository()..activeProfile = profile();
      final c = PlannerCubit(
        userId: 'u1',
        repository: PlanMemory(),
        nutrition: nutrition,
        generator: WeeklyPlanGenerator(catalog: catalog()),
        today: DateTime(2026, 11, 22),
        foodChoices: PlannerFoodChoices(
          ownerUid: owner,
          excluded: ['milk1', 'lentil1', 'egg1'],
        ),
      );
      expect(await c.generate(), true);
      expect(
        c.state.plan!.meals.where((m) => m.mealType == 'breakfast').isEmpty,
        owner == 'u1',
      );
      await c.addMeal('breakfast');
      expect(
        c.state.plan!.meals.where((m) => m.mealType == 'breakfast').isEmpty,
        owner == 'u1',
      );
      await c.close();
    }
  });
  test(
    'unknown session dietary restriction pauses generation without writing',
    () async {
      final nutrition = FakeNutritionRepository()..activeProfile = profile();
      final store = PlanMemory();
      final c = PlannerCubit(
        userId: 'u1',
        repository: store,
        nutrition: nutrition,
        generator: WeeklyPlanGenerator(catalog: catalog()),
        today: DateTime(2026, 11, 22),
        foodChoices: const PlannerFoodChoices(
          ownerUid: 'u1',
          dietaryPreferences: ['medical keto'],
        ),
      );
      expect(await c.generate(), false);
      expect(c.state.constraintIssue, 'unsupported');
      expect(store.writes, 0);
      await c.close();
    },
  );
  test('medical session context pauses generation without writing', () async {
    final nutrition = FakeNutritionRepository()..activeProfile = profile();
    final store = PlanMemory();
    final c = PlannerCubit(
      userId: 'u1',
      repository: store,
      nutrition: nutrition,
      generator: WeeklyPlanGenerator(catalog: catalog()),
      today: DateTime(2026, 11, 22),
      foodChoices: const PlannerFoodChoices(
        ownerUid: 'u1',
        requiresProfessionalReview: true,
      ),
    );
    expect(await c.generate(), false);
    expect(c.state.constraintIssue, 'review');
    expect(store.writes, 0);
    await c.close();
  });
  test(
    'sole-option swap explicitly reports no alternative and does not write',
    () async {
      final nutrition = FakeNutritionRepository()..activeProfile = profile();
      final store = PlanMemory();
      final c = PlannerCubit(
        userId: 'u1',
        repository: store,
        nutrition: nutrition,
        generator: WeeklyPlanGenerator(
          catalog: catalog()
              .where((f) => !['egg1', 'lentil1'].contains(f.id))
              .toList(),
        ),
        today: DateTime(2026, 11, 22),
      );
      expect(await c.generate(), true);
      final first = c.state.plan!.meals.firstWhere(
        (m) => m.mealType == 'breakfast',
      );
      await c.replaceMeal(first.mealId);
      expect(c.state.noAlternative, true);
      expect(store.writes, 1);
      await c.close();
    },
  );
  test(
    'existing profile restrictions pause generation and later replacement',
    () async {
      final nutrition = FakeNutritionRepository()..activeProfile = profile();
      final store = PlanMemory();
      final c = PlannerCubit(
        userId: 'u1',
        repository: store,
        nutrition: nutrition,
        generator: WeeklyPlanGenerator(catalog: catalog()),
        today: DateTime(2026, 11, 22),
      );
      expect(await c.generate(), true);
      final id = c.state.plan!.meals.first.mealId;
      nutrition.activeProfile = profile(
        healthRestrictions: ['renal condition'],
      );
      await c.replaceMeal(id);
      expect(c.state.constraintIssue, 'review');
      expect(store.writes, 1);
      expect(await c.generate(), false);
      expect(store.writes, 1);
      nutrition.activeProfile = profile(
        dietaryPreferences: ['unrecognized diet'],
      );
      expect(await c.generate(), false);
      expect(c.state.constraintIssue, 'unsupported');
      nutrition.activeProfile = profile();
      expect(await c.generate(), true);
      expect(c.state.constraintIssue, isNull);
      await c.close();
    },
  );
  test('reuse reads meal history only after explicit local choice', () async {
    final nutrition = CountingNutrition()..activeProfile = profile();
    final c = PlannerCubit(
      userId: 'u1',
      repository: PlanMemory(),
      nutrition: nutrition,
      generator: WeeklyPlanGenerator(catalog: catalog()),
      today: DateTime(2026, 11, 22),
    );
    expect(await c.generate(), true);
    expect(nutrition.mealReads, 0);
    c.setIncludeRecordedMeals(true);
    expect(await c.generate(), true);
    expect(nutrition.mealReads, 1);
    expect(c.state.recordedCandidateCount, 0);
    await c.close();
  });
  test(
    'unsupported meal count pauses rather than falling back silently',
    () async {
      final nutrition = FakeNutritionRepository()..activeProfile = profile();
      final store = PlanMemory();
      final c = PlannerCubit(
        userId: 'u1',
        repository: store,
        nutrition: nutrition,
        generator: WeeklyPlanGenerator(catalog: catalog()),
        today: DateTime(2026, 11, 22),
        foodChoices: const PlannerFoodChoices(ownerUid: 'u1', mealsPerDay: 5),
      );
      expect(await c.generate(), false);
      expect(c.state.constraintIssue, 'mealCount');
      expect(store.writes, 0);
      await c.close();
    },
  );
  test('typed portions reject missing, nonfinite and nonpositive mass', () {
    for (final grams in [null, 0, -1, double.nan, double.infinity]) {
      expect(
        () => MealPlanFoodPortion.fromMap({'foodId': 'rice', 'grams': grams}),
        throwsFormatException,
      );
    }
    expect(
      MealPlanMealModel.fromMap({
        'foods': ['rice'],
      }).foodPortions,
      isNull,
    );
  });
}
