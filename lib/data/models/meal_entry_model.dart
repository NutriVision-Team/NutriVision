import '../../core/utils/nutrition_values.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealItemModel {
  const MealItemModel({
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.weightInGrams,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.dataSource,
    required this.confidence,
  });

  final String foodId;
  final String foodName;
  final double quantity;
  final String unit;
  final double weightInGrams;
  final double calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final String dataSource;
  final double? confidence;

  Map<String, dynamic> toMap() => {
    'foodId': foodId,
    'foodName': foodName,
    'quantity': quantity,
    'unit': unit,
    'weightInGrams': weightInGrams,
    'calories': calories,
    'protein': protein,
    'carbohydrates': carbohydrates,
    'fat': fat,
    'fiber': fiber,
    'sugar': sugar,
    'sodium': sodium,
    'dataSource': dataSource,
    'confidence': confidence,
  };

  factory MealItemModel.fromMap(Map<String, dynamic> map) => MealItemModel(
    foodId: map['foodId'] as String? ?? '',
    foodName: map['foodName'] as String? ?? '',
    quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
    unit: map['unit'] as String? ?? '',
    weightInGrams: (map['weightInGrams'] as num?)?.toDouble() ?? 0,
    calories: requiredEnergy(map['calories']),
    protein: knownNutrient(map['protein']),
    carbohydrates: knownNutrient(map['carbohydrates']),
    fat: knownNutrient(map['fat']),
    fiber: knownNutrient(map['fiber']),
    sugar: knownNutrient(map['sugar']),
    sodium: knownNutrient(map['sodium']),
    dataSource: map['dataSource'] as String? ?? 'manual',
    confidence: (map['confidence'] as num?)?.toDouble(),
  );
}

class MealEntryModel {
  const MealEntryModel({
    required this.mealId,
    required this.userId,
    required this.dateKey,
    required this.consumedAt,
    required this.mealType,
    required this.inputMethod,
    required this.title,
    this.imageUrl,
    required this.items,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.totalSugar,
    required this.totalSodium,
    required this.analysisStatus,
    this.confidence,
    this.estimatedRange,
    this.nutritionSource,
    this.aiAnalysisId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String mealId;
  final String userId;
  final String dateKey;
  final DateTime consumedAt;
  final String mealType;
  final String inputMethod;
  final String title;
  final String? imageUrl;
  final List<MealItemModel> items;
  final double totalCalories;
  final double? totalProtein;
  final double? totalCarbs;
  final double? totalFat;
  final double? totalFiber;
  final double? totalSugar;
  final double? totalSodium;
  final String analysisStatus;
  final double? confidence;
  final String? estimatedRange;
  final String? nutritionSource;
  final String? aiAnalysisId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'dateKey': dateKey,
    'consumedAt': Timestamp.fromDate(consumedAt),
    'mealType': mealType,
    'inputMethod': inputMethod,
    'title': title,
    'imageUrl': imageUrl,
    'items': items.map((item) => item.toMap()).toList(),
    'totalCalories': totalCalories,
    'totalProtein': totalProtein,
    'totalCarbs': totalCarbs,
    'totalFat': totalFat,
    'totalFiber': totalFiber,
    'totalSugar': totalSugar,
    'totalSodium': totalSodium,
    'analysisStatus': analysisStatus,
    'confidence': confidence,
    'estimatedRange': estimatedRange,
    'nutritionSource': nutritionSource,
    'aiAnalysisId': aiAnalysisId,
    'notes': notes,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': updatedAt != null
        ? Timestamp.fromDate(updatedAt!)
        : FieldValue.serverTimestamp(),
  };

  factory MealEntryModel.fromMap(String mealId, Map<String, dynamic> map) =>
      MealEntryModel(
        mealId: mealId,
        userId: map['userId'] as String? ?? '',
        dateKey: map['dateKey'] as String? ?? '',
        consumedAt: (map['consumedAt'] as Timestamp).toDate(),
        mealType: map['mealType'] as String? ?? 'breakfast',
        inputMethod: map['inputMethod'] as String? ?? 'manual',
        title: map['title'] as String? ?? '',
        imageUrl: map['imageUrl'] as String?,
        items: List<MealItemModel>.from(
          (map['items'] as List? ?? const []).map(
            (item) =>
                MealItemModel.fromMap(Map<String, dynamic>.from(item as Map)),
          ),
        ),
        totalCalories: requiredEnergy(map['totalCalories']),
        totalProtein: knownNutrient(map['totalProtein']),
        totalCarbs: knownNutrient(map['totalCarbs']),
        totalFat: knownNutrient(map['totalFat']),
        totalFiber: knownNutrient(map['totalFiber']),
        totalSugar: knownNutrient(map['totalSugar']),
        totalSodium: knownNutrient(map['totalSodium']),
        analysisStatus: map['analysisStatus'] as String? ?? 'pending',
        confidence: (map['confidence'] as num?)?.toDouble(),
        estimatedRange: map['estimatedRange'] as String?,
        nutritionSource: map['nutritionSource'] as String?,
        aiAnalysisId: map['aiAnalysisId'] as String?,
        notes: map['notes'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}
