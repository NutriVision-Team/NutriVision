import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../data/models/conversation_model.dart';

/// Persistence boundary for coach chat history, using the existing
/// `users/{uid}/conversations/{id}` path and the existing conversation and
/// chat-message models. History is real: a message is only shown after it
/// has been stored or while its store call is in flight with rollback.
abstract class CoachStore {
  Future<List<ChatMessageModel>> loadMessages(String uid);
  Future<void> appendMessage(String uid, ChatMessageModel message);
}

class FirestoreCoachStore implements CoachStore {
  FirestoreCoachStore(this._firestore, {this.assertActive});
  final void Function(String uid)? assertActive;

  final FirebaseFirestore _firestore;

  /// One durable coach conversation per user.
  static const conversationId = 'sufra_coach';

  DocumentReference<Map<String, dynamic>> _conversation(String uid) {
    assertActive?.call(uid);
    if (uid.isEmpty || uid.contains('/')) {
      throw ArgumentError.value(uid, 'uid');
    }
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.conversations)
        .doc(conversationId);
  }

  @override
  Future<List<ChatMessageModel>> loadMessages(String uid) async {
    final snapshot = await _conversation(
      uid,
    ).collection('messages').orderBy('createdAt').get();
    return snapshot.docs
        .map((doc) => ChatMessageModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  @override
  Future<void> appendMessage(String uid, ChatMessageModel message) async {
    if (message.messageId.isEmpty || message.content.trim().isEmpty) {
      throw ArgumentError.value(message.messageId, 'message.messageId');
    }
    final conversation = _conversation(uid);
    final existing = await conversation.get();
    final batch = _firestore.batch();
    batch.set(conversation, {
      'title': conversationId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // Set once at creation; later appends must not move it.
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(
      conversation.collection('messages').doc(message.messageId),
      message.toMap(),
    );
    assertActive?.call(uid);
    await batch.commit();
  }
}

/// Owner activation scope is session-only chat, without cloud history writes.
/// Cleared on route/account disposal. Separate from opt-in durable memory.
class SessionCoachStore implements CoachStore {
  SessionCoachStore({required this.ownerUid, required this.currentUid});
  final String ownerUid;
  final String? Function() currentUid;
  final _messages = <String, ChatMessageModel>{};
  void _active(String uid) {
    if (uid != ownerUid || currentUid() != ownerUid) {
      _messages.clear();
      throw StateError('Inactive owner');
    }
  }

  @override
  Future<List<ChatMessageModel>> loadMessages(String uid) async {
    _active(uid);
    return List.unmodifiable(_messages.values);
  }

  @override
  Future<void> appendMessage(String uid, ChatMessageModel message) async {
    _active(uid);
    _messages[message.messageId] = message;
  }

  void clear() => _messages.clear();
}
