import '../../data/models/food_catalog_model.dart';
import '../../data/repositories/food_repository.dart';

/// Local catalog search, not an AI parser. Spoken counts/plate sizes are never
/// converted to grams. The user must select foods and confirm their portions.
class VoiceFoodSuggestions {
  const VoiceFoodSuggestions(this.repository);
  final FoodRepository repository;
  static const _stop = {
    'اكلت',
    'أكلت',
    'انا',
    'أنا',
    'مع',
    'من',
    'و',
    'طبق',
    'طبقين',
    'كوب',
    'كوباية',
    'جم',
    'جرام',
    'شوية',
    'النهارده',
    'a',
    'the',
    'of',
    'and',
    'i',
    'ate',
    'plate',
    'plates',
    'grams',
    'with',
  };
  Future<List<FoodCatalogModel>> find(String description) async {
    final text = description.trim();
    final words = text
        .split(RegExp(r'[\s،,.;:!?؟]+'))
        .where(
          (w) =>
              w.length > 1 &&
              !_stop.contains(w.toLowerCase()) &&
              !RegExp(r'^[0-9٠-٩۰-۹]+$').hasMatch(w),
        );
    final queries = <String>{
      if (text.isNotEmpty && text.length <= 120) text,
      ...words.where((w) => w.length <= 80).take(10),
    };
    if (queries.isEmpty) return const [];
    final results = await Future.wait(queries.map(repository.searchFood));
    final foods = <String, FoodCatalogModel>{};
    for (final list in results) {
      for (final food in list) {
        foods.putIfAbsent(food.foodId, () => food);
      }
    }
    return List.unmodifiable(foods.values.take(30));
  }
}
