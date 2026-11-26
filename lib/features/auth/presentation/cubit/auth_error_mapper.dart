import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../l10n/app_localizations.dart';

/// Maps Firebase Auth errors to localized, user-safe messages.
String mapAuthError(AppLocalizations l10n, Object error) {
  final ar = l10n.localeName.startsWith('ar');
  if (error is GoogleSignInException) {
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled =>
        ar
            ? 'اتلغى الدخول بجوجل. حسابك وبياناتك زي ما هم.'
            : 'Google sign-in canceled. Your account and data are unchanged.',
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        ar
            ? 'إعداد جوجل على الجهاز ده لسه محتاج تكميل. استخدم الإيميل مؤقتًا.'
            : 'Google setup on this device is incomplete. Use email for now.',
      _ => l10n.authGenericError,
    };
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'requires-password-sign-in':
        return ar
            ? 'لحماية حسابك الحالي، ادخل بالإيميل والباسورد واختار ربط حساب الإيميل الحالي.'
            : 'To protect your existing account, enter its email and password and choose Link email account.';
      case 'account-change-blocked':
        return ar
            ? 'الحساب اتغير أثناء الدخول. ابدأ تاني من حسابك المطلوب.'
            : 'The account changed during sign-in. Start again with the intended account.';
      case 'auth-operation-in-progress':
        return ar
            ? 'الدخول شغال بالفعل. استنى لحظة.'
            : 'Sign-in is already in progress. Please wait.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return ar ? 'اتلغى الدخول بجوجل.' : 'Google sign-in canceled.';
      case 'popup-blocked':
        return ar
            ? 'اسمح بنافذة جوجل المنبثقة وجرب تاني.'
            : 'Allow the Google popup and retry.';
      case 'google-email-mismatch':
      case 'user-mismatch':
        return ar
            ? 'اختار نفس بريد حساب سفرة عشان تربط الحساب بأمان.'
            : 'Choose the same email as your Sufra account to link safely.';
      case 'account-exists-with-different-credential':
      case 'credential-already-in-use':
      case 'email-already-in-use':
        return ar
            ? 'البريد مرتبط بحساب. ادخل بالطريقة الحالية وبعدين اربط جوجل، من غير إنشاء حساب بديل.'
            : 'This email is already linked. Sign in with its current method, then link Google without creating another account.';
      case 'provider-already-linked':
        return ar
            ? 'جوجل مربوط بالحساب ده بالفعل.'
            : 'Google is already linked to this account.';
      case 'too-many-requests':
        return ar
            ? 'محاولات كتير. استنى شوية قبل ما تجرب تاني.'
            : 'Too many attempts. Wait before trying again.';
      case 'user-disabled':
        return ar
            ? 'الحساب متوقف. راجع مسؤول التطبيق.'
            : 'This account is disabled. Contact the app owner.';
      case 'operation-not-allowed':
      case 'unauthorized-domain':
        return ar
            ? 'إعداد طريقة الدخول لسه مش مكتمل. استخدم الإيميل مؤقتًا.'
            : 'This sign-in method is not fully configured. Use email for now.';

      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return l10n.authInvalidCredentials;
      case 'user-not-found':
        return l10n.authUserNotFound;
      case 'weak-password':
        return l10n.authWeakPassword;
      case 'invalid-email':
        return l10n.validationEmail;
      case 'network-request-failed':
        return l10n.authNetworkError;
      default:
        return l10n.authGenericError;
    }
  }
  return l10n.authGenericError;
}
