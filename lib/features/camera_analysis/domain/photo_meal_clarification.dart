import '../../food_catalog/data/datasources/local_food_data_source.dart';
import '../../meal_log/domain/food_portion.dart';
import 'food_recognition_provider.dart';
import 'photo_meal_resolver.dart';

/// Explicit grams in the eaten portion, never inferred from a note or image.
/// This control is only for separate olive oil not included in the chosen food.
class PhotoMealClarification {
  static FoodPortion? oliveOil({
    required double grams,
    required bool separateFromFood,
    required Iterable<FoodPortion> meal,
    required List<LocalFoodRecord> foods,
  }) {
    if (!separateFromFood ||
        !grams.isFinite ||
        grams <= 0 ||
        grams > 200 ||
        meal.isEmpty ||
        meal.any((p) => p.food.foodId == 'usda_sr_171413')) {
      return null;
    }
    return const PhotoMealResolver().resolve(
      FoodRecognitionResult(
        items: [
          RecognitionCandidate(
            name: 'olive oil',
            matchedFoodId: 'usda_sr_171413',
            foodState: 'prepared',
            suggestedPortionGrams: grams,
          ),
        ],
      ),
      foods,
    )[0];
  }
}
