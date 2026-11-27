import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../data/models/favorite_model.dart';
import '../../domain/recipe_catalog_repository.dart';

abstract interface class RecipeFavoritesBackend {
  Future<List<FavoriteModel>> load(String uid);
  Future<void> save(String uid, FavoriteModel model);
  Future<void> remove(String uid, String favoriteId);
}

/// Transactions preserve the original creation timestamp on repeated saves.
class FirestoreRecipeFavoritesBackend implements RecipeFavoritesBackend {
  FirestoreRecipeFavoritesBackend(this.firestore, {required this.assertActive});
  final void Function(String uid) assertActive;
  final FirebaseFirestore firestore;
  @override
  Future<List<FavoriteModel>> load(String uid) async {
    assertActive(uid);
    final result = await firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.favorites)
        .where('targetType', isEqualTo: 'recipe')
        .get();
    assertActive(uid);
    return result.docs
        .map((d) => FavoriteModel.fromMap(d.id, d.data()))
        .toList(growable: false);
  }

  @override
  Future<void> save(String uid, FavoriteModel model) async {
    assertActive(uid);
    final ref = firestore.doc(
      FirestoreCollections.favoriteDocument(uid, model.favoriteId),
    );
    await firestore.runTransaction((transaction) async {
      assertActive(uid);
      final existing = await transaction.get(ref);
      assertActive(uid);
      if (existing.exists) {
        final old = FavoriteModel.fromMap(existing.id, existing.data()!);
        if (old.targetId != model.targetId || old.targetType != 'recipe') {
          throw StateError('Favorite identity collision');
        }
        return;
      }
      transaction.set(ref, model.toMap());
    });
  }

  @override
  Future<void> remove(String uid, String favoriteId) async {
    assertActive(uid);
    final ref = firestore.doc(
      FirestoreCollections.favoriteDocument(uid, favoriteId),
    );
    await firestore.runTransaction((transaction) async {
      assertActive(uid);
      final existing = await transaction.get(ref);
      assertActive(uid);
      if (!existing.exists) return;
      if (existing.data()?['targetType'] != 'recipe') {
        throw StateError('Favorite type mismatch');
      }
      transaction.delete(ref);
    });
  }
}

/// One instance per signed-in UID. Caches are never shared between accounts.
class CloudRecipeFavorites implements RecipeFavorites {
  CloudRecipeFavorites({
    required this.userId,
    required this.activeUserId,
    required this.backend,
    required this.catalog,
  }) {
    if (userId.trim().isEmpty) throw ArgumentError.value(userId, 'userId');
  }
  final String userId;
  final String? Function() activeUserId;
  final RecipeFavoritesBackend backend;
  final RecipeCatalogRepository catalog;
  Set<String> _saved = {};
  Map<String, List<String>> _documentIds = {};
  @override
  bool get isCloudBacked => true;
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _tail = Future.value();

  static String favoriteId(String recipeId) =>
      'recipe_${Uri.encodeComponent(recipeId)}';
  void _guard() {
    if (activeUserId() != userId) {
      _saved = {};
      _loaded = false;
      throw StateError('Favorite account is no longer active');
    }
  }

  @override
  Set<String> read() {
    _guard();
    return Set.unmodifiable(_saved);
  }

  @override
  Future<void> load() {
    _guard();
    if (_loaded) return Future.value();
    return _loading ??= _read().whenComplete(() => _loading = null);
  }

  @override
  Future<void> refresh() {
    final operation = _tail.catchError((Object _) {}).then((_) async {
      _guard();
      _loaded = false;
      await load();
    });
    _tail = operation;
    return operation;
  }

  Future<void> _read() async {
    final records = await backend.load(userId);
    _guard();
    _documentIds = {};
    for (final record in records.where((r) => r.targetType == 'recipe')) {
      _documentIds
          .putIfAbsent(record.targetId, () => [])
          .add(record.favoriteId);
    }
    _saved = records
        .where((r) => r.targetType == 'recipe')
        .map((r) => r.targetId)
        .where((id) => id.isNotEmpty)
        .toSet();
    _loaded = true;
  }

  @override
  Future<void> setSaved(String recipeId, bool saved) {
    // Serialize writes to avoid save/delete races from multiple feature screens.
    final operation = _tail.catchError((Object _) {}).then((_) async {
      _guard();
      await load();
      _guard();
      if (_saved.contains(recipeId) == saved) return;
      final id = favoriteId(recipeId);
      if (saved) {
        final recipe = await catalog.getById(recipeId);
        _guard();
        if (recipe == null) throw StateError('Unknown recipe favorite');
        await backend.save(
          userId,
          FavoriteModel(
            favoriteId: id,
            targetId: recipeId,
            targetType: 'recipe',
            title: recipe.nameAr ?? recipe.nameEn,
            imageUrl: recipe.imageUrl,
          ),
        );
      } else {
        for (final existingId in _documentIds[recipeId] ?? [id]) {
          _guard();
          await backend.remove(userId, existingId);
        }
      }
      _guard();
      if (saved) {
        _saved.add(recipeId);
        _documentIds[recipeId] = [id];
      } else {
        _saved.remove(recipeId);
        _documentIds.remove(recipeId);
      }
    });
    _tail = operation;
    return operation;
  }
}
