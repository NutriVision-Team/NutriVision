import '../../../data/models/food_catalog_model.dart';
import '../../../data/repositories/food_repository.dart';
import 'datasources/local_food_data_source.dart';

/// Keeps bundled-source parsing outside widgets and legacy Firestore models.
/// Nutrient keys are mapped once here, without replacing nulls with zeros.
class LocalFoodRepository implements FoodRepository, FoodCategoryBrowser {
  LocalFoodRepository({LocalFoodDataSource? source})
    : _source = source ?? LocalFoodDataSource();
  final LocalFoodDataSource _source;

  FoodCatalogModel _map(LocalFoodRecord record) => FoodCatalogModel(
    foodId: record.id,
    name: record.nameAr.isNotEmpty ? record.nameAr : record.nameEn,
    localizedNames: {'ar': record.nameAr, 'en': record.nameEn},
    category: record.category,
    foodState: record.foodState,
    sourceUrl: record.source.url,
    servingSizes: {'referenceAmountGrams': record.referenceAmountGrams},
    nutritionPer100g: {
      'calories': record.nutrientsPer100g.energyKcal,
      'protein': record.nutrientsPer100g.proteinG,
      'carbohydrates': record.nutrientsPer100g.carbohydrateG,
      'fat': record.nutrientsPer100g.fatG,
      'fiber': record.nutrientsPer100g.fiberG,
      'sugar': record.nutrientsPer100g.sugarsG,
      'sodium': record.nutrientsPer100g.sodiumMg,
    },
    source: '${record.source.provider}, ${record.source.sourceVersion}',
    sourceId: record.source.fdcId.toString(),
    verificationStatus: record.dataQuality,
  );

  @override
  Future<List<FoodCatalogModel>> browseFoods({
    String? category,
    bool egyptianStaples = false,
  }) async {
    final records = await _source.getAll();
    const stapleTerms = [
      'فول',
      'عدس',
      'أرز',
      'ارز',
      'عيش',
      'خبز',
      'بيض',
      'طماطم',
      'بصل',
      'باذنجان',
      'ملوخية',
      'حمص',
      'بامية',
    ];
    return records
        .where(
          (f) =>
              (category == null || f.category == category) &&
              (!egyptianStaples ||
                  stapleTerms.any(
                    (s) =>
                        f.nameAr.contains(s) ||
                        f.aliases.any((a) => a.contains(s)),
                  )),
        )
        .map(_map)
        .toList(growable: false);
  }

  @override
  Future<List<FoodCatalogModel>> searchFood(String query) async =>
      (await _source.search(query)).map(_map).toList(growable: false);

  @override
  Future<FoodCatalogModel?> getFoodById(String foodId) async {
    final record = await _source.getById(foodId);
    return record == null ? null : _map(record);
  }
}
