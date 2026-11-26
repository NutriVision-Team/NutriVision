import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'google_auth_gateway.dart';

class AuthService {
  AuthService._()
    : _auth = FirebaseAuth.instance,
      // Live explicit linking, password login and ordinary Google login
      // proved both providers return the unchanged owner UID on 2026-11-23.
      _google = GoogleAuthGateway();

  @visibleForTesting
  AuthService.withAuth(FirebaseAuth auth, {GoogleAuthGateway? google})
    : _auth = auth,
      _google = google ?? GoogleAuthGateway();

  static final AuthService instance = AuthService._();

  /// A stalled network must end in a clear error, not an endless spinner.
  static const Duration networkTimeout = Duration(seconds: 30);

  Future<T> _bounded<T>(Future<T> call) => call.timeout(
    networkTimeout,
    onTimeout: () =>
        throw FirebaseAuthException(code: 'network-request-failed'),
  );

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _bounded(
      _auth.signInWithEmailAndPassword(email: email, password: password),
    );
    return credential.user;
  }

  Future<User?> createUserWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _bounded(
      _auth.createUserWithEmailAndPassword(email: email, password: password),
    );
    return credential.user;
  }

  final GoogleAuthGateway _google;
  bool _googleBusy = false;
  Future<User?> signInWithGoogle({
    required bool linkExisting,
    Future<SufraGoogleIdentity?> Function()? chooseWebIdentity,
  }) async {
    if (_googleBusy) {
      throw FirebaseAuthException(code: 'auth-operation-in-progress');
    }
    _googleBusy = true;
    final previousUid = _auth.currentUser?.uid;
    try {
      final result = await _google.authenticate(
        _auth,
        linkExisting: linkExisting,
        chooseWebIdentity: chooseWebIdentity,
      );
      if (linkExisting && result.user?.uid != previousUid) {
        throw FirebaseAuthException(code: 'account-change-blocked');
      }
      return result.user;
    } finally {
      _googleBusy = false;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
  }
}
