import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google requests identity only, never contacts, Drive or Gmail access.
class SufraGoogleIdentity {
  const SufraGoogleIdentity({required this.email, required this.idToken});
  final String email;
  final String? idToken;
}

class GoogleAuthGateway {
  GoogleAuthGateway({this.protectedEmail = ''});
  final String protectedEmail;

  // Optional pre-link protection for an explicitly identified password account.
  // Production owner no longer needs this guard after verified live linking.
  Future<void>? _initialization;

  /// Forgets the device Google account so the next sign-in shows the picker.
  /// Best effort: Firebase sign-out is what ends the app session.
  Future<void> signOut() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      await (_initialization ??= GoogleSignIn.instance.initialize());
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  Future<UserCredential> authenticate(
    FirebaseAuth auth, {
    required bool linkExisting,
    Future<SufraGoogleIdentity?> Function()? chooseWebIdentity,
  }) async {
    final owner = auth.currentUser;
    if (linkExisting && owner == null) {
      throw FirebaseAuthException(code: 'requires-password-sign-in');
    }
    if (!linkExisting && owner != null) {
      throw FirebaseAuthException(code: 'account-change-blocked');
    }
    final google = GoogleSignIn.instance;
    final SufraGoogleIdentity account;
    if (kIsWeb || chooseWebIdentity != null) {
      final selected = await chooseWebIdentity?.call();
      if (selected == null) {
        throw FirebaseAuthException(code: 'popup-closed-by-user');
      }
      account = selected;
    } else {
      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        throw FirebaseAuthException(code: 'operation-not-supported');
      }
      await (_initialization ??= google.initialize());
      final native = await google.authenticate();
      account = SufraGoogleIdentity(
        email: native.email,
        idToken: native.authentication.idToken,
      );
    }
    // Protect the existing owner password account from Firebase trusted-provider conversion.
    if (!linkExisting &&
        protectedEmail.isNotEmpty &&
        account.email.toLowerCase() == protectedEmail.toLowerCase()) {
      throw FirebaseAuthException(code: 'requires-password-sign-in');
    }
    if (owner != null &&
        account.email.toLowerCase() != owner.email?.toLowerCase()) {
      throw FirebaseAuthException(code: 'google-email-mismatch');
    }
    if (auth.currentUser?.uid != owner?.uid) {
      throw FirebaseAuthException(code: 'account-change-blocked');
    }
    final token = account.idToken;
    if (token == null || token.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    final credential = GoogleAuthProvider.credential(idToken: token);
    if (!linkExisting) return auth.signInWithCredential(credential);
    // Repeat linking is an authenticated Google check, not a failed action.
    // This keeps both the existing UID and password provider intact.
    return owner!.providerData.any((p) => p.providerId == 'google.com')
        ? owner.reauthenticateWithCredential(credential)
        : owner.linkWithCredential(credential);
  }
}
