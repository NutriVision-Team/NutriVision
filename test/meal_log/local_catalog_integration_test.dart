import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/features/food_catalog/data/local_food_repository.dart';
import 'package:sufradepi/features/recipes/data/datasources/local_recipe_data_source.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled food catalog parses all 101 records with stable source IDs',
    () async {
      final source = LocalFoodDataSource();
      final records = await source.getAll();
      expect(records, hasLength(101));
      expect(records.map((r) => r.id).toSet(), hasLength(101));
      expect(
        records.every(
          (r) => r.source.fdcId > 0 && r.source.provider.isNotEmpty,
        ),
        isTrue,
      );
      expect(source.isLoaded, isTrue);
      expect(() => records.clear(), throwsUnsupportedError);
    },
  );

  test(
    'source anomalies survive as null through UI repository adapter',
    () async {
      final repo = LocalFoodRepository();
      for (final id in ['usda_foundation_2727566', 'usda_foundation_2727570']) {
        final food = await repo.getFoodById(id);
        expect(food, isNotNull);
        expect(food!.nutritionPer100g!['carbohydrates'], isNull);
        final portion = FoodPortion(food, 100);
        expect(portion.canSave, isTrue);
        expect(
          portion
              .toMeal(
                uid: 'fixture',
                id: id,
                at: DateTime(2026, 11, 22),
                mealType: 'lunch',
              )
              .totalCarbs,
          isNull,
        );
        expect(food.foodState, isNotEmpty);
        expect(food.sourceUrl, startsWith('https://'));
      }
    },
  );

  test(
    'Arabic aliases and English names search offline without dropping source state',
    () async {
      final source = LocalFoodDataSource();
      expect(await source.search('بيض'), isNotEmpty);
      expect(await source.search('EGG'), isNotEmpty);
      expect(await source.search('   '), isEmpty);
      final repo = LocalFoodRepository(source: source);
      final mapped = await repo.searchFood('egg');
      expect(mapped.every((r) => r.foodState?.isNotEmpty == true), isTrue);
      expect(await repo.getFoodById('does-not-exist'), isNull);
    },
  );

  test(
    'all recipe measures are preserved, and recipe nutrition is explicitly unknown',
    () async {
      final records = await LocalRecipeDataSource().getAll();
      expect(records, hasLength(8));
      for (final recipe in records) {
        expect(recipe.nutritionStatus, 'not_calculable_from_source');
        expect(recipe.ingredients, isNotEmpty);
        expect(
          recipe.ingredients.every((i) => i.normalizedQuantityGrams == null),
          isTrue,
        );
        expect(recipe.source.licenseNote, isNotEmpty);
        expect(recipe.instructions, isNotEmpty);
      }
    },
  );

  test(
    'runtime datasets contain no FAO-derived records and terms registry retains release gate',
    () async {
      final sources = jsonDecode(
        await rootBundle.loadString('assets/data/data_sources.json'),
      );
      final records = sources['sources'] as List<dynamic>;
      final fao = records.singleWhere((s) => s['id'] == 'fao_near_east');
      expect(fao['status'], 'reference_only_license_review_required');
      final recipes = records.singleWhere((s) => s['id'] == 'themealdb');
      expect(
        (recipes['license'] as String).toLowerCase(),
        contains('development'),
      );
      for (final file in ['foods', 'recipes', 'alternatives']) {
        final raw = await rootBundle.loadString('assets/data/$file.json');
        expect(raw.toLowerCase(), isNot(contains('fao.org')));
      }
    },
  );
}
