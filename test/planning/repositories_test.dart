import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/conversation_model.dart';
import 'package:sufradepi/data/models/meal_plan_model.dart';
import 'package:sufradepi/data/models/shopping_list_model.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'package:sufradepi/features/planner/data/planner_repository.dart';
import 'package:sufradepi/features/shopping/data/shopping_repository.dart';

import 'support/planning_memory_firestore.dart';

void main() {
  late PlanningMemoryFirestore store;

  setUp(() => store = PlanningMemoryFirestore());

  group('FirestorePlannerRepository', () {
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
          calories: 300,
          foods: const ['egg1'],
          dateKey: '2026-11-21',
          foodPortions: const [MealPlanFoodPortion(foodId: 'egg1', grams: 120)],
        ),
      ],
      generatedBy: 'rule_engine',
    );

    test('saves under the user path and round-trips', () async {
      final repo = FirestorePlannerRepository(store);
      await repo.savePlan('u1', plan);
      expect(
        store.documents.keys,
        contains('users/u1/meal_plans/week_2026-11-21'),
      );
      final loaded = await repo.getPlan('u1', plan.planId);
      expect(loaded, isNotNull);
      expect(loaded!.meals.single.foods, ['egg1']);
      expect(loaded.meals.single.foodPortions!.single.grams, 120);
      expect(loaded.meals.single.dateKey, '2026-11-21');
      expect(loaded.dailyCalorieTarget, 2000);
    });

    test('keeps a createdAt stamp and isolates users by path', () async {
      final repo = FirestorePlannerRepository(store);
      await repo.savePlan('u1', plan);
      final doc = await store
          .collection('users/u1/meal_plans')
          .doc(plan.planId)
          .get();
      expect(doc.data()!['createdAt'], isNotNull);
      expect(await repo.getPlan('u2', plan.planId), isNull);
    });
  });

  group('FirestoreShoppingRepository', () {
    const list = ShoppingListModel(
      listId: 'current',
      title: 'قائمة التسوق',
      planId: 'week_2026-11-21',
      status: 'active',
    );

    ShoppingListItemModel item(
      String id, {
      bool purchased = false,
      String? linkedFoodId,
    }) => ShoppingListItemModel(
      itemId: id,
      name: id,
      quantity: 100,
      unit: 'g',
      category: 'protein',
      isPurchased: purchased,
      linkedFoodId: linkedFoodId,
    );

    test('saves the list and its items, and toggles persist', () async {
      final repo = FirestoreShoppingRepository(store);
      await repo.saveList('u1', list);
      await repo.upsertItem('u1', 'current', item('a', linkedFoodId: 'egg1'));
      await repo.upsertItem('u1', 'current', item('b'));
      var items = await repo.getItems('u1', 'current');
      expect(items.length, 2);
      await repo.setPurchased('u1', 'current', 'a', true);
      items = await repo.getItems('u1', 'current');
      expect(items.firstWhere((i) => i.itemId == 'a').isPurchased, isTrue);
      final loaded = await repo.getList('u1', 'current');
      expect(loaded, isNotNull);
    });

    test(
      'replaceGeneratedItems keeps manual items and purchased state',
      () async {
        final repo = FirestoreShoppingRepository(store);
        await repo.saveList('u1', list);
        await repo.upsertItem(
          'u1',
          'current',
          item('food_egg1', purchased: true, linkedFoodId: 'egg1'),
        );
        await repo.upsertItem(
          'u1',
          'current',
          item('food_rice1', linkedFoodId: 'rice1'),
        );
        await repo.upsertItem('u1', 'current', item('manual_1'));
        await repo.replaceGeneratedItems('u1', 'current', [
          item('food_egg1', linkedFoodId: 'egg1'),
          item('food_milk1', linkedFoodId: 'milk1'),
        ]);
        final items = await repo.getItems('u1', 'current');
        final byId = {for (final i in items) i.itemId: i};
        expect(byId.keys, {'food_egg1', 'food_milk1', 'manual_1'});
        expect(byId['food_egg1']!.isPurchased, isTrue);
      },
    );
  });

  group('FirestoreCoachStore', () {
    test('stores messages ordered by createdAt under the user path', () async {
      final repo = FirestoreCoachStore(store);
      final base = DateTime(2026, 11, 22, 12);
      await repo.appendMessage(
        'u1',
        ChatMessageModel(
          messageId: 'm1',
          role: 'user',
          content: 'أول',
          messageType: 'text',
          createdAt: base,
        ),
      );
      await repo.appendMessage(
        'u1',
        ChatMessageModel(
          messageId: 'm2',
          role: 'assistant',
          content: 'ثاني',
          messageType: 'text',
          createdAt: base.add(const Duration(minutes: 1)),
        ),
      );
      final messages = await repo.loadMessages('u1');
      expect(messages.map((m) => m.messageId), ['m1', 'm2']);
      expect(await repo.loadMessages('u2'), isEmpty);
    });
  });
}
