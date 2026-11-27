import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/meal_plan_model.dart';
import 'package:sufradepi/data/models/shopping_list_model.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/features/shopping/domain/shopping_list_logic.dart';

LocalFoodRecord food(String id, String category, String nameAr) =>
    LocalFoodRecord(
      id: id,
      nameAr: nameAr,
      nameEn: id,
      aliases: const [],
      category: category,
      foodState: 'raw',
      referenceAmountGrams: 100,
      nutrientsPer100g: const LocalFoodNutrients(energyKcal: 100),
      dataQuality: 'verified_source',
      source: const LocalFoodSource(
        provider: 'fixture',
        dataset: 'fixture',
        fdcId: 1,
        sourceVersion: '1',
        url: 'fixture',
      ),
    );

void main() {
  final plan = MealPlanModel(
    planId: 'week_2026-11-21',
    title: 'week_2026-11-21',
    startDate: DateTime(2026, 11, 21),
    endDate: DateTime(2026, 11, 27),
    status: 'active',
    dailyCalorieTarget: 2000,
    meals: [
      MealPlanMealModel(
        mealId: '2026-11-21:breakfast',
        title: 'فطار',
        mealType: 'breakfast',
        calories: 200,
        foods: const ['egg1', 'milk1'],
        dateKey: '2026-11-21',
        foodPortions: const [
          MealPlanFoodPortion(foodId: 'egg1', grams: 120),
          MealPlanFoodPortion(foodId: 'milk1', grams: 200),
        ],
      ),
      // Legacy shape: no typed portions, so its quantities are unknown.
      MealPlanMealModel(
        mealId: '2026-11-22:breakfast',
        title: 'فطار',
        mealType: 'breakfast',
        calories: 200,
        foods: const ['egg1', 'milk1'],
      ),
    ],
    generatedBy: 'rule_engine',
  );
  final byId = {
    'egg1': food('egg1', 'eggs', 'بيض'),
    'milk1': food('milk1', 'dairy', 'حليب'),
  };

  test('aggregates typed portions and skips legacy unmeasured meals', () {
    final aggregation = aggregatePlanItems(plan, byId);
    final egg = aggregation.items.firstWhere((i) => i.linkedFoodId == 'egg1');
    expect(egg.quantity, 120.0);
    expect(egg.unit, 'g');
    expect(egg.name, 'بيض');
    // Day one's measured milk is included; day two has no typed portions,
    // so both of its entries are skipped, never guessed.
    final milk = aggregation.items.firstWhere((i) => i.linkedFoodId == 'milk1');
    expect(milk.quantity, 200.0);
    expect(aggregation.skipped, 2);
  });

  test('unknown catalog ids are skipped rather than invented', () {
    final orphan = MealPlanModel(
      planId: 'p',
      title: 'p',
      startDate: DateTime(2026, 11, 21),
      endDate: DateTime(2026, 11, 27),
      status: 'active',
      dailyCalorieTarget: 2000,
      meals: [
        MealPlanMealModel(
          mealId: '2026-11-21:lunch',
          title: 'غداء',
          mealType: 'lunch',
          calories: 100,
          foods: const ['ghost'],
          foodPortions: const [
            MealPlanFoodPortion(foodId: 'ghost', grams: 100),
          ],
        ),
      ],
      generatedBy: 'rule_engine',
    );
    final aggregation = aggregatePlanItems(orphan, byId);
    expect(aggregation.items, isEmpty);
    expect(aggregation.skipped, 1);
  });

  test('progress and grouping follow the stored items', () {
    final aggregation = aggregatePlanItems(plan, byId);
    final items = [
      for (final item in aggregation.items)
        ShoppingListItemModel(
          itemId: item.itemId,
          name: item.name,
          quantity: item.quantity,
          unit: item.unit,
          category: item.category,
          isPurchased: item.itemId == 'food_egg1',
          linkedFoodId: item.linkedFoodId,
        ),
    ];
    expect(shoppingProgress(items), (1, 2));
    final grouped = groupShoppingItems(items);
    expect(grouped[ShoppingGroup.protein]!.single.itemId, 'food_egg1');
    expect(grouped[ShoppingGroup.dairy]!.single.itemId, 'food_milk1');
    expect(shoppingProgress(const []), (0, 0));
  });

  test('catalog categories map to the design groups, unknown to other', () {
    expect(shoppingGroupFor('eggs'), ShoppingGroup.protein);
    expect(shoppingGroupFor('vegetables'), ShoppingGroup.produce);
    expect(shoppingGroupFor('legumes'), ShoppingGroup.grains);
    expect(shoppingGroupFor('nonsense'), ShoppingGroup.other);
  });
}
