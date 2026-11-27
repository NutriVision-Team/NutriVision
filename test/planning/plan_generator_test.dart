import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/features/planner/domain/weekly_plan_generator.dart';

LocalFoodRecord food(
  String id,
  String category,
  double? kcal, {
  String nameAr = 'صنف',
  List<String> aliases = const [],
}) => LocalFoodRecord(
  id: id,
  nameAr: nameAr,
  nameEn: id,
  aliases: aliases,
  category: category,
  foodState: 'prepared',
  referenceAmountGrams: 100,
  nutrientsPer100g: LocalFoodNutrients(energyKcal: kcal),
  dataQuality: 'verified_source',
  source: const LocalFoodSource(
    provider: 'fixture',
    dataset: 'fixture',
    fdcId: 1,
    sourceVersion: '1',
    url: 'fixture',
  ),
);

List<LocalFoodRecord> catalog() => [
  food('egg1', 'eggs', 148, nameAr: 'بيض'),
  food('milk1', 'dairy', 60, nameAr: 'زبادي'),
  food('chicken1', 'poultry', 165, nameAr: 'فراخ'),
  food('rice1', 'grains', 359, nameAr: 'خبز'),
  food('lentil1', 'legumes', 360, nameAr: 'عدس'),
  food('spinach1', 'vegetables', 25, nameAr: 'خيار'),
  food('apple1', 'fruits', 52, nameAr: 'تفاح'),
  food('nuts1', 'nuts_seeds', 588, nameAr: 'فول سوداني'),
  food('mystery1', 'grains', null, nameAr: 'صنف مجهول الطاقة'),
];

void main() {
  final generator = WeeklyPlanGenerator(catalog: catalog());
  final weekStart = DateTime(2026, 11, 21); // a Saturday

  test('weekStartOf returns the Egyptian Saturday-first week', () {
    expect(WeeklyPlanGenerator.weekStartOf(DateTime(2026, 11, 21)), weekStart);
    expect(WeeklyPlanGenerator.weekStartOf(DateTime(2026, 11, 22)), weekStart);
    expect(WeeklyPlanGenerator.weekStartOf(DateTime(2026, 11, 27)), weekStart);
    expect(
      WeeklyPlanGenerator.weekStartOf(DateTime(2026, 11, 28)),
      DateTime(2026, 11, 28),
    );
  });

  test(
    'unmatched terms stay visible instead of claiming semantic matching',
    () {
      expect(generator.unmatchedFoodTerms(['لبن غير مسجل', 'milk1', '  ']), [
        'لبن غير مسجل',
      ]);
    },
  );
  test('vegan excludes dairy eggs meat and fish before generation', () {
    final plan = generator.generate(
      weekStart: weekStart,
      dailyCalorieTarget: 2000,
      seed: 1,
      dietaryPreferences: ['vegan'],
    );
    final ids = plan.meals.expand((m) => m.foods).toSet();
    expect(ids.intersection({'milk1', 'egg1', 'chicken1'}), isEmpty);
    expect(plan.meals.where((m) => m.mealType == 'breakfast').length, 7);
  });
  test(
    'swap changes candidate when possible, never returns identical meal',
    () {
      final g = WeeklyPlanGenerator(
        catalog: [
          ...catalog(),
          food('milk2', 'dairy', 70, nameAr: 'زبادي يوناني'),
        ],
      );
      final a = g.generateMeal(
        day: weekStart,
        mealType: 'breakfast',
        dailyCalorieTarget: 2000,
        seed: 1,
        preferredFoods: ['milk1'],
      )!;
      final b = g.generateMeal(
        day: weekStart,
        mealType: 'breakfast',
        dailyCalorieTarget: 2000,
        seed: 1,
        preferredFoods: ['milk1'],
        previousFoodIds: a.foods,
      )!;
      expect(b.foods, isNot(a.foods));
      expect(b.foods.first, isNot('milk1'));
      final none = generator.generateMeal(
        day: weekStart,
        mealType: 'breakfast',
        dailyCalorieTarget: 2000,
        seed: 1,
        excludedFoodIds: const {'egg1', 'lentil1'},
        previousFoodIds: ['milk1', 'rice1', 'apple1'],
      );
      expect(none, isNull);
    },
  );
  test('weekly usage spreads equivalent candidates before repeating', () {
    final g = WeeklyPlanGenerator(
      catalog: [
        ...catalog(),
        food('milk2', 'dairy', 70, nameAr: 'زبادي يوناني'),
      ],
    );
    final plan = g.generate(
      weekStart: weekStart,
      dailyCalorieTarget: 2000,
      seed: 4,
    );
    final breakfasts = plan.meals.where((m) => m.mealType == 'breakfast');
    expect(
      breakfasts.where((m) => m.foods.contains('milk1')).length,
      inInclusiveRange(3, 4),
    );
    expect(
      breakfasts.where((m) => m.foods.contains('milk2')).length,
      inInclusiveRange(3, 4),
    );
  });
  test('three meal choice omits snacks and preserves target fraction sum', () {
    final p = generator.generate(
      weekStart: weekStart,
      dailyCalorieTarget: 2000,
      seed: 1,
      mealsPerDay: 3,
    );
    expect(p.meals.length, 21);
    expect(p.meals.any((m) => m.mealType == 'snack'), false);
    expect(
      [
        'breakfast',
        'lunch',
        'dinner',
      ].fold<double>(0, (s, v) => s + WeeklyPlanGenerator.fractionFor(v, 3)),
      1,
    );
    expect(
      () => generator.generate(
        weekStart: weekStart,
        dailyCalorieTarget: 2000,
        seed: 1,
        mealsPerDay: 5,
      ),
      throwsArgumentError,
    );
  });
  test('foods with unknown energy are never plannable', () {
    expect(generator.eligible.map((f) => f.id), isNot(contains('mystery1')));
    expect(generator.eligible.length, 8);
  });

  test(
    'generation is deterministic for the same seed and covers 7x4 slots',
    () {
      final a = generator.generate(
        weekStart: weekStart,
        dailyCalorieTarget: 2000,
        seed: 42,
      );
      final b = generator.generate(
        weekStart: weekStart,
        dailyCalorieTarget: 2000,
        seed: 42,
      );
      expect(a.meals.length, 28);
      expect(a.planId, WeeklyPlanGenerator.planIdFor(weekStart));
      for (var i = 0; i < 28; i++) {
        expect(a.meals[i].mealId, b.meals[i].mealId);
        expect(a.meals[i].calories, b.meals[i].calories);
        expect(a.meals[i].foods, b.meals[i].foods);
      }
    },
  );

  test(
    'meal calories equal the measured grams computation, never invented',
    () {
      final plan = generator.generate(
        weekStart: weekStart,
        dailyCalorieTarget: 2000,
        seed: 7,
      );
      final byId = {for (final f in catalog()) f.id: f};
      for (final meal in plan.meals) {
        var expected = 0.0;
        final portions = meal.foodPortions;
        expect(portions, isNotNull);
        expect(portions!.length, meal.foods.length);
        for (final portion in portions) {
          expect(meal.foods, contains(portion.foodId));
          expected +=
              portion.grams /
              100 *
              byId[portion.foodId]!.nutrientsPer100g.energyKcal!;
        }
        expect(meal.calories, closeTo(expected, 0.001));
        expect(meal.calories, greaterThan(0));
      }
    },
  );

  test('slot ids encode their calendar day reversibly', () {
    final plan = generator.generate(
      weekStart: weekStart,
      dailyCalorieTarget: 1800,
      seed: 3,
    );
    final keys = plan.meals.map((m) => m.dateKey).toSet();
    expect(keys.length, 7);
    expect(keys, contains('2026-11-21'));
    expect(keys, contains('2026-11-27'));
  });

  test('allergy terms exclude matching foods at name level', () {
    final excluded = generator.excludedByAllergy(['بيض']);
    expect(excluded, contains('egg1'));
    final plan = generator.generate(
      weekStart: weekStart,
      dailyCalorieTarget: 2000,
      seed: 5,
      allergies: ['بيض'],
    );
    final allPortions = plan.meals.expand((m) => m.foodPortions!);
    expect(allPortions.map((p) => p.foodId), isNot(contains('egg1')));
    for (final meal in plan.meals) {
      // foods stays canonical ids; typed portions carry the quantities.
      expect(meal.foods.every((f) => !f.contains(':')), isTrue);
    }
  });

  test('rejects a non-positive target instead of inventing a plan', () {
    expect(
      () => generator.generate(
        weekStart: weekStart,
        dailyCalorieTarget: 0,
        seed: 1,
      ),
      throwsArgumentError,
    );
  });
  test(
    'real catalog produces complementary edible meals, never raw meat or dry flour',
    () {
      final data =
          jsonDecode(File('assets/data/foods.json').readAsStringSync()) as Map;
      final records = (data['foods'] as List)
          .map((f) => LocalFoodRecord.fromJson(Map<String, dynamic>.from(f)))
          .toList();
      final real = WeeklyPlanGenerator(catalog: records);
      final byId = {for (final f in records) f.id: f};
      for (var seed = 0; seed < 20; seed++) {
        final plan = real.generate(
          weekStart: weekStart,
          dailyCalorieTarget: 2100,
          seed: seed,
        );
        expect(plan.meals.length, 28);
        for (final meal in plan.meals) {
          final foods = meal.foods.map((id) => byId[id]!).toList();
          expect(
            foods.any(
              (f) => RegExp(
                r'flour|paste|butter|dry',
                caseSensitive: false,
              ).hasMatch(f.nameEn),
            ),
            isFalse,
          );
          expect(
            foods.any(
              (f) =>
                  const [
                    'meat',
                    'fish',
                    'poultry',
                    'eggs',
                  ].contains(f.category) &&
                  f.foodState == 'raw',
            ),
            isFalse,
          );
          expect(foods.map((f) => f.category).toSet().length, foods.length);
          expect(meal.foodPortions!.every((p) => p.grams <= 300), isTrue);
        }
      }
    },
  );
  test('food choices rank within roles, exclusions always win', () {
    final g = WeeklyPlanGenerator(
      catalog: [
        ...catalog(),
        food('milk2', 'dairy', 70, nameAr: 'زبادي يوناني'),
      ],
    );
    final a = g.generate(
      weekStart: weekStart,
      dailyCalorieTarget: 2000,
      seed: 1,
      preferredFoods: ['milk2'],
    );
    expect(a.meals.first.foods, contains('milk2'));
    expect(
      a.meals
          .where((m) => m.mealType == 'breakfast')
          .map((m) => m.foods.first)
          .toSet()
          .length,
      greaterThan(1),
    );
    for (final m in a.meals.where((m) => m.mealType == 'breakfast')) {
      expect(m.foods, contains('rice1'));
    }
    final b = g.generate(
      weekStart: weekStart,
      dailyCalorieTarget: 2000,
      seed: 1,
      preferredFoods: ['milk2'],
      excludedFoods: ['milk2'],
    );
    expect(b.meals.expand((m) => m.foods), isNot(contains('milk2')));
    expect(b.meals.where((m) => m.mealType == 'breakfast').length, 7);
    final gap = g.generate(
      weekStart: weekStart,
      dailyCalorieTarget: 2000,
      seed: 1,
      excludedFoods: ['خبز'],
    );
    expect(gap.meals.where((m) => m.mealType == 'breakfast'), isEmpty);
  });
  test('authored assembly quantities stay bounded at high energy targets', () {
    final data =
        jsonDecode(File('assets/data/foods.json').readAsStringSync()) as Map;
    final records = (data['foods'] as List)
        .map((f) => LocalFoodRecord.fromJson(Map<String, dynamic>.from(f)))
        .toList();
    final g = WeeklyPlanGenerator(catalog: records);
    final byId = {for (final f in records) f.id: f};
    for (var seed = 0; seed < 30; seed++) {
      final plan = g.generate(
        weekStart: weekStart,
        dailyCalorieTarget: 4000,
        seed: seed,
      );
      for (final meal in plan.meals) {
        var total = 0.0;
        for (final p in meal.foodPortions!) {
          final f = byId[p.foodId]!;
          final max = f.category == 'grains'
              ? (f.nameEn.toLowerCase().contains('bread') ? 105 : 300)
              : f.category == 'dairy'
              ? (f.nameEn.toLowerCase().contains('cottage')
                    ? 150
                    : f.nameEn.toLowerCase().contains('cheese')
                    ? 30
                    : 250)
              : f.category == 'legumes'
              ? 225
              : const ['poultry', 'meat'].contains(f.category)
              ? 135
              : f.category == 'fats'
              ? 10
              : WeeklyPlanGenerator.sampleServingLimit(f);
          expect(p.grams, lessThanOrEqualTo(max));
          expect(p.grams % 5, 0);
          expect(f.nameEn.toLowerCase().contains('hummus'), isFalse);
          expect(f.nameEn.toLowerCase().contains('avocado'), isFalse);
          total += p.grams / 100 * f.nutrientsPer100g.energyKcal!;
          if (f.foodState == 'dried') expect(p.grams, lessThanOrEqualTo(30));
          if (f.nameEn.toLowerCase().contains('cottage')) {
            expect(p.grams, lessThanOrEqualTo(150));
          }
        }
        expect(meal.calories, closeTo(total, 0.001));
      }
      expect(
        plan.meals.fold<double>(0, (s, m) => s + m.calories),
        lessThan(4000 * 7),
      );
    }
  });
  test(
    'missing complementary role leaves a gap instead of raw substitution',
    () {
      final g = WeeklyPlanGenerator(
        catalog: [food('raw-chicken', 'poultry', 165)],
      );
      expect(
        g.generateMeal(
          day: weekStart,
          mealType: 'lunch',
          dailyCalorieTarget: 2000,
          seed: 1,
        ),
        isNull,
      );
    },
  );
}
