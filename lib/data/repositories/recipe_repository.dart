import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';

class RecipeModel {
  const RecipeModel({
    required this.recipeId,
    required this.title,
    this.localizedTitles,
    this.description,
    this.imageUrl,
    this.ingredients,
    this.instructions,
    this.preparationTime,
    this.servings,
    this.nutritionPerServing,
    this.category,
    this.tags,
    this.isPublished = false,
    this.createdAt,
    this.updatedAt,
  });

  final String recipeId;
  final String title;
  final Map<String, dynamic>? localizedTitles;
  final String? description;
  final String? imageUrl;
  final List<String>? ingredients;
  final List<String>? instructions;
  final int? preparationTime;
  final int? servings;
  final Map<String, dynamic>? nutritionPerServing;
  final String? category;
  final List<String>? tags;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'localizedTitles': localizedTitles ?? const <String, dynamic>{},
    'description': description,
    'imageUrl': imageUrl,
    'ingredients': ingredients ?? const <String>[],
    'instructions': instructions ?? const <String>[],
    'preparationTime': preparationTime,
    'servings': servings,
    'nutritionPerServing': nutritionPerServing ?? const <String, dynamic>{},
    'category': category,
    'tags': tags ?? const <String>[],
    'isPublished': isPublished,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': updatedAt != null
        ? Timestamp.fromDate(updatedAt!)
        : FieldValue.serverTimestamp(),
  };

  factory RecipeModel.fromMap(String recipeId, Map<String, dynamic> map) =>
      RecipeModel(
        recipeId: recipeId,
        title: map['title'] as String? ?? '',
        localizedTitles: map['localizedTitles'] as Map<String, dynamic>?,
        description: map['description'] as String?,
        imageUrl: map['imageUrl'] as String?,
        ingredients: List<String>.from(map['ingredients'] ?? const []),
        instructions: List<String>.from(map['instructions'] ?? const []),
        preparationTime: map['preparationTime'] as int?,
        servings: map['servings'] as int?,
        nutritionPerServing:
            map['nutritionPerServing'] as Map<String, dynamic>?,
        category: map['category'] as String?,
        tags: List<String>.from(map['tags'] ?? const []),
        isPublished: map['isPublished'] as bool? ?? false,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}

abstract class RecipeRepository {
  Future<List<RecipeModel>> getPublishedRecipes();
}

class FirestoreRecipeRepository implements RecipeRepository {
  FirestoreRecipeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<RecipeModel>> getPublishedRecipes() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.recipes)
        .where('isPublished', isEqualTo: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => RecipeModel.fromMap(doc.id, doc.data()))
        .toList();
  }
}
