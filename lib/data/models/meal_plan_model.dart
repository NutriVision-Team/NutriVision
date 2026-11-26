import 'package:cloud_firestore/cloud_firestore.dart';

class MealPlanFoodPortion {
  const MealPlanFoodPortion({required this.foodId, required this.grams});
  final String foodId;
  final double grams;
  Map<String, dynamic> toMap() => {'foodId': foodId, 'grams': grams};
  factory MealPlanFoodPortion.fromMap(Map<String, dynamic> map) {
    final id = map['foodId'];
    final grams = map['grams'];
    if (id is! String ||
        id.trim().isEmpty ||
        id.contains('/') ||
        grams is! num ||
        !grams.isFinite ||
        grams <= 0 ||
        grams > 10000) {
      throw const FormatException('Invalid measured planned portion');
    }
    return MealPlanFoodPortion(foodId: id, grams: grams.toDouble());
  }
}

class MealPlanMealModel {
  const MealPlanMealModel({
    required this.mealId,
    required this.title,
    required this.mealType,
    required this.calories,
    required this.foods,
    this.dateKey,
    this.foodPortions,
  });

  final String mealId;
  final String title;
  final String mealType;
  final double calories;
  final List<String> foods;

  /// Legacy records without measurements remain unknown.
  final List<MealPlanFoodPortion>? foodPortions;
  final String? dateKey;

  Map<String, dynamic> toMap() => {
    'mealId': mealId,
    'title': title,
    'mealType': mealType,
    'calories': calories,
    'foods': foods,
    'dateKey': dateKey,
    'foodPortions': foodPortions?.map((e) => e.toMap()).toList(),
  };

  factory MealPlanMealModel.fromMap(Map<String, dynamic> map) =>
      MealPlanMealModel(
        mealId: map['mealId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        mealType: map['mealType'] as String? ?? 'breakfast',
        calories: (map['calories'] as num?)?.toDouble() ?? 0,
        foods: List<String>.from(map['foods'] ?? const []),
        dateKey: map['dateKey'] as String?,
        foodPortions: (map['foodPortions'] as List?)
            ?.map(
              (e) => MealPlanFoodPortion.fromMap(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
}

class MealPlanModel {
  const MealPlanModel({
    required this.planId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.dailyCalorieTarget,
    required this.meals,
    required this.generatedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String planId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double dailyCalorieTarget;
  final List<MealPlanMealModel> meals;
  final String generatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'status': status,
    'dailyCalorieTarget': dailyCalorieTarget,
    'meals': meals.map((meal) => meal.toMap()).toList(),
    'generatedBy': generatedBy,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': updatedAt != null
        ? Timestamp.fromDate(updatedAt!)
        : FieldValue.serverTimestamp(),
  };

  factory MealPlanModel.fromMap(
    String planId,
    Map<String, dynamic> map,
  ) => MealPlanModel(
    planId: planId,
    title: map['title'] as String? ?? '',
    startDate: (map['startDate'] as Timestamp).toDate(),
    endDate: (map['endDate'] as Timestamp).toDate(),
    status: map['status'] as String? ?? 'draft',
    dailyCalorieTarget: (map['dailyCalorieTarget'] as num?)?.toDouble() ?? 0,
    meals: List<MealPlanMealModel>.from(
      (map['meals'] as List? ?? const []).map(
        (item) =>
            MealPlanMealModel.fromMap(Map<String, dynamic>.from(item as Map)),
      ),
    ),
    generatedBy: map['generatedBy'] as String? ?? 'manual',
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
  );
}
