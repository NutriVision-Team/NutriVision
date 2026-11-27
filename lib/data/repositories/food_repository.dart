import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../models/food_catalog_model.dart';

abstract class FoodRepository {
  Future<List<FoodCatalogModel>> searchFood(String query);
  Future<FoodCatalogModel?> getFoodById(String foodId);
}

class FirestoreFoodRepository implements FoodRepository {
  FirestoreFoodRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<FoodCatalogModel>> searchFood(String query) async {
    if (query.trim().isEmpty) {
      return const <FoodCatalogModel>[];
    }

    final snapshot = await _firestore
        .collection(FirestoreCollections.foodCatalog)
        .where('name', isGreaterThanOrEqualTo: query.trim())
        .where('name', isLessThanOrEqualTo: '${query.trim()}\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => FoodCatalogModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<FoodCatalogModel?> getFoodById(String foodId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.foodCatalog)
        .doc(foodId)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return FoodCatalogModel.fromMap(snapshot.id, snapshot.data()!);
  }
}

/// Optional offline category browsing without changing legacy cloud search.
abstract interface class FoodCategoryBrowser {
  Future<List<FoodCatalogModel>> browseFoods({
    String? category,
    bool egyptianStaples = false,
  });
}
