import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ordinary screens do not restore removed source/reference displays', () {
    final forbidden = <String, List<String>>{
      'lib/features/camera_analysis/presentation/photo_meal_result_card.dart': [
        'p.food.source',
      ],
      'lib/features/home/presentation/widgets/home_recipe_section.dart': [
        'Text(l.homeRecipeSourceNote',
      ],
      'lib/features/meal_log/presentation/screens/meal_detail_screen.dart': [
        'l.foodSource(',
      ],
      'lib/features/barcode/presentation/screens/product_result_screen.dart': [
        'creditProduct(',
      ],
      'lib/features/recipes/presentation/screens/recipe_suggestion_screen.dart':
          ['.discoveryMsg036'],
      'lib/features/recipes/presentation/screens/quantified_recipe_screen.dart':
          ['r.source.provider', 'r.source.url'],
      'lib/features/alternatives/presentation/screens/alternatives_screen.dart':
          ['record.original.source.provider', 'record.original.source.url'],
    };
    for (final file in forbidden.entries) {
      final text = File(file.key).readAsStringSync();
      for (final token in file.value) {
        expect(text.contains(token), isFalse, reason: '${file.key}: $token');
      }
    }
    final barcode = File(
      'lib/features/barcode/presentation/screens/product_result_screen.dart',
    ).readAsStringSync();
    expect(barcode, contains('l.productAttribution'));
    expect(barcode, contains("ValueKey('off-attribution')"));
    final legal = File(
      'lib/core/widgets/sufra_licenses_screen.dart',
    ).readAsStringSync();
    expect(legal, contains('Open Food Facts contributors'));
    expect(legal, contains('image_credits.json'));
    expect(legal, contains('recipes.json'));
  });
}
