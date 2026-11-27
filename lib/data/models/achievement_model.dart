import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  const AchievementModel({
    required this.achievementId,
    required this.achievementType,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.isUnlocked,
    this.unlockedAt,
    this.createdAt,
  });

  final String achievementId;
  final String achievementType;
  final String title;
  final String description;
  final double progress;
  final double target;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'achievementType': achievementType,
    'title': title,
    'description': description,
    'progress': progress,
    'target': target,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };

  factory AchievementModel.fromMap(
    String achievementId,
    Map<String, dynamic> map,
  ) => AchievementModel(
    achievementId: achievementId,
    achievementType: map['achievementType'] as String? ?? 'general',
    title: map['title'] as String? ?? '',
    description: map['description'] as String? ?? '',
    progress: (map['progress'] as num?)?.toDouble() ?? 0,
    target: (map['target'] as num?)?.toDouble() ?? 0,
    isUnlocked: map['isUnlocked'] as bool? ?? false,
    unlockedAt: (map['unlockedAt'] as Timestamp?)?.toDate(),
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
  );
}
