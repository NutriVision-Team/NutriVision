import 'dart:async';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/user_profile_model.dart';
import 'package:sufradepi/data/repositories/user_repository.dart';
import 'package:sufradepi/features/auth/presentation/cubit/session_cubit.dart';
import 'package:sufradepi/services/auth_service.dart';

class GatedUserRepository implements UserRepository {
  final gate = Completer<UserProfileModel?>();
  @override
  Future<UserProfileModel?> getCurrentUser() => gate.future;
  @override
  Future<void> upsertUser(UserProfileModel user) async {}
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  test(
    'late profile response after sign-out cannot restore previous account',
    () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1'),
        signedIn: true,
      );
      final repo = GatedUserRepository();
      final cubit = SessionCubit(
        authService: AuthService.withAuth(auth),
        userRepository: repo,
      );
      await settle();
      await auth.signOut();
      await settle();
      repo.gate.complete(
        UserProfileModel(
          uid: 'u1',
          displayName: 'Fixture',
          onboardingCompleted: true,
        ),
      );
      await settle();
      expect(cubit.state, isA<SessionUnauthenticated>());
      await cubit.close();
    },
  );

  test(
    'mismatched profile is rejected instead of displaying another account data',
    () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1'),
        signedIn: true,
      );
      final repo = GatedUserRepository();
      final cubit = SessionCubit(
        authService: AuthService.withAuth(auth),
        userRepository: repo,
      );
      repo.gate.complete(
        UserProfileModel(
          uid: 'u2',
          displayName: 'Other fixture',
          onboardingCompleted: true,
        ),
      );
      await settle();
      expect(cubit.state, isA<SessionFailure>());
      await cubit.close();
    },
  );

  test(
    'new authenticated user with no profile goes to setup, not endless splash',
    () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1'),
        signedIn: true,
      );
      final repo = GatedUserRepository();
      final cubit = SessionCubit(
        authService: AuthService.withAuth(auth),
        userRepository: repo,
      );
      repo.gate.complete(null);
      await settle();
      expect(cubit.state, isA<SessionAuthenticated>());
      expect((cubit.state as SessionAuthenticated).needsSetup, isTrue);
      await cubit.close();
    },
  );

  test(
    'profile read failure is an explicit failure and never claims profile loaded',
    () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1'),
        signedIn: true,
      );
      final repo = GatedUserRepository();
      final cubit = SessionCubit(
        authService: AuthService.withAuth(auth),
        userRepository: repo,
      );
      await settle();
      repo.gate.completeError(StateError('offline'));
      await settle();
      expect(cubit.state, isA<SessionFailure>());
      await cubit.close();
    },
  );
}
