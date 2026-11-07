import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String goal,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(name.trim());
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'goal': goal,
      'role': 'user',
      'onboardingSeen': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// هل المستخدم لسه ما شافش الـ Onboarding؟
  Future<bool> needsOnboarding() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['onboardingSeen'] != true;
  }

  Future<void> markOnboardingSeen() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .set({'onboardingSeen': true}, SetOptions(merge: true));
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> logout() => _auth.signOut();

  String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'الإيميل ده مستخدم قبل كده';
        case 'invalid-email':
          return 'الإيميل مش صحيح';
        case 'weak-password':
          return 'كلمة السر ضعيفة';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'الإيميل أو كلمة السر غلط';
        case 'network-request-failed':
          return 'مشكلة في الاتصال بالإنترنت';
        case 'too-many-requests':
          return 'محاولات كتير، جرب بعد شوية';
      }
      return e.message ?? 'حصل خطأ';
    }
    return 'حصل خطأ غير متوقع';
  }
}