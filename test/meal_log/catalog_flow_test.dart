import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/data/repositories/food_repository.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/meal_log/presentation/cubit/food_search_cubit.dart';
import 'package:sufradepi/features/meal_log/presentation/cubit/meal_save_cubit.dart';

import 'recent_meals_cubit_test.dart' show RecordingNutrition;

FoodCatalogModel catalog({
  Map<String, dynamic>? nutrition,
  String? source = 'test-only',
}) => FoodCatalogModel(
  foodId: 'f1',
  name: 'Fixture',
  source: source,
  nutritionPer100g:
      nutrition ??
      {
        'calories': 200,
        'protein': 10,
        'carbohydrates': 20,
        'fat': 8,
        'fiber': 4,
        'sugar': 2,
        'sodium': 50,
      },
);

class DelayedFoodRepository implements FoodRepository {
  final queries = <String>[];
  final pending = <String, Completer<List<FoodCatalogModel>>>{};
  @override
  Future<List<FoodCatalogModel>> searchFood(String query) {
    queries.add(query);
    return (pending[query] = Completer<List<FoodCatalogModel>>()).future;
  }

  @override
  Future<FoodCatalogModel?> getFoodById(String id) async => null;
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  test('portion scales declared per-100g values with no AI arithmetic', () {
    final p = FoodPortion(catalog(), 250);
    expect(p.amount('calories'), 500);
    expect(p.amount('sodium'), 125);
    final m = p.toMeal(
      uid: 'u1',
      id: 'm1',
      at: DateTime(2026, 11, 22),
      mealType: 'lunch',
    );
    expect(m.items.single.weightInGrams, 250);
    expect(m.totalCalories, 500);
    expect(m.items.single.confidence, isNull);
  });

  test(
    'known calories can be logged without turning unknown nutrients into zeros',
    () {
      final p = FoodPortion(catalog(nutrition: {'calories': 200}), 100);
      expect(p.amount('fiber'), isNull);
      expect(p.canSave, isTrue);
      final saved = p.toMeal(
        uid: 'u1',
        id: 'm1',
        at: DateTime(2026),
        mealType: 'lunch',
      );
      expect(saved.totalCalories, 200);
      expect(saved.totalFiber, isNull);
      expect(saved.items.single.protein, isNull);
      expect(saved.toMap()['totalSugar'], isNull);
    },
  );

  test('invalid nutrition and unknown provenance cannot be saved', () {
    expect(FoodPortion(catalog(source: null), 100).canSave, isFalse);
    for (final value in [-1, double.nan, double.infinity, '200']) {
      expect(
        FoodPortion(
          catalog(nutrition: {'calories': value}),
          100,
        ).amount('calories'),
        isNull,
      );
    }
    for (final grams in [0.0, -1.0, double.nan, double.infinity, 10001.0]) {
      expect(() => FoodPortion(catalog(), grams), throwsArgumentError);
    }
  });

  test('stale search response cannot replace newer query results', () async {
    final repo = DelayedFoodRepository();
    final cubit = FoodSearchCubit(repo, debounce: Duration.zero);
    cubit.search('old');
    await tick();
    cubit.search('new');
    await tick();
    repo.pending['new']!.complete([catalog()]);
    await tick();
    repo.pending['old']!.complete([]);
    await tick();
    expect(cubit.state.query, 'new');
    expect(cubit.state.foods, hasLength(1));
    await cubit.close();
  });

  test(
    'blank cancels search; failure is distinct from a genuine empty result',
    () async {
      final repo = DelayedFoodRepository();
      final cubit = FoodSearchCubit(repo, debounce: Duration.zero);
      cubit.search('   ');
      await tick();
      expect(repo.queries, isEmpty);
      cubit.search('q');
      await tick();
      repo.pending['q']!.completeError(StateError('offline'));
      await tick();
      expect(cubit.state.status, FoodSearchStatus.failure);
      cubit.retry();
      await tick();
      repo.pending['q']!.complete([]);
      await tick();
      expect(cubit.state.status, FoodSearchStatus.ready);
      expect(cubit.state.foods, isEmpty);
      await cubit.close();
    },
  );

  test('clearing input invalidates an in-flight search', () async {
    final repo = DelayedFoodRepository();
    final cubit = FoodSearchCubit(repo, debounce: Duration.zero);
    cubit.search('q');
    await tick();
    cubit.search('');
    repo.pending['q']!.complete([catalog()]);
    await tick();
    expect(cubit.state.status, FoodSearchStatus.idle);
    expect(cubit.state.foods, isEmpty);
    await cubit.close();
  });

  test(
    'review save is idempotent across retry and ignores double-tap',
    () async {
      final repo = RecordingNutrition()
        ..gate = Completer<void>()
        ..failNext = true;
      final cubit = MealSaveCubit(
        portion: FoodPortion(catalog(), 100),
        repository: repo,
        uid: 'u1',
        currentUid: () => 'u1',
        mealType: 'lunch',
        clock: () => DateTime(2026, 11, 22),
      );
      final saving = cubit.save();
      await cubit.save();
      expect(repo.writes, hasLength(1));
      repo.gate!.complete();
      await saving;
      expect(cubit.state, MealSaveStatus.failure);
      await cubit.save();
      expect(repo.writes[0].mealId, repo.writes[1].mealId);
      await cubit.save();
      expect(repo.writes, hasLength(2));
      await cubit.close();
    },
  );

  test(
    'review blocks writes for expired account and incomplete nutrition',
    () async {
      final repo = RecordingNutrition();
      final expired = MealSaveCubit(
        portion: FoodPortion(catalog(), 100),
        repository: repo,
        uid: 'u1',
        currentUid: () => 'u2',
        mealType: 'lunch',
      );
      await expired.save();
      expect(expired.state, MealSaveStatus.expired);
      final incomplete = MealSaveCubit(
        portion: FoodPortion(catalog(nutrition: {}), 100),
        repository: repo,
        uid: 'u1',
        currentUid: () => 'u1',
        mealType: 'lunch',
      );
      await incomplete.save();
      expect(incomplete.state, MealSaveStatus.failure);
      expect(repo.writes, isEmpty);
      await expired.close();
      await incomplete.close();
    },
  );
}
