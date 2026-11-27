import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  const DeviceModel({
    required this.deviceId,
    required this.fcmToken,
    required this.platform,
    required this.deviceName,
    required this.language,
    required this.isActive,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
  });

  final String deviceId;
  final String fcmToken;
  final String platform;
  final String deviceName;
  final String language;
  final bool isActive;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'fcmToken': fcmToken,
    'platform': platform,
    'deviceName': deviceName,
    'language': language,
    'isActive': isActive,
    'lastSeenAt': lastSeenAt != null
        ? Timestamp.fromDate(lastSeenAt!)
        : FieldValue.serverTimestamp(),
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': updatedAt != null
        ? Timestamp.fromDate(updatedAt!)
        : FieldValue.serverTimestamp(),
  };

  factory DeviceModel.fromMap(String deviceId, Map<String, dynamic> map) =>
      DeviceModel(
        deviceId: deviceId,
        fcmToken: map['fcmToken'] as String? ?? '',
        platform: map['platform'] as String? ?? 'android',
        deviceName: map['deviceName'] as String? ?? '',
        language: map['language'] as String? ?? 'en',
        isActive: map['isActive'] as bool? ?? true,
        lastSeenAt: (map['lastSeenAt'] as Timestamp?)?.toDate(),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}
