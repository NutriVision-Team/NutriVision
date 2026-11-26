import '../../core/utils/nutrition_values.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLogModel {
  const DailyLogModel({
    required this.dateKey,
    required this.timezone,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.totalSugar,
    required this.totalSodium,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    required this.waterIntakeMl,
    required this.mealCount,
    this.updatedAt,
  });

  final String dateKey;
  final String timezone;
  final double? totalCalories;
  final double? totalProtein;
  final double? totalCarbs;
  final double? totalFat;
  final double? totalFiber;
  final double? totalSugar;
  final double? totalSodium;
  final double calorieTarget;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;
  final double waterIntakeMl;
  final int mealCount;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'dateKey': dateKey,
    'timezone': timezone,
    'totalCalories': totalCalories,
    'totalProtein': totalProtein,
    'totalCarbs': totalCarbs,
    'totalFat': totalFat,
    'totalFiber': totalFiber,
    'totalSugar': totalSugar,
    'totalSodium': totalSodium,
    'calorieTarget': calorieTarget,
    'proteinTarget': proteinTarget,
    'carbsTarget': carbsTarget,
    'fatTarget': fatTarget,
    'waterIntakeMl': waterIntakeMl,
    'mealCount': mealCount,
    'updatedAt': updatedAt != null
        ? Timestamp.fromDate(updatedAt!)
        : FieldValue.serverTimestamp(),
  };

  factory DailyLogModel.fromMap(Map<String, dynamic> map) => DailyLogModel(
    dateKey: map['dateKey'] as String? ?? '',
    timezone: map['timezone'] as String? ?? 'UTC',
    totalCalories: knownNutrient(map['totalCalories']),
    totalProtein: knownNutrient(map['totalProtein']),
    totalCarbs: knownNutrient(map['totalCarbs']),
    totalFat: knownNutrient(map['totalFat']),
    totalFiber: knownNutrient(map['totalFiber']),
    totalSugar: knownNutrient(map['totalSugar']),
    totalSodium: knownNutrient(map['totalSodium']),
    calorieTarget: (map['calorieTarget'] as num?)?.toDouble() ?? 0,
    proteinTarget: (map['proteinTarget'] as num?)?.toDouble() ?? 0,
    carbsTarget: (map['carbsTarget'] as num?)?.toDouble() ?? 0,
    fatTarget: (map['fatTarget'] as num?)?.toDouble() ?? 0,
    waterIntakeMl: (map['waterIntakeMl'] as num?)?.toDouble() ?? 0,
    mealCount: (map['mealCount'] as num?)?.toInt() ?? 0,
    updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
  );
}
