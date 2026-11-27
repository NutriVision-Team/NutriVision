import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final reference = _firestore.collection(collection).doc(documentId);
    await reference.set(data, SetOptions(merge: merge));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required String collection,
    required String documentId,
  }) async {
    return _firestore.collection(collection).doc(documentId).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCollection({
    required String collection,
  }) async {
    return _firestore.collection(collection).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection({
    required String collection,
    Query<Map<String, dynamic>>? query,
  }) {
    final collectionRef = _firestore.collection(collection);
    return (query ?? collectionRef).snapshots();
  }
}
