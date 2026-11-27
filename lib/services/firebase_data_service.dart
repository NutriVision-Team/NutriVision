import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firestore_collections.dart';
import '../data/repositories/food_repository.dart';
import '../data/repositories/nutrition_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/user_repository.dart';

class FirebaseDataService {
  FirebaseDataService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreUserRepository get userRepository =>
      FirestoreUserRepository(_firestore, _auth);

  FirestoreNutritionRepository get nutritionRepository =>
      FirestoreNutritionRepository(_firestore);

  FirestoreFoodRepository get foodRepository =>
      FirestoreFoodRepository(_firestore);

  FirestoreProductRepository get productRepository =>
      FirestoreProductRepository(_firestore);

  FirestoreRecipeRepository get recipeRepository =>
      FirestoreRecipeRepository(_firestore);

  Future<void> saveDeviceToken({
    required String uid,
    required String deviceId,
    required String fcmToken,
    required String platform,
    required String deviceName,
    required String language,
  }) async {
    final deviceRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.devices)
        .doc(deviceId);

    await deviceRef.set({
      'fcmToken': fcmToken,
      'platform': platform,
      'deviceName': deviceName,
      'language': language,
      'isActive': true,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
