import '../../../core/utils/date_utils.dart';
import '../../../core/utils/nutrition_values.dart';
import '../../../data/models/meal_entry_model.dart';

/// Rescales the same stored ingredients. It does not switch raw/cooked foods,
/// invent missing nutrients, or use AI. Unknown quantities cannot be rescaled.
MealEntryModel editLoggedMeal(
  MealEntryModel original, {
  required String title,
  required String mealType,
  required String? notes,
  List<double>? weightsInGrams,
  DateTime? consumedAt,
  DateTime? updatedAt,
}) {
  if (title.trim().isEmpty ||
      title.trim().length > 120 ||
      notes != null && notes.length > 1000) {
    throw ArgumentError('Invalid meal text');
  }
  if (!const [
    'breakfast',
    'lunch',
    'dinner',
    'snack',
    'suhoor',
    'iftar',
  ].contains(mealType)) {
    throw ArgumentError('Invalid meal type');
  }
  if (weightsInGrams != null &&
      weightsInGrams.length != original.items.length) {
    throw ArgumentError('Ingredient count mismatch');
  }
  final items = <MealItemModel>[];
  for (var i = 0; i < original.items.length; i++) {
    final item = original.items[i];
    final weight = weightsInGrams?[i] ?? item.weightInGrams;
    if (!weight.isFinite ||
        weight <= 0 ||
        weight > 10000 ||
        !item.weightInGrams.isFinite ||
        item.weightInGrams <= 0) {
      throw ArgumentError('Invalid ingredient weight');
    }
    final ratio = weight / item.weightInGrams;
    items.add(
      MealItemModel(
        foodId: item.foodId,
        foodName: item.foodName,
        quantity: item.quantity * ratio,
        unit: item.unit,
        weightInGrams: weight,
        calories: item.calories * ratio,
        protein: item.protein == null ? null : item.protein! * ratio,
        carbohydrates: item.carbohydrates == null
            ? null
            : item.carbohydrates! * ratio,
        fat: item.fat == null ? null : item.fat! * ratio,
        fiber: item.fiber == null ? null : item.fiber! * ratio,
        sugar: item.sugar == null ? null : item.sugar! * ratio,
        sodium: item.sodium == null ? null : item.sodium! * ratio,
        dataSource: item.dataSource,
        confidence: item.confidence,
      ),
    );
  }
  final totals = items.isEmpty
      ? null
      : <String, double?>{
          'calories': items.fold<double>(0, (sum, item) => sum + item.calories),
          'protein': sumKnownNutrients(items.map((i) => i.protein)),
          'carbs': sumKnownNutrients(items.map((i) => i.carbohydrates)),
          'fat': sumKnownNutrients(items.map((i) => i.fat)),
          'fiber': sumKnownNutrients(items.map((i) => i.fiber)),
          'sugar': sumKnownNutrients(items.map((i) => i.sugar)),
          'sodium': sumKnownNutrients(items.map((i) => i.sodium)),
        };
  final at = consumedAt ?? original.consumedAt;
  return MealEntryModel(
    mealId: original.mealId,
    userId: original.userId,
    dateKey: SufraDateUtils.toDateKey(at),
    consumedAt: at,
    mealType: mealType,
    inputMethod: original.inputMethod,
    title: title.trim(),
    imageUrl: original.imageUrl,
    items: List.unmodifiable(items),
    totalCalories: totals?['calories'] ?? original.totalCalories,
    totalProtein: totals == null ? original.totalProtein : totals['protein'],
    totalCarbs: totals == null ? original.totalCarbs : totals['carbs'],
    totalFat: totals == null ? original.totalFat : totals['fat'],
    totalFiber: totals == null ? original.totalFiber : totals['fiber'],
    totalSugar: totals == null ? original.totalSugar : totals['sugar'],
    totalSodium: totals == null ? original.totalSodium : totals['sodium'],
    analysisStatus: original.analysisStatus,
    confidence: original.confidence,
    estimatedRange: original.estimatedRange,
    nutritionSource: original.nutritionSource,
    aiAnalysisId: original.aiAnalysisId,
    notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    createdAt: original.createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );
}
