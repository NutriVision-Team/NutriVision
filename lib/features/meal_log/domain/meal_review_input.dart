import 'catalog_meal_draft.dart';

/// Metadata captured before review. Nothing is saved until the user confirms.
class MealReviewInput {
  MealReviewInput({
    required this.draft,
    this.mealType = 'lunch',
    this.notes = '',
    this.title,
    this.inputMethod = 'catalog',
  }) {
    if (!const {'breakfast', 'lunch', 'dinner', 'snack'}.contains(mealType)) {
      throw ArgumentError.value(mealType, 'mealType');
    }
  }
  final CatalogMealDraft draft;
  final String mealType, notes;
  final String? title;
  final String inputMethod;
}
