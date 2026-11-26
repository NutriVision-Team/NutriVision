import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/features/camera_analysis/domain/food_recognition_provider.dart';
import 'package:sufradepi/features/camera_analysis/domain/photo_meal_resolver.dart';
import 'package:sufradepi/features/camera_analysis/domain/photo_meal_clarification.dart';
import 'package:sufradepi/features/meal_log/domain/catalog_meal_draft.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'quantity and separate oil change deterministic totals; skipped or unresolved oil does not',
    () async {
      final foods = await LocalFoodDataSource().getAll();
      final meal = const PhotoMealResolver()
          .resolve(
            const FoodRecognitionResult(
              items: [
                RecognitionCandidate(
                  name: 'cooked rice',
                  foodState: 'cooked',
                  suggestedPortionGrams: 150,
                ),
              ],
            ),
            foods,
          )
          .values;
      expect(CatalogMealDraft(meal).totals!.energyKcal, 195);
      final oil = PhotoMealClarification.oliveOil(
        grams: 10,
        separateFromFood: true,
        meal: meal,
        foods: foods,
      )!;
      expect(oil.grams, 10);
      expect(oil.amount('calories'), 88.4);
      expect(
        CatalogMealDraft([...meal, oil]).totals!.energyKcal,
        closeTo(283.4, .0001),
      );
      for (final g in [double.nan, double.infinity, -1.0, 0.0, 201.0]) {
        expect(
          PhotoMealClarification.oliveOil(
            grams: g,
            separateFromFood: true,
            meal: meal,
            foods: foods,
          ),
          isNull,
        );
      }
      expect(
        PhotoMealClarification.oliveOil(
          grams: 10,
          separateFromFood: false,
          meal: meal,
          foods: foods,
        ),
        isNull,
      );
      expect(
        PhotoMealClarification.oliveOil(
          grams: 10,
          separateFromFood: true,
          meal: [...meal, oil],
          foods: foods,
        ),
        isNull,
      );
      expect(
        PhotoMealClarification.oliveOil(
          grams: 10,
          separateFromFood: true,
          meal: meal,
          foods: [],
        ),
        isNull,
      );
      expect(
        PhotoMealClarification.oliveOil(
          grams: 10,
          separateFromFood: true,
          meal: [],
          foods: foods,
        ),
        isNull,
      );
    },
  );
}
