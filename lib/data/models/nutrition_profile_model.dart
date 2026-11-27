import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionProfileModel {
  const NutritionProfileModel({
    required this.profileId,
    required this.gender,
    required this.dateOfBirth,
    required this.heightCm,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.nutritionGoal,
    required this.dailyCalorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    this.dietaryPreferences = const [],
    this.allergies = const [],
    this.healthRestrictions = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String profileId;
  final String gender;
  final DateTime dateOfBirth;
  final double heightCm;
  final double currentWeightKg;
  final double targetWeightKg;
  final String activityLevel;
  final String nutritionGoal;
  final double dailyCalorieTarget;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;
  final List<String> dietaryPreferences;
  final List<String> allergies;
  final List<String> healthRestrictions;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'heightCm': heightCm,
      'currentWeightKg': currentWeightKg,
      'targetWeightKg': targetWeightKg,
      'activityLevel': activityLevel,
      'nutritionGoal': nutritionGoal,
      'dailyCalorieTarget': dailyCalorieTarget,
      'proteinTarget': proteinTarget,
      'carbsTarget': carbsTarget,
      'fatTarget': fatTarget,
      'dietaryPreferences': dietaryPreferences,
      'allergies': allergies,
      'healthRestrictions': healthRestrictions,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory NutritionProfileModel.fromMap(
    String profileId,
    Map<String, dynamic> map,
  ) {
    return NutritionProfileModel(
      profileId: profileId,
      gender: map['gender'] as String? ?? 'not_specified',
      dateOfBirth: (map['dateOfBirth'] as Timestamp).toDate(),
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 0,
      currentWeightKg: (map['currentWeightKg'] as num?)?.toDouble() ?? 0,
      targetWeightKg: (map['targetWeightKg'] as num?)?.toDouble() ?? 0,
      activityLevel: map['activityLevel'] as String? ?? 'moderate',
      nutritionGoal: map['nutritionGoal'] as String? ?? 'maintain',
      dailyCalorieTarget: (map['dailyCalorieTarget'] as num?)?.toDouble() ?? 0,
      proteinTarget: (map['proteinTarget'] as num?)?.toDouble() ?? 0,
      carbsTarget: (map['carbsTarget'] as num?)?.toDouble() ?? 0,
      fatTarget: (map['fatTarget'] as num?)?.toDouble() ?? 0,
      dietaryPreferences: List<String>.from(
        map['dietaryPreferences'] ?? const [],
      ),
      allergies: List<String>.from(map['allergies'] ?? const []),
      healthRestrictions: List<String>.from(
        map['healthRestrictions'] ?? const [],
      ),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
