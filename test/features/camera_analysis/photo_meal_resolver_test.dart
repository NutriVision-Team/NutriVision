import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/camera_analysis/domain/photo_meal_resolver.dart';
import 'package:sufradepi/features/camera_analysis/domain/food_recognition_provider.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'cooked rice exact identity calculates sourced calories, never dry rice',
    () async {
      final foods = await LocalFoodDataSource().getAll();
      const resolver = PhotoMealResolver();
      FoodRecognitionResult result(String? state, {double? grams = 150}) =>
          FoodRecognitionResult(
            items: [
              RecognitionCandidate(
                name: 'cooked rice',
                foodState: state,
                suggestedPortionGrams: grams,
              ),
            ],
          );
      final found = resolver.resolve(result('cooked'), foods);
      expect(found[0]!.food.foodId, 'usda_sr_168878');
      expect(found[0]!.amount('calories'), 195);
      expect(
        found[0]!.food.sourceUrl,
        'https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_json_2018-04.zip',
      );
      expect(resolver.resolve(result('dried'), foods), isEmpty);
      expect(resolver.resolve(result(null), foods), isEmpty);
      expect(resolver.resolve(result('cooked', grams: null), foods), isEmpty);
    },
  );
  test(
    'ordinary cooked names resolve only within matching preparation',
    () async {
      final foods = await LocalFoodDataSource().getAll();
      const r = PhotoMealResolver();
      for (final name in [
        'rice',
        'white rice',
        'steamed rice',
        'pasta',
        'lentils',
        'chickpeas',
      ]) {
        FoodRecognitionResult result(String state) => FoodRecognitionResult(
          items: [
            RecognitionCandidate(
              name: name,
              foodState: state,
              suggestedPortionGrams: 150,
            ),
          ],
        );
        expect(r.resolve(result('cooked'), foods), hasLength(1), reason: name);
        expect(r.resolve(result('unknown'), foods), isEmpty);
        expect(r.resolve(result('prepared'), foods), isEmpty);
      }
    },
  );
  test('boiled fava base is not silently substituted for ful recipe', () async {
    final foods = await LocalFoodDataSource().getAll();
    const resolver = PhotoMealResolver();
    FoodRecognitionResult result(String name, String state) =>
        FoodRecognitionResult(
          items: [
            RecognitionCandidate(
              name: name,
              foodState: state,
              suggestedPortionGrams: 200,
            ),
          ],
        );
    final base = resolver.resolve(result('boiled fava beans', 'cooked'), foods);
    expect(base[0]!.food.foodId, 'usda_sr_173753');
    expect(base[0]!.amount('calories'), 220);
    expect(base[0]!.food.name, contains('من غير زيت'));
    expect(resolver.resolve(result('ful medames', 'prepared'), foods), isEmpty);
    expect(resolver.resolve(result('kidney beans', 'cooked'), foods), isEmpty);
  });
  test('unknown composite cannot borrow another food nutrition', () async {
    final foods = await LocalFoodDataSource().getAll();
    expect(
      const PhotoMealResolver().resolve(
        const FoodRecognitionResult(
          items: [
            RecognitionCandidate(
              name: 'koshari',
              foodState: 'cooked',
              suggestedPortionGrams: 300,
            ),
          ],
        ),
        foods,
      ),
      isEmpty,
    );
    expect(foods.where((f) => f.id.startsWith('fao_')), isEmpty);
  });
  test(
    'duplicate identities abstain rather than double-counting aliases',
    () async {
      final foods = await LocalFoodDataSource().getAll();
      final matched = const PhotoMealResolver().resolve(
        const FoodRecognitionResult(
          items: [
            RecognitionCandidate(
              name: 'cooked rice',
              foodState: 'cooked',
              suggestedPortionGrams: 150,
            ),
            RecognitionCandidate(
              name: 'cooked white rice',
              foodState: 'cooked',
              suggestedPortionGrams: 150,
            ),
          ],
        ),
        foods,
      );
      expect(matched, isEmpty);
    },
  );
  test(
    'word order and punctuation normalize, ingredient or preparation changes do not',
    () async {
      final foods = await LocalFoodDataSource().getAll();
      FoodRecognitionResult r(String name, String state) =>
          FoodRecognitionResult(
            items: [
              RecognitionCandidate(
                name: name,
                foodState: state,
                suggestedPortionGrams: 150,
              ),
            ],
          );
      const resolver = PhotoMealResolver();
      expect(
        resolver
            .resolve(r('Rice, white, cooked', 'cooked'), foods)[0]!
            .food
            .foodId,
        'usda_sr_168878',
      );
      expect(resolver.resolve(r('raw rice white', 'cooked'), foods), isEmpty);
      expect(resolver.resolve(r('sliced chicken', 'cooked'), foods), isEmpty);
      expect(resolver.resolve(r('boiled egg', 'cooked'), foods), isEmpty);
      expect(resolver.resolve(r('salad', 'prepared'), foods), isEmpty);
    },
  );
}
