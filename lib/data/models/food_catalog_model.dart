import 'package:cloud_firestore/cloud_firestore.dart';

class FoodCatalogModel {
  const FoodCatalogModel({
    required this.foodId,
    required this.name,
    this.localizedNames,
    this.category,
    this.foodState,
    this.sourceUrl,
    this.servingSizes,
    this.nutritionPer100g,
    this.source,
    this.sourceId,
    this.verificationStatus,
    this.createdAt,
    this.updatedAt,
  });

  final String foodId;
  final String name;
  final Map<String, dynamic>? localizedNames;
  final String? category;
  final String? foodState;
  final String? sourceUrl;
  final Map<String, dynamic>? servingSizes;
  final Map<String, dynamic>? nutritionPer100g;
  final String? source;
  final String? sourceId;
  final String? verificationStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'name': name,
    'localizedNames': localizedNames ?? const <String, dynamic>{},
    'category': category,
    'foodState': foodState,
    'sourceUrl': sourceUrl,
    'servingSizes': servingSizes ?? const <String, dynamic>{},
    'nutritionPer100g': nutritionPer100g ?? const <String, dynamic>{},
    'source': source,
    'sourceId': sourceId,
    'verificationStatus': verificationStatus,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': updatedAt != null
        ? Timestamp.fromDate(updatedAt!)
        : FieldValue.serverTimestamp(),
  };

  factory FoodCatalogModel.fromMap(String foodId, Map<String, dynamic> map) =>
      FoodCatalogModel(
        foodId: foodId,
        name: map['name'] as String? ?? '',
        localizedNames: map['localizedNames'] as Map<String, dynamic>?,
        category: map['category'] as String?,
        foodState: map['foodState'] as String?,
        sourceUrl: map['sourceUrl'] as String?,
        servingSizes: map['servingSizes'] as Map<String, dynamic>?,
        nutritionPer100g: map['nutritionPer100g'] as Map<String, dynamic>?,
        source: map['source'] as String?,
        sourceId: map['sourceId'] as String?,
        verificationStatus: map['verificationStatus'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}
