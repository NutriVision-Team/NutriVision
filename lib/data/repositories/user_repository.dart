import '../../features/gamification/data/local_protected_ledger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/firestore_collections.dart';
import '../../core/errors/app_exception.dart';
import '../models/user_profile_model.dart';

abstract class UserRepository {
  Future<UserProfileModel?> getCurrentUser();
  Future<void> upsertUser(UserProfileModel user);
}

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(
    this._firestore,
    this._auth, {
    this.localActivityHook,
  });
  final LocalRecordedActivityHook? localActivityHook;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<UserProfileModel?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return null;
    }

    final snapshot = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (_auth.currentUser?.uid != uid) {
      throw const AppException('Account changed during profile read.');
    }
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    if (snapshot.data()!['uid'] != uid) {
      throw const AppException('Profile owner does not match its document.');
    }
    return UserProfileModel.fromMap(snapshot.data()!);
  }

  @override
  Future<void> upsertUser(UserProfileModel user) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty || uid != user.uid) {
      throw const AppException('Authenticated user is required.');
    }

    localActivityHook?.assertOwner(uid);
    final payload = user.toMap();
    if (localActivityHook == null) {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .set(payload, SetOptions(merge: true));
      return;
    }
    final ref = _firestore.collection(FirestoreCollections.users).doc(uid);
    if (user.onboardingCompleted) {
      await localActivityHook!.beforeSourceSave(uid, 'profile', 'setup');
    }
    await _firestore.runTransaction((tx) async {
      final old = (await tx.get(ref)).data();
      localActivityHook!.assertOwner(uid);
      // Only the real false->true transition after activation is recordable.
      // A legacy completed profile never gets today's timestamp on an edit.
      if (user.onboardingCompleted &&
          old?['onboardingCompleted'] == false &&
          old?['rewardSetupRecordedAt'] == null) {
        payload['rewardSetupRecordedAt'] = FieldValue.serverTimestamp();
      }
      tx.set(ref, payload, SetOptions(merge: true));
    });
    if (user.onboardingCompleted) {
      await localActivityHook!.sourceSaved(uid, 'profile', 'setup');
    }
  }
}
