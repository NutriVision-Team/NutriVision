import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../data/models/shopping_list_model.dart';

/// Persistence boundary for the shopping list. One current list per user,
/// stored at the existing `users/{uid}/shopping_lists/{listId}` path with
/// items in its `items` subcollection using the existing item model.
abstract class ShoppingRepository {
  Future<ShoppingListModel?> getList(String uid, String listId);
  Future<List<ShoppingListItemModel>> getItems(String uid, String listId);
  Future<ShoppingListModel> saveList(String uid, ShoppingListModel list);
  Future<void> upsertItem(
    String uid,
    String listId,
    ShoppingListItemModel item,
  );
  Future<void> removeItem(String uid, String listId, String itemId);
  Future<void> setPurchased(
    String uid,
    String listId,
    String itemId,
    bool purchased,
  );

  /// Replaces generated items while preserving the purchased state of items
  /// that stay in the list (stable ids make this a merge, not a wipe).
  Future<void> replaceGeneratedItems(
    String uid,
    String listId,
    List<ShoppingListItemModel> items,
  );
}

class FirestoreShoppingRepository implements ShoppingRepository {
  FirestoreShoppingRepository(this._firestore, {this.assertActive});
  final void Function(String uid)? assertActive;

  final FirebaseFirestore _firestore;

  /// The single list the app maintains for the user.
  static const currentListId = 'current';

  DocumentReference<Map<String, dynamic>> _list(String uid, String listId) {
    assertActive?.call(uid);
    if (uid.isEmpty ||
        uid.contains('/') ||
        listId.isEmpty ||
        listId.contains('/')) {
      throw ArgumentError('A valid owner and list id are required');
    }
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.shoppingLists)
        .doc(listId);
  }

  CollectionReference<Map<String, dynamic>> _items(String uid, String listId) =>
      _list(uid, listId).collection('items');

  @override
  Future<ShoppingListModel?> getList(String uid, String listId) async {
    final snapshot = await _list(uid, listId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return ShoppingListModel.fromMap(snapshot.id, snapshot.data()!);
  }

  @override
  Future<List<ShoppingListItemModel>> getItems(
    String uid,
    String listId,
  ) async {
    final snapshot = await _items(uid, listId).get();
    return snapshot.docs
        .map((doc) => ShoppingListItemModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<ShoppingListModel> saveList(String uid, ShoppingListModel list) async {
    final ref = _list(uid, list.listId);
    final payload = list.toMap();
    final existing = await ref.get();
    final createdAt = existing.data()?['createdAt'];
    if (createdAt != null) {
      payload['createdAt'] = createdAt;
    }
    payload['updatedAt'] = FieldValue.serverTimestamp();
    assertActive?.call(uid);
    await ref.set(payload, SetOptions(merge: true));
    return list;
  }

  @override
  Future<void> upsertItem(
    String uid,
    String listId,
    ShoppingListItemModel item,
  ) async {
    if (item.itemId.isEmpty ||
        item.name.trim().isEmpty ||
        !item.quantity.isFinite ||
        item.quantity <= 0) {
      throw ArgumentError.value(item.itemId, 'item.itemId');
    }
    await _items(
      uid,
      listId,
    ).doc(item.itemId).set(item.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> removeItem(String uid, String listId, String itemId) =>
      _items(uid, listId).doc(itemId).delete();

  @override
  Future<void> setPurchased(
    String uid,
    String listId,
    String itemId,
    bool purchased,
  ) async {
    await _items(
      uid,
      listId,
    ).doc(itemId).set({'isPurchased': purchased}, SetOptions(merge: true));
  }

  @override
  Future<void> replaceGeneratedItems(
    String uid,
    String listId,
    List<ShoppingListItemModel> items,
  ) async {
    final collection = _items(uid, listId);
    final existing = await collection.get();
    final keepPurchased = <String, bool>{
      for (final doc in existing.docs)
        if ((doc.data()['linkedFoodId'] as String?) != null)
          doc.id: doc.data()['isPurchased'] as bool? ?? false,
    };
    final batch = _firestore.batch();
    if (items.length + existing.docs.length > 450) {
      throw StateError('Shopping list too large');
    }
    final newIds = items.map((i) => i.itemId).toSet();
    // Remove previously generated food items that are no longer planned;
    // manual items (no linkedFoodId) are never touched by regeneration.
    for (final doc in existing.docs) {
      final generated = (doc.data()['linkedFoodId'] as String?) != null;
      if (generated && !newIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }
    for (final item in items) {
      final wasPurchased = keepPurchased[item.itemId] ?? false;
      batch.set(collection.doc(item.itemId), {
        ...item.toMap(),
        'isPurchased': wasPurchased,
      }, SetOptions(merge: true));
    }
    assertActive?.call(uid);
    await batch.commit();
  }
}
