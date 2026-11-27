import 'assembly_portions.dart';
import '../../alternatives/domain/food_preference_filter.dart';
import 'dart:math';

import '../../../../core/utils/date_utils.dart';
import '../../../../data/models/meal_plan_model.dart';
import '../../food_catalog/data/datasources/local_food_data_source.dart';

/// Meal slots in the weekly planner, in display order.
const plannerSlots = <String>['breakfast', 'lunch', 'dinner', 'snack'];

/// Deterministic weekly meal-plan generator.
///
/// Builds a seven-day plan only from verified local catalog records whose
/// energy value is measured. Foods with unknown energy are never planned,
/// because their calories could not be shown honestly. No AI and no network
/// is involved; identical inputs always produce the identical plan.
class WeeklyPlanGenerator {
  WeeklyPlanGenerator({required List<LocalFoodRecord> catalog})
    : _eligible = List.unmodifiable(
        catalog.where((food) {
          final energy = food.nutrientsPer100g.energyKcal;
          return food.id.isNotEmpty &&
              food.nameAr.isNotEmpty &&
              energy != null &&
              energy > 0;
        }),
      );

  /// Catalog records with a measured energy value, the only plannable foods.
  final List<LocalFoodRecord> _eligible;

  List<LocalFoodRecord> get eligible => _eligible;

  /// The catalog category of [foodId], or null when it is not plannable.
  String? categoryOf(String foodId) {
    for (final food in _eligible) {
      if (food.id == foodId) return food.category;
    }
    return null;
  }

  String foodLabel(String id, {required bool arabic}) {
    for (final food in _eligible) {
      if (food.id == id) return arabic ? food.nameAr : food.nameEn;
    }
    return '';
  }

  /// Calorie share of each slot within a day.
  static const Map<String, double> slotFractions = {
    'breakfast': 0.25,
    'lunch': 0.35,
    'dinner': 0.30,
    'snack': 0.10,
  };

  static double fractionFor(String slot, int mealsPerDay) {
    if (!const [3, 4].contains(mealsPerDay)) {
      throw ArgumentError.value(mealsPerDay);
    }
    return mealsPerDay == 3
        ? (const {'breakfast': .3, 'lunch': .4, 'dinner': .3}[slot] ?? 0)
        : slotFractions[slot]!;
  }

  /// Slot-appropriate catalog categories, in preference order.
  static const Map<String, List<String>> slotCategories = {
    'breakfast': ['dairy', 'eggs', 'legumes', 'grains', 'fruits'],
    'lunch': ['poultry', 'meat', 'fish', 'grains', 'legumes', 'vegetables'],
    'dinner': ['vegetables', 'dairy', 'eggs', 'grains', 'fish'],
    'snack': ['fruits', 'nuts_seeds', 'dairy', 'beverages'],
  };

  /// The Egyptian week starts on Saturday.
  static DateTime weekStartOf(DateTime day) {
    final start = SufraDateUtils.startOfDay(day);
    return SufraDateUtils.shiftDays(
      start,
      -((start.weekday - DateTime.saturday + 7) % 7),
    );
  }

  /// Stable plan id for the week that starts on [weekStart]. Regenerating
  /// the same week replaces the same document instead of duplicating it.
  static String planIdFor(DateTime weekStart) =>
      'week_${SufraDateUtils.toDateKey(weekStart)}';

  /// Deterministic meal id binding a slot to a calendar day.
  static String mealIdFor(DateTime day, String mealType) =>
      '${SufraDateUtils.toDateKey(day)}:$mealType';

  /// Parses the day a planned meal belongs to from its deterministic id.
  static String? dateKeyOfMealId(String mealId) {
    final separator = mealId.indexOf(':');
    if (separator <= 0) return null;
    final key = mealId.substring(0, separator);
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key) ? key : null;
  }

  /// Generates a full seven-day plan. [seed] selects the rotation; callers
  /// pass a fresh value per explicit regeneration so each generated plan is
  /// a deliberate, persisted choice.
  MealPlanModel generate({
    required DateTime weekStart,
    required double dailyCalorieTarget,
    required int seed,
    List<String> allergies = const [],
    List<String> preferredFoods = const [],
    List<String> excludedFoods = const [],
    List<String> dietaryPreferences = const [],
    DateTime? createdAt,
    List<MealPlanMealModel> recordedMeals = const [],
    int mealsPerDay = 4,
  }) {
    if (!dailyCalorieTarget.isFinite || dailyCalorieTarget <= 0) {
      throw ArgumentError.value(
        dailyCalorieTarget,
        'dailyCalorieTarget',
        'A measured target is required to plan honestly',
      );
    }
    if (!const [3, 4].contains(mealsPerDay)) {
      throw ArgumentError.value(mealsPerDay, 'mealsPerDay');
    }
    final start = SufraDateUtils.startOfDay(weekStart);
    final excluded = {
      ..._excludedByAllergy(excludedFoods),
      ...excludedByConstraints(
        allergies: allergies,
        dietaryPreferences: dietaryPreferences,
      ),
    };
    final meals = <MealPlanMealModel>[];
    final usage = <String, int>{};
    final recordedUsage = <String, int>{};
    for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
      final day = SufraDateUtils.shiftDays(start, dayIndex);
      for (final slot in plannerSlots.where(
        (slot) => mealsPerDay == 4 || slot != 'snack',
      )) {
        var meal = generateMeal(
          day: day,
          mealType: slot,
          dailyCalorieTarget: dailyCalorieTarget,
          seed: seed,
          excludedFoodIds: excluded,
          preferredFoods: preferredFoods,
          foodUsage: usage,
          mealsPerDay: mealsPerDay,
        );
        final targetKcal = dailyCalorieTarget * fractionFor(slot, mealsPerDay);
        final candidates =
            recordedMeals
                .where(
                  (m) =>
                      m.mealType == slot &&
                      m.foods.every((id) => !excluded.contains(id)) &&
                      m.calories >= targetKcal * .75 &&
                      m.calories <= targetKcal * 1.25,
                )
                .toList()
              ..sort((a, b) {
                final count = (recordedUsage[a.mealId] ?? 0).compareTo(
                  recordedUsage[b.mealId] ?? 0,
                );
                return count != 0
                    ? count
                    : (a.calories - targetKcal).abs().compareTo(
                        (b.calories - targetKcal).abs(),
                      );
              });
        if (candidates.isNotEmpty &&
            (recordedUsage[candidates.first.mealId] ?? 0) < 2) {
          final c = candidates.first;
          recordedUsage.update(c.mealId, (n) => n + 1, ifAbsent: () => 1);
          meal = MealPlanMealModel(
            mealId: mealIdFor(day, slot),
            title: c.title,
            mealType: slot,
            calories: c.calories,
            foods: c.foods,
            foodPortions: c.foodPortions,
            dateKey: SufraDateUtils.toDateKey(day),
          );
        }
        if (meal != null) {
          meals.add(meal);
          for (final id in meal.foods) {
            usage.update(id, (v) => v + 1, ifAbsent: () => 1);
          }
        }
      }
    }
    if (meals.isEmpty) {
      throw StateError('No eligible foods for plan generation');
    }
    return MealPlanModel(
      planId: planIdFor(start),
      title: planIdFor(start),
      startDate: start,
      endDate: SufraDateUtils.shiftDays(start, 6),
      status: 'active',
      dailyCalorieTarget: dailyCalorieTarget,
      meals: meals,
      generatedBy: 'deterministic_catalog',
      createdAt: createdAt,
    );
  }

  /// Generates one slot meal for [day], or null when no eligible food
  /// remains for the slot after exclusions (the caller surfaces the gap
  /// instead of silently substituting an unsuitable food).
  MealPlanMealModel? generateMeal({
    required DateTime day,
    required String mealType,
    required double dailyCalorieTarget,
    required int seed,
    Set<String> excludedFoodIds = const {},
    List<String> preferredFoods = const [],
    List<String> previousFoodIds = const [],
    Map<String, int> foodUsage = const {},
    int mealsPerDay = 4,
  }) {
    if (!dailyCalorieTarget.isFinite || dailyCalorieTarget <= 0) {
      throw ArgumentError.value(dailyCalorieTarget, 'dailyCalorieTarget');
    }
    final categories = slotCategories[mealType];
    final fraction = slotFractions.containsKey(mealType)
        ? fractionFor(mealType, mealsPerDay)
        : null;
    if (categories == null || fraction == null) {
      throw ArgumentError.value(mealType, 'mealType', 'Unknown slot');
    }
    // Compose a meal from complementary ready-to-eat roles. Raw meat,
    // dry grains, flour, butter and condiments are not meals on their own.
    final pool = _eligible
        .where((f) => !excludedFoodIds.contains(f.id))
        .toList();
    final random = Random(
      seed ^
          SufraDateUtils.toDateKey(day).hashCode ^
          mealType.hashCode ^
          0x5f3a,
    );
    bool ready(LocalFoodRecord f) =>
        const {'cooked', 'prepared', 'canned'}.contains(f.foodState);
    bool bread(LocalFoodRecord f) =>
        f.category == 'grains' &&
        ready(f) &&
        RegExp(
          r'bread|عيش|خبز',
          caseSensitive: false,
        ).hasMatch('${f.nameEn} ${f.nameAr}');
    bool dairy(LocalFoodRecord f) =>
        f.category == 'dairy' &&
        !RegExp(
          r'butter|زبدة',
          caseSensitive: false,
        ).hasMatch('${f.nameEn} ${f.nameAr}');
    bool protein(LocalFoodRecord f) =>
        ready(f) &&
        const {'poultry', 'meat', 'fish', 'eggs'}.contains(f.category);
    bool legume(LocalFoodRecord f) =>
        ready(f) &&
        f.category == 'legumes' &&
        !RegExp(
          r'peanut|hummus|فول سوداني|حمص بالطحينة',
          caseSensitive: false,
        ).hasMatch('${f.nameEn} ${f.nameAr}');
    bool starch(LocalFoodRecord f) =>
        ready(f) &&
        f.category == 'grains' &&
        !RegExp(
          r'flour|دقيق|سميد',
          caseSensitive: false,
        ).hasMatch('${f.nameEn} ${f.nameAr}');
    bool vegetable(LocalFoodRecord f) =>
        f.category == 'vegetables' &&
        (ready(f) ||
            RegExp(
              r'cucumber|tomato, roma|carrot|lettuce|pepper, bell|خيار|طماطم$|جزر|خس|فلفل رومي',
              caseSensitive: false,
            ).hasMatch('${f.nameEn} ${f.nameAr}')) &&
        !RegExp(
          r'paste|معجون|garlic|ثوم',
          caseSensitive: false,
        ).hasMatch('${f.nameEn} ${f.nameAr}');
    final roles = <bool Function(LocalFoodRecord)>[
      if (mealType == 'breakfast') ...[
        (f) => dairy(f) || legume(f) || (protein(f) && f.category == 'eggs'),
        bread,
        (f) =>
            f.category == 'fruits' &&
            !f.nameEn.toLowerCase().contains('avocado'),
      ] else if (mealType == 'snack') ...[
        (f) =>
            f.category == 'fruits' &&
            !f.nameEn.toLowerCase().contains('avocado'),
        (f) =>
            f.category == 'nuts_seeds' &&
            !RegExp(
              r'butter|tahini|طحينة',
              caseSensitive: false,
            ).hasMatch('${f.nameEn} ${f.nameAr}'),
      ] else ...[
        (f) => protein(f) || legume(f),
        starch,
        vegetable,
      ],
    ];
    final picked = <LocalFoodRecord>[];
    for (final role in roles) {
      final candidates = pool
          .where(role)
          .where((f) => !picked.contains(f))
          .toList();
      if (candidates.isEmpty) return null;
      // Preferences rank within the same complementary role. They can never
      // reintroduce excluded foods or turn a nut into a main dish.
      final preferredIds = _excludedByAllergy(preferredFoods);
      final preferred = candidates
          .where((f) => preferredIds.contains(f.id))
          .toList();
      // Liked foods are soft choices, not permission to repeat one meal all
      // week. A two-use head start is a product variety rule, not nutrition.
      final freshPreferred = preferred
          .where((f) => (foodUsage[f.id] ?? 0) < 2)
          .toList();
      var choicePool = freshPreferred.isEmpty ? candidates : freshPreferred;
      // A requested swap may relax soft preferences, never exclusions, to
      // produce an actual alternative. No alternative returns null below.
      final roleIndex = picked.length;
      if (previousFoodIds.length > roleIndex) {
        final previous = previousFoodIds[roleIndex];
        final different = choicePool.where((f) => f.id != previous).toList();
        final fallback = candidates.where((f) => f.id != previous).toList();
        if (different.isNotEmpty) {
          choicePool = different;
        } else if (fallback.isNotEmpty) {
          choicePool = fallback;
        }
      }
      final least = choicePool.map((f) => foodUsage[f.id] ?? 0).reduce(min);
      final varied = choicePool
          .where((f) => (foodUsage[f.id] ?? 0) == least)
          .toList();
      picked.add(varied[random.nextInt(varied.length)]);
    }
    if (previousFoodIds.length == picked.length &&
        picked.indexed.every((v) => v.$2.id == previousFoodIds[v.$1])) {
      return null;
    }
    final mealKcal = dailyCalorieTarget * fraction;
    // Authored weighed assembly ranges only for the actual bundled catalog.
    // Synthetic/unknown schemas retain the conservative fallback below.
    if (picked.every(
      (f) => f.id.startsWith('usda_') || f.id.startsWith('fao_'),
    )) {
      final assembly = AssemblyPortions.compose(
        picked: picked,
        eligibleExtras: pool,
        mealId: mealIdFor(day, mealType),
        mealType: mealType,
        dateKey: SufraDateUtils.toDateKey(day),
        targetKcal: mealKcal,
      );
      if (assembly != null) return assembly;
    }

    final shares = mealType == 'snack'
        ? [0.5, 0.5]
        : mealType == 'breakfast'
        ? [0.35, 0.45, 0.2]
        : [0.4, 0.5, 0.1];
    final foods = <String>[];
    final portions = <MealPlanFoodPortion>[];
    final titles = <String>[];
    var calories = 0.0;
    for (final (index, food) in picked.indexed) {
      final shareKcal = mealKcal * shares[index];
      final per100 = food.nutrientsPer100g.energyKcal!;
      // Serving examples, not clinical maxima. Never inflate a low-energy
      // food just to fill a calorie share.
      final maximum = sampleServingLimit(food);
      final grams = (shareKcal / per100 * 100).clamp(15.0, maximum);
      // Readable 5 g increments. Calories always use the displayed quantity.
      final rounded = ((grams / 5).round() * 5).toDouble().clamp(15.0, maximum);
      calories += rounded / 100 * per100;
      foods.add(food.id);
      portions.add(MealPlanFoodPortion(foodId: food.id, grams: rounded));
      titles.add(food.nameAr);
    }

    return MealPlanMealModel(
      mealId: mealIdFor(day, mealType),
      title: titles.join(' و'),
      mealType: mealType,
      calories: calories,
      foods: foods,
      dateKey: SufraDateUtils.toDateKey(day),
      foodPortions: portions,
    );
  }

  /// Conservative sample-serving bounds based on adult portion examples.
  /// These are product defaults, not a personalised diet or maximum intake.
  static double sampleServingLimit(LocalFoodRecord food) {
    final name = food.nameEn.toLowerCase();
    switch (food.category) {
      case 'dairy':
        if (name.contains('cottage')) return 100;
        if (name.contains('cheese')) return 30;
        return 150;
      case 'nuts_seeds':
        return 30;
      case 'fruits':
        return food.foodState == 'dried' ? 30 : 160;
      case 'vegetables':
        return 160;
      case 'legumes':
        return 150;
      case 'poultry':
      case 'meat':
        return 90;
      case 'fish':
        return 140;
      case 'eggs':
        return 120;
      case 'grains':
        return RegExp(
              r'bread|عيش|خبز',
              caseSensitive: false,
            ).hasMatch('${food.nameEn} ${food.nameAr}')
            ? 70
            : 150;
      default:
        return 100;
    }
  }

  Set<String> excludedByConstraints({
    List<String> allergies = const [],
    List<String> dietaryPreferences = const [],
  }) => _eligible
      .where(
        (f) => !FoodPreferenceFilter.allows(
          f,
          allergies: allergies,
          dietaryPreferences: dietaryPreferences,
        ),
      )
      .map((f) => f.id)
      .toSet();

  List<String> unmatchedFoodTerms(List<String> terms) => terms
      .where(
        (term) => term.trim().isNotEmpty && _excludedByAllergy([term]).isEmpty,
      )
      .toList();

  /// Allergy filtering matches the words the user actually typed in their
  /// profile against catalog names, aliases and ids. The catalog carries no
  /// allergen tags, so this is a name-level guard, not a certified
  /// allergen screen; the UI states that limit explicitly.
  Set<String> excludedByAllergy(List<String> allergies) =>
      _excludedByAllergy(allergies);

  Set<String> _excludedByAllergy(List<String> allergies) {
    final terms = allergies
        .map((a) => a.trim().toLowerCase())
        .where((a) => a.isNotEmpty)
        .toList(growable: false);
    if (terms.isEmpty) return const {};
    final excluded = <String>{};
    for (final food in _eligible) {
      final haystack = [
        food.id.toLowerCase(),
        food.nameAr.toLowerCase(),
        food.nameEn.toLowerCase(),
        ...food.aliases.map((a) => a.toLowerCase()),
      ];
      final hit = terms.any(
        (term) => haystack.any((field) => field.contains(term)),
      );
      if (hit) excluded.add(food.id);
    }
    return excluded;
  }
}
