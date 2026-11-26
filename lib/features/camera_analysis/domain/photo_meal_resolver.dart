import '../../../data/models/food_catalog_model.dart';
import '../../food_catalog/data/datasources/local_food_data_source.dart';
import '../../meal_log/domain/food_portion.dart';
import 'food_recognition_provider.dart';

/// Resolves only exact catalog identities with an explicit matching preparation
/// state. Dry rice is never silently used for a cooked rice plate. Recognition
/// supplies uncertain amounts, never nutrition. Caller must request review.
class PhotoMealResolver {
  const PhotoMealResolver();
  static String normalized(String text) => text
      .toLowerCase()
      .trim()
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[ً-ْ]'), '')
      .replaceAll(RegExp(r'[,،;:()_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  // Only order and punctuation vary. Every identity/preparation word remains.
  static String identityKey(String text) {
    final words = normalized(text).split(' ')..sort();
    return words.join(' ');
  }

  Map<int, FoodPortion> resolve(
    FoodRecognitionResult result,
    List<LocalFoodRecord> foods,
  ) {
    final resolved = <int, FoodPortion>{};
    for (var i = 0; i < result.items.length; i++) {
      final candidate = result.items[i];
      final grams = candidate.suggestedPortionGrams;
      final state = candidate.foodState;
      if (grams == null || state == null || state == 'unknown') continue;
      final possible = foods
          .where(
            (f) =>
                f.foodState == state &&
                (candidate.matchedFoodId != null
                    ? f.id == candidate.matchedFoodId
                    : [f.nameAr, f.nameEn, ...f.aliases].any(
                        (n) => identityKey(n) == identityKey(candidate.name),
                      )),
          )
          .toList();
      if (possible.length != 1) continue;
      final f = possible.single;
      final portion = FoodPortion(
        FoodCatalogModel(
          foodId: f.id,
          name: f.nameAr.isEmpty ? f.nameEn : f.nameAr,
          localizedNames: {'ar': f.nameAr, 'en': f.nameEn},
          category: f.category,
          foodState: f.foodState,
          source: '${f.source.provider}, ${f.source.sourceVersion}',
          sourceId: f.source.fdcId.toString(),
          sourceUrl: f.source.url,
          verificationStatus: f.dataQuality,
          nutritionPer100g: {
            'calories': f.nutrientsPer100g.energyKcal,
            'protein': f.nutrientsPer100g.proteinG,
            'carbohydrates': f.nutrientsPer100g.carbohydrateG,
            'fat': f.nutrientsPer100g.fatG,
            'fiber': f.nutrientsPer100g.fiberG,
            'sugar': f.nutrientsPer100g.sugarsG,
            'sodium': f.nutrientsPer100g.sodiumMg,
          },
        ),
        grams,
      );
      if (portion.canSave) resolved[i] = portion;
    }
    // One proposal must not count the same food twice. The model may repeat a
    // name or list a dish and a synonymous component. Leave every conflicting
    // candidate unresolved instead of choosing one silently.
    final counts = <String, int>{};
    for (final p in resolved.values) {
      counts.update(p.food.foodId, (v) => v + 1, ifAbsent: () => 1);
    }
    resolved.removeWhere((_, p) => (counts[p.food.foodId] ?? 0) > 1);
    return Map.unmodifiable(resolved);
  }
}
