import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.uid,
    required this.displayName,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    this.preferredLanguage = 'en',
    this.timezone = 'UTC',
    this.measurementSystem = 'metric',
    this.notificationPreferences = const <String, bool>{},
    this.onboardingCompleted = false,
    this.accountStatus = 'active',
    this.policyAcceptance,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;
  final String preferredLanguage;
  final String timezone;
  final String measurementSystem;
  final Map<String, bool> notificationPreferences;
  final bool onboardingCompleted;
  final String accountStatus;

  /// Versioned acceptance evidence. Null on legacy profiles, preserved on merge.
  final Map<String, dynamic>? policyAcceptance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    final now = FieldValue.serverTimestamp();
    return {
      if (policyAcceptance != null) 'policyAcceptance': policyAcceptance,
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'preferredLanguage': preferredLanguage,
      'timezone': timezone,
      'measurementSystem': measurementSystem,
      'notificationPreferences': notificationPreferences,
      'onboardingCompleted': onboardingCompleted,
      'accountStatus': accountStatus,
      'createdAt': createdAt ?? now,
      'updatedAt': updatedAt ?? now,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      policyAcceptance: map['policyAcceptance'] is Map
          ? Map<String, dynamic>.from(map['policyAcceptance'] as Map)
          : null,
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      photoUrl: map['photoUrl'] as String?,
      preferredLanguage: map['preferredLanguage'] as String? ?? 'en',
      timezone: map['timezone'] as String? ?? 'UTC',
      measurementSystem: map['measurementSystem'] as String? ?? 'metric',
      notificationPreferences: Map<String, bool>.from(
        (map['notificationPreferences'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value as bool? ?? false),
        ),
      ),
      onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
      accountStatus: map['accountStatus'] as String? ?? 'active',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
