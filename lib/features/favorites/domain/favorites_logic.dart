import '../../../core/utils/nutrition_values.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/favorite_model.dart';
import '../../../data/models/meal_entry_model.dart';

/// Values of [FavoriteModel.targetType] this feature reads and writes.
/// 'recipe' records come from the recipe screens (CloudRecipeFavorites, ids
/// `recipe_<id>`). 'meal' records are written here (ids `meal_<mealId>`).
/// Other target types are left untouched and never shown or deleted.
const favoriteTypeMeal = 'meal';
const favoriteTypeRecipe = 'recipe';

String mealFavoriteId(String mealId) => 'meal_${Uri.encodeComponent(mealId)}';

enum FavoritesTab { meals, recipes, frequent }

enum FavoritesSort { recent, name, calories }

/// One favorite meal resolved against the user's own logged meals.
/// [meal] is null when the original logged meal no longer exists: the
/// favorite is then shown as unavailable and can only be removed. Nothing is
/// rebuilt from guesses.
class FavoriteMealView {
  const FavoriteMealView(this.favorite, this.meal);
  final FavoriteModel favorite;
  final MealEntryModel? meal;
  bool get available => meal != null;
}

/// A food seen in the user's own logs, with how many logged meals contained it.
class FrequentFood {
  const FrequentFood({
    required this.foodId,
    required this.name,
    required this.count,
    required this.lastAt,
  });
  final String foodId;
  final String name;
  final int count;
  final DateTime lastAt;
}

/// The most frequently logged foods in the window, newest tie-break.
/// Only meals owned by [uid] count. A food counts once per meal.
/// Items with no id or no name are skipped (never invented).
List<FrequentFood> frequentFoods(
  Iterable<MealEntryModel> meals, {
  required String uid,
  required DateTime now,
  Duration window = const Duration(days: 30),
  int limit = 20,
}) {
  final from = now.subtract(window);
  final counts = <String, int>{};
  final names = <String, String>{};
  final last = <String, DateTime>{};
  for (final m in meals) {
    if (m.userId != uid ||
        m.consumedAt.isBefore(from) ||
        m.consumedAt.isAfter(now)) {
      continue;
    }
    final seen = <String>{};
    for (final i in m.items) {
      final id = i.foodId.trim();
      final name = i.foodName.trim();
      if (id.isEmpty || name.isEmpty || !seen.add(id)) continue;
      counts[id] = (counts[id] ?? 0) + 1;
      names.putIfAbsent(id, () => name);
      final prev = last[id];
      if (prev == null || m.consumedAt.isAfter(prev)) last[id] = m.consumedAt;
    }
  }
  final out =
      [
        for (final e in counts.entries)
          FrequentFood(
            foodId: e.key,
            name: names[e.key]!,
            count: e.value,
            lastAt: last[e.key]!,
          ),
      ]..sort((a, b) {
        final c = b.count.compareTo(a.count);
        return c != 0 ? c : b.lastAt.compareTo(a.lastAt);
      });
  return out.take(limit).toList(growable: false);
}

/// Logged-meal titles, grouped, counted in the window: the design's hero
/// ("الأكثر تسجيلًا ... سجّلته N مرات"). Null when nothing was logged.
({String title, int count})? mostLoggedMeal(
  Iterable<MealEntryModel> meals, {
  required String uid,
  required DateTime now,
  Duration window = const Duration(days: 30),
}) {
  final from = now.subtract(window);
  final counts = <String, int>{};
  for (final m in meals) {
    if (m.userId != uid ||
        m.consumedAt.isBefore(from) ||
        m.consumedAt.isAfter(now)) {
      continue;
    }
    final t = m.title.trim();
    if (t.isNotEmpty) counts[t] = (counts[t] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  final best = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
  return (title: best.key, count: best.value);
}

List<FavoriteMealView> sortMeals(
  List<FavoriteMealView> input,
  FavoritesSort sort,
) {
  final list = [...input];
  int cmpName(FavoriteMealView a, FavoriteMealView b) =>
      a.favorite.title.compareTo(b.favorite.title);
  switch (sort) {
    case FavoritesSort.name:
      list.sort(cmpName);
    case FavoritesSort.calories:
      // Unavailable meals have no known calories: they go last, never as 0.
      list.sort((a, b) {
        final x = a.meal?.totalCalories, y = b.meal?.totalCalories;
        if (x == null && y == null) return cmpName(a, b);
        if (x == null) return 1;
        if (y == null) return -1;
        final c = y.compareTo(x);
        return c != 0 ? c : cmpName(a, b);
      });
    case FavoritesSort.recent:
      list.sort((a, b) {
        final x = a.favorite.createdAt, y = b.favorite.createdAt;
        if (x == null && y == null) return cmpName(a, b);
        if (x == null) return 1;
        if (y == null) return -1;
        return y.compareTo(x);
      });
  }
  return list;
}

/// Copy of a saved meal for "add to diary": same stored items and totals,
/// new id and time. Unknown nutrients stay unknown. The same instance is
/// reused across retries by the caller so a lost acknowledgement cannot
/// create two meals.
MealEntryModel mealCopyForDiary(
  MealEntryModel meal, {
  required String uid,
  required String id,
  required DateTime at,
  required String mealType,
}) {
  if (meal.userId != uid ||
      uid.isEmpty ||
      id.isEmpty ||
      id.contains('/') ||
      meal.title.trim().isEmpty ||
      meal.items.isEmpty ||
      !const {
        'breakfast',
        'lunch',
        'dinner',
        'snack',
        'suhoor',
        'iftar',
      }.contains(mealType)) {
    throw ArgumentError('Invalid favorite meal copy');
  }
  for (final item in meal.items) {
    if (item.foodId.trim().isEmpty ||
        item.foodName.trim().isEmpty ||
        !item.weightInGrams.isFinite ||
        item.weightInGrams <= 0 ||
        item.weightInGrams > 10000 ||
        !item.quantity.isFinite ||
        item.quantity <= 0 ||
        knownNutrient(item.calories) == null) {
      throw ArgumentError('Invalid favorite ingredient');
    }
  }
  void verify(double? total, Iterable<double?> values) {
    final calculated = sumKnownNutrients(values);
    if (total == null && calculated == null) return;
    if (total == null ||
        calculated == null ||
        knownNutrient(total) == null ||
        (total - calculated).abs() > .02) {
      throw ArgumentError('Inconsistent favorite nutrients');
    }
  }

  verify(meal.totalCalories, meal.items.map((i) => i.calories));
  verify(meal.totalProtein, meal.items.map((i) => i.protein));
  verify(meal.totalCarbs, meal.items.map((i) => i.carbohydrates));
  verify(meal.totalFat, meal.items.map((i) => i.fat));
  verify(meal.totalFiber, meal.items.map((i) => i.fiber));
  verify(meal.totalSugar, meal.items.map((i) => i.sugar));
  verify(meal.totalSodium, meal.items.map((i) => i.sodium));
  return MealEntryModel(
    mealId: id,
    userId: uid,
    dateKey: SufraDateUtils.toDateKey(at),
    consumedAt: at,
    mealType: mealType,
    inputMethod: 'relog',
    title: meal.title,
    imageUrl: meal.imageUrl,
    items: List.unmodifiable(meal.items),
    totalCalories: meal.totalCalories,
    totalProtein: meal.totalProtein,
    totalCarbs: meal.totalCarbs,
    totalFat: meal.totalFat,
    totalFiber: meal.totalFiber,
    totalSugar: meal.totalSugar,
    totalSodium: meal.totalSodium,
    analysisStatus: meal.analysisStatus,
    confidence: meal.confidence,
    estimatedRange: meal.estimatedRange,
    nutritionSource: meal.nutritionSource,
  );
}
