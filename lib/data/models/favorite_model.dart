import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteModel {
  const FavoriteModel({
    required this.favoriteId,
    required this.targetId,
    required this.targetType,
    required this.title,
    this.imageUrl,
    this.createdAt,
  });

  final String favoriteId;
  final String targetId;
  final String targetType;
  final String title;
  final String? imageUrl;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'targetId': targetId,
    'targetType': targetType,
    'title': title,
    'imageUrl': imageUrl,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };

  factory FavoriteModel.fromMap(String favoriteId, Map<String, dynamic> map) =>
      FavoriteModel(
        favoriteId: favoriteId,
        targetId: map['targetId'] as String? ?? '',
        targetType: map['targetType'] as String? ?? 'food',
        title: map['title'] as String? ?? '',
        imageUrl: map['imageUrl'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
