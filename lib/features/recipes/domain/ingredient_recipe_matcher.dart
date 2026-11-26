import '../data/datasources/local_recipe_data_source.dart';
import 'recipe_catalog_repository.dart';

class IngredientRecipeMatch {
  const IngredientRecipeMatch({
    required this.recipe,
    required this.matchedInputs,
  });
  final LocalRecipeRecord recipe;
  final List<String> matchedInputs;
}

/// Deterministic lexical matching only. This never asserts pantry completeness,
/// nutrition, cooking time, allergy safety, or model-generated inference.
abstract final class IngredientRecipeMatcher {
  static String normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[إأآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll(RegExp(r'[^a-z0-9\u0621-\u064A ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // Search aliases, not replacements for the provider's ingredient names.
  static const _aliases = <String, List<String>>{
    'chicken': ['chicken', 'فراخ', 'دجاج'],
    'rice': ['rice', 'ارز', 'رز'],
    'tomato': ['tomato', 'tomatoes', 'طماطم'],
    'onion': ['onion', 'onions', 'بصل'],
    'garlic': ['garlic', 'ثوم', 'توم'],
    'egg': ['egg', 'eggs', 'بيض'],
    'bean': ['broad beans', 'fava beans', 'فول'],
    'lentil': ['lentil', 'lentils', 'عدس'],
    'chickpea': ['chickpea', 'chickpeas', 'حمص'],
    'oil': ['oil', 'زيت'],
    'lemon': ['lemon', 'lemons', 'ليمون'],
    'courgette': ['courgette', 'zucchini', 'كوسة'],
    'parsley': ['parsley', 'بقدونس'],
    'cumin': ['cumin', 'كمون'],
    'macaroni': ['macaroni', 'pasta', 'مكرونة', 'معكرونة'],
  };
  static Set<String> _terms(String input) {
    final value = normalize(input);
    final terms = <String>{value};
    for (final aliases in _aliases.values) {
      if (aliases.map(normalize).contains(value)) {
        terms.addAll(aliases.map(normalize));
      }
    }
    return terms.where((s) => s.isNotEmpty).toSet();
  }

  static bool _contains(String haystack, String needle) {
    if (needle.isEmpty) return false;
    return ' ${normalize(haystack)} '.contains(' $needle ');
  }

  static List<IngredientRecipeMatch> match(
    List<LocalRecipeRecord> recipes,
    RecipeRequest request,
  ) {
    final inputs = request.ingredients
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    final result = <IngredientRecipeMatch>[];
    for (final recipe in recipes) {
      if (request.requireMealType &&
          !recipe.mealTypes.contains(request.mealType)) {
        continue;
      }
      final kcal = recipe.caloriesPerServing, time = recipe.cookingMinutes;
      if (request.maxCalories != null &&
          (kcal == null ||
              !kcal.isFinite ||
              kcal <= 0 ||
              kcal > request.maxCalories!)) {
        continue;
      }
      if (request.maxCookingMinutes != null &&
          (time == null ||
              !time.isFinite ||
              time <= 0 ||
              time > request.maxCookingMinutes!)) {
        continue;
      }
      final matched = inputs
          .where(
            (input) => _terms(input).any(
              (term) => recipe.ingredients.any(
                (ingredient) => _contains(ingredient.name, term),
              ),
            ),
          )
          .toList();
      if (matched.isNotEmpty ||
          (inputs.isEmpty &&
              (request.requireMealType ||
                  request.maxCalories != null ||
                  request.maxCookingMinutes != null))) {
        result.add(
          IngredientRecipeMatch(
            recipe: recipe,
            matchedInputs: List.unmodifiable(matched),
          ),
        );
      }
    }
    result.sort((a, b) {
      final score = b.matchedInputs.length.compareTo(a.matchedInputs.length);
      // Stable tie-break, never invented meal suitability.
      return score != 0 ? score : a.recipe.id.compareTo(b.recipe.id);
    });
    return List.unmodifiable(result);
  }
}
