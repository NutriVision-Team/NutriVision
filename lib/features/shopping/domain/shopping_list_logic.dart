import '../../../data/models/meal_plan_model.dart';
import '../../../data/models/shopping_list_model.dart';
import '../../food_catalog/data/datasources/local_food_data_source.dart';

/// Coarse shopping groups shown as category headings, mapping the verified
/// catalog categories onto the design's groups.
enum ShoppingGroup { produce, protein, dairy, grains, other }

ShoppingGroup shoppingGroupFor(String catalogCategory) {
  switch (catalogCategory) {
    case 'vegetables':
    case 'fruits':
      return ShoppingGroup.produce;
    case 'poultry':
    case 'meat':
    case 'fish':
    case 'eggs':
      return ShoppingGroup.protein;
    case 'dairy':
      return ShoppingGroup.dairy;
    case 'grains':
    case 'legumes':
      return ShoppingGroup.grains;
    default:
      return ShoppingGroup.other;
  }
}

/// Aggregates measured typed food portions from a weekly plan.
/// Legacy meals without portions and unresolved catalog IDs are skipped,
/// never inferred from the canonical foods list or any legacy encoding.
class ShoppingAggregation {
  const ShoppingAggregation({required this.items, required this.skipped});

  final List<ShoppingListItemModel> items;

  /// Plan entries that could not be turned into measured items.
  final int skipped;
}

ShoppingAggregation aggregatePlanItems(
  MealPlanModel plan,
  Map<String, LocalFoodRecord> catalogById,
) {
  final gramsByFood = <String, double>{};
  var skipped = 0;
  for (final meal in plan.meals) {
    // Typed portions are the only measured quantities; a meal saved before
    // portions existed (or by any other writer) has unknown quantities and
    // is skipped whole, never inferred from legacy encodings.
    final portions = meal.foodPortions;
    if (portions == null) {
      skipped += meal.foods.length;
      continue;
    }
    for (final portion in portions) {
      if (portion.foodId.isEmpty ||
          !portion.grams.isFinite ||
          portion.grams <= 0) {
        skipped++;
        continue;
      }
      if (!catalogById.containsKey(portion.foodId)) {
        skipped++;
        continue;
      }
      gramsByFood.update(
        portion.foodId,
        (value) => value + portion.grams,
        ifAbsent: () => portion.grams,
      );
    }
  }
  final items = <ShoppingListItemModel>[];
  for (final entry in gramsByFood.entries) {
    final food = catalogById[entry.key]!;
    items.add(
      ShoppingListItemModel(
        itemId: 'food_${food.id}',
        name: food.nameAr.isNotEmpty ? food.nameAr : food.nameEn,
        quantity: entry.value,
        unit: 'g',
        category: shoppingGroupFor(food.category).name,
        isPurchased: false,
        linkedFoodId: food.id,
      ),
    );
  }
  items.sort((a, b) => a.itemId.compareTo(b.itemId));
  return ShoppingAggregation(items: items, skipped: skipped);
}

/// Progress over the current items: purchased count and total.
(int purchased, int total) shoppingProgress(List<ShoppingListItemModel> items) {
  var purchased = 0;
  for (final item in items) {
    if (item.isPurchased) purchased++;
  }
  return (purchased, items.length);
}

/// Groups items by their [ShoppingGroup] name, preserving group order.
Map<ShoppingGroup, List<ShoppingListItemModel>> groupShoppingItems(
  List<ShoppingListItemModel> items,
) {
  final grouped = <ShoppingGroup, List<ShoppingListItemModel>>{};
  for (final item in items) {
    final group =
        ShoppingGroup.values.asNameMap()[item.category] ?? ShoppingGroup.other;
    grouped.putIfAbsent(group, () => []).add(item);
  }
  return grouped;
}
