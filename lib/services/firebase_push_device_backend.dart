import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'push_device_lifecycle.dart';

class FirebasePushDeviceBackend implements PushDeviceBackend {
  FirebasePushDeviceBackend(this.preferences);
  final SharedPreferences preferences;
  String? get rememberedOwner => preferences.getString('push_owner');
  @override
  Future<void> rememberOwner(String? uid) async {
    final ok = uid == null
        ? await preferences.remove('push_owner')
        : await preferences.setString('push_owner', uid);
    if (!ok) throw StateError('Push ownership persistence unavailable');
  }

  String get _deviceId {
    final existing = preferences.getString('push_installation_id');
    if (existing != null) return existing;
    throw StateError('Push installation not prepared');
  }

  Future<void> prepare() async {
    if (preferences.getString('push_installation_id') == null) {
      final random = Random.secure();
      final id = List.generate(
        24,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      if (!await preferences.setString('push_installation_id', id)) {
        throw StateError('Installation persistence unavailable');
      }
    }
  }

  void _owner(String uid) {
    if (uid.isEmpty ||
        uid.contains('/') ||
        FirebaseAuth.instance.currentUser?.uid != uid) {
      throw StateError('Push owner changed');
    }
  }

  DocumentReference<Map<String, dynamic>> _ref(String uid) => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('devices')
      .doc(_deviceId);
  @override
  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    final status = (await FirebaseMessaging.instance.getNotificationSettings())
        .authorizationStatus;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  @override
  // ignore: deprecated_member_use
  Future<String?> token() => FirebaseMessaging.instance.getToken();
  @override
  // ignore: deprecated_member_use
  Future<void> deleteToken() => FirebaseMessaging.instance.deleteToken();
  @override
  Future<void> remove(String uid) async {
    _owner(uid);
    await _ref(uid).delete();
  }

  @override
  Future<void> save(String uid, String token) async {
    _owner(uid);
    await prepare();
    final ref = _ref(uid);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      _owner(uid);
      final old = await tx.get(ref);
      _owner(uid);
      tx.set(ref, {
        'fcmToken': token,
        'platform': defaultTargetPlatform.name,
        'deviceName': 'Sufra installation',
        'language': preferences.getString('locale') ?? 'ar',
        'isActive': true,
        'lastSeenAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (!old.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
