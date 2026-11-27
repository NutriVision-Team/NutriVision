import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/data/repositories/food_repository.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/features/achievements/domain/achievement_activity.dart';

class ActivityNutritionFixture implements NutritionRepository {
  ActivityNutritionFixture(this.entries);
  final List<MealEntryModel> entries;
  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async => entries;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ActivityFoodsFixture implements FoodRepository {
  final reads = <String>[];
  @override
  Future<FoodCatalogModel?> getFoodById(String foodId) async {
    reads.add(foodId);
    if (foodId == 'unknown') return null;
    return FoodCatalogModel(
      foodId: foodId,
      name: foodId,
      category: 'vegetables',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MealEntryModel meal(String id, String uid, String date, List<String> foods) =>
    MealEntryModel.fromMap(id, {
      'userId': uid,
      'dateKey': date,
      'consumedAt': Timestamp.fromDate(DateTime.utc(2026, 11, 22)),
      'mealType': 'lunch',
      'totalCalories': 100,
      'nutritionSource': 'explicit test fixture',
      'items': foods
          .map(
            (f) => {
              'foodId': f,
              'calories': 50,
              'dataSource': 'explicit test fixture',
            },
          )
          .toList(),
    });
void main() {
  test(
    'activity adapter filters wrong UID and invalid dates; resolves each food once',
    () async {
      final foods = ActivityFoodsFixture();
      final loader = RepositoryAchievementActivityLoader(
        foods: foods,
        nutrition: ActivityNutritionFixture([
          meal('1', 'owner', '2026-11-21', ['tomato', 'carrot']),
          meal('2', 'owner', '2026-11-22', ['tomato']),
          meal('3', 'other', '2026-11-22', ['private-food']),
          meal('4', 'owner', '2026-02-30', ['invalid-date-food']),
        ]),
      );
      final activity = await loader.load('owner');
      expect(activity.mealCount, 2);
      expect(activity.loggedDays, {'2026-11-21', '2026-11-22'});
      expect(activity.distinctFoods, {'tomato', 'carrot'});
      expect(foods.reads, ['tomato', 'carrot']);
      expect(activity.categoriesByDay['2026-11-21']?['vegetables'], {
        'tomato',
        'carrot',
      });
    },
  );
  test(
    'unknown categories stay unverified, not confirmed vegetable achievements',
    () async {
      final loader = RepositoryAchievementActivityLoader(
        foods: ActivityFoodsFixture(),
        nutrition: ActivityNutritionFixture([
          meal('1', 'owner', '2026-11-22', ['tomato', 'unknown']),
        ]),
      );
      final activity = await loader.load('owner');
      expect(activity.categoryDataComplete, isFalse);
      expect(activity.categoriesByDay['2026-11-22']?['vegetables'], {'tomato'});
    },
  );
  test('empty account IDs fail before reading activity', () async {
    final loader = RepositoryAchievementActivityLoader(
      foods: ActivityFoodsFixture(),
      nutrition: ActivityNutritionFixture([]),
    );
    await expectLater(loader.load(''), throwsArgumentError);
  });
}
