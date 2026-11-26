import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/catalog_food_art.dart';
import 'package:sufradepi/features/recipes/presentation/recipe_arabic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    '95 original foods retain explicit art; six cooked/prepared additions use honest fallback',
    () async {
      final data =
          jsonDecode(await rootBundle.loadString('assets/data/foods.json'))
              as Map;
      final foods = data['foods'] as List;
      expect(foods.length, 101);
      final original = foods
          .where((f) => (f['id'] as String).startsWith('usda_foundation_'))
          .toList();
      expect(original.length, 95);
      final actual = original
          .map((f) => CatalogFoodPainter.identity(f['id'] as String))
          .toList();
      expect(actual.every((a) => a != null), isTrue);
      expect(actual.toSet().length, 95);
      final added = foods.where((f) => !original.contains(f));
      expect(added.map((f) => f['id']).toSet(), {
        'usda_sr_168878',
        'usda_sr_168928',
        'usda_sr_172421',
        'usda_sr_173757',
        'usda_sr_171413',
        'usda_sr_173753',
      });
      for (final food in added) {
        expect(CatalogFoodPainter.identity(food['id'] as String), isNull);
      }
    },
  );
  test(
    'Arabic ingredient names and instruction count cover all eight source dishes',
    () async {
      final data =
          jsonDecode(await rootBundle.loadString('assets/data/recipes.json'))
              as Map;
      for (final recipe in data['recipes'] as List) {
        expect(
          RecipeArabic.steps[recipe['id']]!.length,
          (recipe['instructions'] as List).length,
        );
        for (final ingredient in recipe['ingredients'] as List) {
          expect(
            RecipeArabic.ingredients.containsKey(ingredient['name']),
            isTrue,
            reason: ingredient['name'],
          );
        }
      }
    },
  );
}
