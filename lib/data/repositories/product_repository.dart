import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';

class ProductModel {
  const ProductModel({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.ingredients,
    this.allergens,
    this.nutritionPer100g,
    this.nutritionGrade,
    this.source,
    this.updatedAt,
  });

  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final List<String>? ingredients;
  final List<String>? allergens;
  final Map<String, dynamic>? nutritionPer100g;
  final String? nutritionGrade;
  final String? source;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'barcode': barcode,
    'name': name,
    'brand': brand,
    'imageUrl': imageUrl,
    'ingredients': ingredients ?? const <String>[],
    'allergens': allergens ?? const <String>[],
    'nutritionPer100g': nutritionPer100g ?? const <String, dynamic>{},
    'nutritionGrade': nutritionGrade,
    'source': source,
    'updatedAt': updatedAt != null
        ? Timestamp.fromDate(updatedAt!)
        : FieldValue.serverTimestamp(),
  };

  factory ProductModel.fromMap(String barcode, Map<String, dynamic> map) =>
      ProductModel(
        barcode: barcode,
        name: map['name'] as String? ?? '',
        brand: map['brand'] as String?,
        imageUrl: map['imageUrl'] as String?,
        ingredients: List<String>.from(map['ingredients'] ?? const []),
        allergens: List<String>.from(map['allergens'] ?? const []),
        nutritionPer100g: map['nutritionPer100g'] as Map<String, dynamic>?,
        nutritionGrade: map['nutritionGrade'] as String?,
        source: map['source'] as String?,
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}

abstract class ProductRepository {
  Future<ProductModel?> lookupBarcode(String barcode);
}

class FirestoreProductRepository implements ProductRepository {
  FirestoreProductRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<ProductModel?> lookupBarcode(String barcode) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.products)
        .doc(barcode)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return ProductModel.fromMap(snapshot.id, snapshot.data()!);
  }
}
