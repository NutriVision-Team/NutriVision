import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  const AppNotificationModel({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.type,
    this.payload,
    this.isRead = false,
    this.createdAt,
    this.readAt,
  });

  final String notificationId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'type': type,
    'payload': payload ?? const <String, dynamic>{},
    'isRead': isRead,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
  };

  factory AppNotificationModel.fromMap(
    String notificationId,
    Map<String, dynamic> map,
  ) => AppNotificationModel(
    notificationId: notificationId,
    title: map['title'] as String? ?? '',
    body: map['body'] as String? ?? '',
    type: map['type'] as String? ?? 'generic',
    payload: map['payload'] as Map<String, dynamic>?,
    isRead: map['isRead'] as bool? ?? false,
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    readAt: (map['readAt'] as Timestamp?)?.toDate(),
  );
}
