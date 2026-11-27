import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../data/models/favorite_model.dart';

/// All reads/writes of `users/{uid}/favorites` for this feature. Existing
/// paths, ids and fields are unchanged; records of other types are never
/// modified.
abstract interface class FavoritesBackend {
  Future<List<FavoriteModel>> loadAll(String uid);

  /// Creates the favorite unless one with the same id exists (keeps the
  /// original createdAt). Throws on an id that belongs to another target.
  Future<void> saveIfAbsent(String uid, FavoriteModel model);

  /// Deletes only when the stored record has [expectedType].
  Future<void> remove(
    String uid,
    String favoriteId, {
    required String expectedType,
  });
}

class FirestoreFavoritesBackend implements FavoritesBackend {
  FirestoreFavoritesBackend(this.firestore, {required this.assertActive});
  final FirebaseFirestore firestore;
  final void Function(String uid) assertActive;

  @override
  Future<List<FavoriteModel>> loadAll(String uid) async {
    assertActive(uid);
    final snap = await firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.favorites)
        .get();
    assertActive(uid);
    return [for (final d in snap.docs) FavoriteModel.fromMap(d.id, d.data())];
  }

  @override
  Future<void> saveIfAbsent(String uid, FavoriteModel model) async {
    assertActive(uid);
    final ref = firestore.doc(
      FirestoreCollections.favoriteDocument(uid, model.favoriteId),
    );
    await firestore.runTransaction((t) async {
      assertActive(uid);
      final existing = await t.get(ref);
      assertActive(uid);
      if (existing.exists) {
        final old = FavoriteModel.fromMap(existing.id, existing.data()!);
        if (old.targetId != model.targetId ||
            old.targetType != model.targetType) {
          throw StateError('Favorite identity collision');
        }
        return;
      }
      t.set(ref, model.toMap());
    });
  }

  @override
  Future<void> remove(
    String uid,
    String favoriteId, {
    required String expectedType,
  }) async {
    assertActive(uid);
    final ref = firestore.doc(
      FirestoreCollections.favoriteDocument(uid, favoriteId),
    );
    await firestore.runTransaction((t) async {
      assertActive(uid);
      final existing = await t.get(ref);
      assertActive(uid);
      if (!existing.exists) return;
      if (existing.data()?['targetType'] != expectedType) {
        throw StateError('Favorite type mismatch');
      }
      t.delete(ref);
    });
  }
}
