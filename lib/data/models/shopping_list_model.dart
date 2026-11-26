import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListItemModel {
  const ShoppingListItemModel({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.isPurchased,
    this.linkedFoodId,
    this.productBarcode,
    this.productImageUrl,
    this.productBrand,
    this.productSourceUrl,
  });

  final String itemId;
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final bool isPurchased;
  final String? linkedFoodId;

  /// Exact selected pack identity, separate from generic catalog imagery.
  final String? productBarcode, productImageUrl, productBrand, productSourceUrl;

  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'category': category,
    'isPurchased': isPurchased,
    'linkedFoodId': linkedFoodId,
    'productBarcode': productBarcode,
    'productImageUrl': productImageUrl,
    'productBrand': productBrand,
    'productSourceUrl': productSourceUrl,
  };

  factory ShoppingListItemModel.fromMap(
    String itemId,
    Map<String, dynamic> map,
  ) => ShoppingListItemModel(
    itemId: itemId,
    name: map['name'] as String? ?? '',
    quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
    unit: map['unit'] as String? ?? '',
    category: map['category'] as String? ?? 'general',
    isPurchased: map['isPurchased'] as bool? ?? false,
    linkedFoodId: map['linkedFoodId'] as String?,
    productBarcode: map['productBarcode'] as String?,
    productImageUrl: map['productImageUrl'] as String?,
    productBrand: map['productBrand'] as String?,
    productSourceUrl: map['productSourceUrl'] as String?,
  );
}

class ShoppingListModel {
  const ShoppingListModel({
    required this.listId,
    required this.title,
    required this.planId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String listId;
  final String title;
  final String? planId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'planId': planId,
    'status': status,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': updatedAt != null
        ? Timestamp.fromDate(updatedAt!)
        : FieldValue.serverTimestamp(),
  };

  factory ShoppingListModel.fromMap(String listId, Map<String, dynamic> map) =>
      ShoppingListModel(
        listId: listId,
        title: map['title'] as String? ?? '',
        planId: map['planId'] as String?,
        status: map['status'] as String? ?? 'active',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}
