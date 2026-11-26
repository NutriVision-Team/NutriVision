import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/features/meal_log/presentation/cubit/recent_meals_cubit.dart';

import '../goldens/milestone1_screens_test.dart' show FakeNutritionRepository;

MealEntryModel meal({String uid = 'u1', String id = 'm1', DateTime? at}) =>
    MealEntryModel(
      mealId: id,
      userId: uid,
      dateKey: '2026-11-20',
      consumedAt: at ?? DateTime(2026, 11, 20),
      mealType: 'lunch',
      inputMethod: 'manual',
      title: 'Meal',
      items: const [],
      totalCalories: 400,
      totalProtein: 20,
      totalCarbs: 50,
      totalFat: 10,
      totalFiber: 5,
      totalSugar: 3,
      totalSodium: 80,
      analysisStatus: 'confirmed',
      nutritionSource: 'catalog',
    );

class RecordingNutrition extends FakeNutritionRepository {
  final writes = <MealEntryModel>[];
  Completer<void>? gate;
  bool failNext = false;
  @override
  Future<void> saveMealEntry(String uid, MealEntryModel meal) async {
    expect(meal.userId, uid);
    writes.add(meal);
    await gate?.future;
    if (failNext) {
      failNext = false;
      throw StateError('offline');
    }
  }
}

void main() {
  late RecordingNutrition repo;
  late RecentMealsCubit cubit;
  String? current;
  setUp(() {
    repo = RecordingNutrition();
    current = 'u1';
    cubit = RecentMealsCubit(
      repository: repo,
      uid: 'u1',
      currentUid: () => current,
      clock: () => DateTime(2026, 11, 22, 14),
    );
  });
  tearDown(() => cubit.close());

  test(
    'sorts newest and excludes entries belonging to another account',
    () async {
      repo.meals = [
        meal(),
        meal(uid: 'other', at: DateTime(2027)),
        meal(id: 'newest', at: DateTime(2026, 11, 21)),
      ];
      await cubit.load();
      expect(cubit.state.meal?.mealId, 'newest');
    },
  );

  test('empty results are ready, not a fabricated sample meal', () async {
    await cubit.load();
    expect(cubit.state.status, RecentMealsStatus.ready);
    expect(cubit.state.meal, isNull);
    await cubit.relog();
    expect(repo.writes, isEmpty);
  });

  test(
    'double submit while saving writes once, and preserves source nutrients',
    () async {
      repo.meals = [meal()];
      await cubit.load();
      repo.gate = Completer<void>();
      final pending = cubit.relog();
      await cubit.relog();
      expect(repo.writes, hasLength(1));
      repo.gate!.complete();
      await pending;
      expect(cubit.state.status, RecentMealsStatus.saved);
      expect(repo.writes.single.dateKey, '2026-11-22');
      expect(repo.writes.single.totalCalories, 400);
      expect(repo.writes.single.nutritionSource, 'catalog');
      expect(repo.writes.single.mealId, isNot('m1'));
    },
  );

  test(
    'ambiguous save failure retries same ID instead of duplicating a meal',
    () async {
      repo.meals = [meal()];
      await cubit.load();
      repo.failNext = true;
      await cubit.relog();
      expect(cubit.state.status, RecentMealsStatus.failure);
      await cubit.relog();
      expect(repo.writes, hasLength(2));
      expect(repo.writes[0].mealId, repo.writes[1].mealId);
      expect(cubit.state.status, RecentMealsStatus.saved);
    },
  );

  test('account change prevents a write using the previous account', () async {
    repo.meals = [meal()];
    await cubit.load();
    current = 'other';
    await cubit.relog();
    expect(repo.writes, isEmpty);
  });

  test('dispose during pending save causes no late emit', () async {
    repo.meals = [meal()];
    await cubit.load();
    repo.gate = Completer<void>();
    final pending = cubit.relog();
    await cubit.close();
    repo.gate!.complete();
    await expectLater(pending, completes);
  });
}
