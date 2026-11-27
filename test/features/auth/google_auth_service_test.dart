import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/services/auth_service.dart';
import 'package:sufradepi/services/google_auth_gateway.dart';
import 'package:sufradepi/features/auth/presentation/cubit/auth_error_mapper.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

class FixtureUserInfo extends UserInfo {
  FixtureUserInfo(String provider)
    : super.fromJson({
        'uid': 'fixture-$provider',
        'providerId': provider,
        'isAnonymous': false,
        'isEmailVerified': true,
      });
}

class ControlledGoogle extends GoogleAuthGateway {
  final completer = Completer<UserCredential>();
  int calls = 0;
  bool? link;
  @override
  Future<UserCredential> authenticate(
    FirebaseAuth auth, {
    required bool linkExisting,
    Future<SufraGoogleIdentity?> Function()? chooseWebIdentity,
  }) {
    calls++;
    link = linkExisting;
    return completer.future;
  }
}

// ignore: must_be_immutable
class TrackingLinkedUser extends MockUser {
  TrackingLinkedUser()
    : super(
        uid: 'linked-owner',
        email: 'owner@example.com',
        providerData: [
          FixtureUserInfo('password'),
          FixtureUserInfo('google.com'),
        ],
      );
  int links = 0;
  int reauthentications = 0;
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) {
    links++;
    return super.linkWithCredential(credential);
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential? credential,
  ) {
    reauthentications++;
    return super.reauthenticateWithCredential(credential);
  }
}

void main() {
  test(
    'already linked Google reauthenticates without relinking or losing password',
    () async {
      final user = TrackingLinkedUser();
      final auth = MockFirebaseAuth(mockUser: user, signedIn: true);
      final result = await GoogleAuthGateway().authenticate(
        auth,
        linkExisting: true,
        chooseWebIdentity: () async => const SufraGoogleIdentity(
          email: 'owner@example.com',
          idToken: 'fixture',
        ),
      );
      expect(result.user!.uid, 'linked-owner');
      expect(user.links, 0);
      expect(user.reauthentications, 1);
      expect(
        user.providerData.map((p) => p.providerId),
        containsAll(['password', 'google.com']),
      );
    },
  );
  test('duplicate Google requests cannot race', () async {
    final auth = MockFirebaseAuth();
    final google = ControlledGoogle();
    final service = AuthService.withAuth(auth, google: google);
    final first = service.signInWithGoogle(linkExisting: false);
    await expectLater(
      service.signInWithGoogle(linkExisting: false),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(google.calls, 1);
    google.completer.completeError(
      FirebaseAuthException(code: 'popup-closed-by-user'),
    );
    await expectLater(first, throwsA(isA<FirebaseAuthException>()));
  });
  test(
    'linking preserves exact UID and rejects changed owner result',
    () async {
      final user = MockUser(uid: 'original', email: 'owner@example.com');
      final auth = MockFirebaseAuth(mockUser: user, signedIn: true);
      final google = ControlledGoogle();
      final service = AuthService.withAuth(auth, google: google);
      final future = service.signInWithGoogle(linkExisting: true);
      google.completer.complete(
        await MockFirebaseAuth(
          mockUser: MockUser(uid: 'wrong'),
        ).signInWithCredential(
          GoogleAuthProvider.credential(idToken: 'fixture'),
        ),
      );
      await expectLater(future, throwsA(isA<FirebaseAuthException>()));
      expect(auth.currentUser!.uid, 'original');
      expect(google.link, isTrue);
    },
  );
  test(
    'gateway linking without authenticated owner never launches provider',
    () async {
      await expectLater(
        GoogleAuthGateway().authenticate(
          MockFirebaseAuth(),
          linkExisting: true,
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    },
  );
  test('gateway cannot use sign-in to replace an active account', () async {
    final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u'), signedIn: true);
    await expectLater(
      GoogleAuthGateway().authenticate(auth, linkExisting: false),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(auth.currentUser!.uid, 'u');
  });
  test(
    'mismatched identity rejected before linking and owner unchanged',
    () async {
      final user = MockUser(uid: 'u', email: 'owner@example.com');
      final auth = MockFirebaseAuth(mockUser: user, signedIn: true);
      await expectLater(
        GoogleAuthGateway().authenticate(
          auth,
          linkExisting: true,
          chooseWebIdentity: () async => const SufraGoogleIdentity(
            email: 'other@example.com',
            idToken: 'fixture',
          ),
        ),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'google-email-mismatch',
          ),
        ),
      );
      expect(auth.currentUser!.uid, 'u');
      expect(
        user.providerData.any((p) => p.providerId == 'google.com'),
        isFalse,
      );
    },
  );
  test(
    'owner direct sign-in rejected before Firebase provider conversion',
    () async {
      final auth = MockFirebaseAuth();
      await expectLater(
        GoogleAuthGateway(protectedEmail: 'owner@example.invalid').authenticate(
          auth,
          linkExisting: false,
          chooseWebIdentity: () async => const SufraGoogleIdentity(
            email: 'owner@example.invalid',
            idToken: 'fixture',
          ),
        ),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'requires-password-sign-in',
          ),
        ),
      );
      expect(auth.currentUser, isNull);
    },
  );
  test('cancel and missing token never mutate authentication', () async {
    final auth = MockFirebaseAuth();
    for (final identity in [
      null,
      const SufraGoogleIdentity(email: 'test@example.com', idToken: null),
      const SufraGoogleIdentity(email: 'test@example.com', idToken: ''),
    ]) {
      await expectLater(
        GoogleAuthGateway().authenticate(
          auth,
          linkExisting: false,
          chooseWebIdentity: () async => identity,
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(auth.currentUser, isNull);
    }
  });
  test('account switch during identity chooser blocks the write', () async {
    final user = MockUser(uid: 'u', email: 'owner@example.com');
    final auth = MockFirebaseAuth(mockUser: user, signedIn: true);
    await expectLater(
      GoogleAuthGateway().authenticate(
        auth,
        linkExisting: true,
        chooseWebIdentity: () async {
          await auth.signOut();
          return const SufraGoogleIdentity(
            email: 'owner@example.com',
            idToken: 'fixture',
          );
        },
      ),
      throwsA(
        isA<FirebaseAuthException>().having(
          (e) => e.code,
          'code',
          'account-change-blocked',
        ),
      ),
    );
    expect(auth.currentUser, isNull);
  });
  for (final lang in ['ar', 'en']) {
    test(
      'safe localized mapping covers cancellation, throttling and linking errors $lang',
      () async {
        final l = await AppLocalizations.delegate.load(Locale(lang));
        for (final code in [
          'requires-password-sign-in',
          'auth-operation-in-progress',
          'account-change-blocked',
          'popup-closed-by-user',
          'popup-blocked',
          'google-email-mismatch',
          'credential-already-in-use',
          'provider-already-linked',
          'too-many-requests',
          'user-disabled',
          'operation-not-allowed',
          'invalid-credential',
          'unknown',
        ]) {
          final mapped = mapAuthError(
            l,
            FirebaseAuthException(
              code: code,
              message: 'PRIVATE RAW PROVIDER DETAIL',
            ),
          );
          expect(mapped, isNotEmpty);
          expect(mapped, isNot(contains('PRIVATE')));
        }
      },
    );
  }
}
