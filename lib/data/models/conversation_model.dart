import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  const ChatMessageModel({
    required this.messageId,
    required this.role,
    required this.content,
    required this.messageType,
    this.metadata,
    this.createdAt,
  });

  final String messageId;
  final String role;
  final String content;
  final String messageType;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'role': role,
    'content': content,
    'messageType': messageType,
    'metadata': metadata ?? const <String, dynamic>{},
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };

  factory ChatMessageModel.fromMap(
    String messageId,
    Map<String, dynamic> map,
  ) => ChatMessageModel(
    messageId: messageId,
    role: map['role'] as String? ?? 'user',
    content: map['content'] as String? ?? '',
    messageType: map['messageType'] as String? ?? 'text',
    metadata: map['metadata'] as Map<String, dynamic>?,
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
  );
}

class ConversationModel {
  const ConversationModel({
    required this.conversationId,
    required this.title,
    this.createdAt,
    this.updatedAt,
    this.lastMessageAt,
  });

  final String conversationId;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': updatedAt != null
        ? Timestamp.fromDate(updatedAt!)
        : FieldValue.serverTimestamp(),
    'lastMessageAt': lastMessageAt != null
        ? Timestamp.fromDate(lastMessageAt!)
        : null,
  };

  factory ConversationModel.fromMap(
    String conversationId,
    Map<String, dynamic> map,
  ) => ConversationModel(
    conversationId: conversationId,
    title: map['title'] as String? ?? 'New conversation',
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
  );
}
