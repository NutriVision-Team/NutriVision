import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/repositories/food_repository.dart';

class AchievementRule {
  const AchievementRule({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.condition,
    required this.target,
    required this.parameters,
  });
  factory AchievementRule.fromJson(Map<String, dynamic> j) => AchievementRule(
    id: j['id'] as String,
    titleAr: j['title']['ar'] as String,
    titleEn: j['title']['en'] as String,
    descriptionAr: j['description']['ar'] as String,
    descriptionEn: j['description']['en'] as String,
    condition: j['conditionType'] as String,
    target: j['target'] as int,
    parameters: (j['ruleParameters'] as Map).cast<String, dynamic>(),
  );
  final String id, titleAr, titleEn, descriptionAr, descriptionEn, condition;
  final int target;
  final Map<String, dynamic> parameters;
}

class AchievementActivity {
  const AchievementActivity({
    required this.userId,
    required this.loggedDays,
    required this.mealCount,
    required this.distinctFoods,
    required this.mealTypesByDay,
    required this.categoriesByDay,
    this.categoryDataComplete = true,
  });
  final String userId;
  final Set<String> loggedDays;
  final int mealCount;
  final Set<String> distinctFoods;
  final Map<String, Set<String>> mealTypesByDay;
  final Map<String, Map<String, Set<String>>> categoriesByDay;
  final bool categoryDataComplete;

  static DateTime? day(String key) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) return null;
    final d = DateTime.tryParse('${key}T00:00:00Z');
    return d != null && keyOf(d) == key ? d : null;
  }

  static String keyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int currentStreak(String todayKey) {
    var cursor = day(todayKey);
    if (cursor == null) return 0;
    if (!loggedDays.contains(keyOf(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (loggedDays.contains(keyOf(cursor!))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  int get longestStreak {
    final dates = loggedDays.map(day).whereType<DateTime>().toList()..sort();
    var best = 0, run = 0;
    DateTime? previous;
    for (final d in dates) {
      run = previous != null && d.difference(previous).inDays == 1
          ? run + 1
          : 1;
      if (run > best) best = run;
      previous = d;
    }
    return best;
  }

  /// Null means unverified, never earned. No water-goal target exists upstream.
  int? progress(AchievementRule rule) {
    switch (rule.condition) {
      case 'meal_log_count':
        return mealCount;
      case 'daily_log_streak':
        return longestStreak;
      case 'distinct_foods_logged':
        return distinctFoods.length;
      case 'distinct_meal_types_in_day':
        final requiredTypes = Set<String>.from(
          rule.parameters['mealTypes'] as List? ?? [],
        );
        var best = 0;
        for (final types in mealTypesByDay.values) {
          final count = types.intersection(requiredTypes).length;
          if (count > best) best = count;
        }
        return best;
      case 'category_items_in_day':
        if (!categoryDataComplete) return null;
        final category = rule.parameters['category'] as String?;
        var best = 0;
        for (final values in categoriesByDay.values) {
          final count = values[category]?.length ?? 0;
          if (count > best) best = count;
        }
        return best;
      default:
        return null;
    }
  }
}

abstract interface class AchievementActivityLoader {
  Future<AchievementActivity> load(String userId);
}

/// Read-only adapter. The screen guards account changes and stale futures.
class RepositoryAchievementActivityLoader implements AchievementActivityLoader {
  RepositoryAchievementActivityLoader({
    required this.nutrition,
    required this.foods,
  });
  final NutritionRepository nutrition;
  final FoodRepository foods;
  @override
  Future<AchievementActivity> load(String userId) async {
    if (userId.trim().isEmpty) throw ArgumentError.value(userId, 'userId');
    final entries = (await nutrition.getMealEntries(userId))
        .where(
          (m) =>
              m.userId == userId && AchievementActivity.day(m.dateKey) != null,
        )
        .toList();
    final days = <String>{};
    final distinct = <String>{};
    final types = <String, Set<String>>{};
    final categories = <String, Map<String, Set<String>>>{};
    final foodCategories = <String, String?>{};
    var complete = true;
    for (final meal in entries) {
      days.add(meal.dateKey);
      types.putIfAbsent(meal.dateKey, () => {}).add(meal.mealType);
      for (final item in meal.items) {
        if (item.foodId.isEmpty) {
          complete = false;
          continue;
        }
        distinct.add(item.foodId);
        if (!foodCategories.containsKey(item.foodId)) {
          foodCategories[item.foodId] = (await foods.getFoodById(
            item.foodId,
          ))?.category;
        }
        final category = foodCategories[item.foodId];
        if (category == null || category.isEmpty) {
          complete = false;
          continue;
        }
        categories
            .putIfAbsent(meal.dateKey, () => {})
            .putIfAbsent(category, () => {})
            .add(item.foodId);
      }
    }
    return AchievementActivity(
      userId: userId,
      loggedDays: Set.unmodifiable(days),
      mealCount: entries.length,
      distinctFoods: Set.unmodifiable(distinct),
      mealTypesByDay: types,
      categoriesByDay: categories,
      categoryDataComplete: complete,
    );
  }
}

class AchievementCatalog {
  AchievementCatalog({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  Future<List<AchievementRule>> load() async {
    final j =
        jsonDecode(await _bundle.loadString('assets/data/achievements.json'))
            as Map<String, dynamic>;
    if (j['schemaVersion'] != '1.0.0') {
      throw const FormatException('Unknown achievement schema');
    }
    return (j['achievements'] as List)
        .map(
          (e) => AchievementRule.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList(growable: false);
  }
}
