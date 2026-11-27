import 'dart:async';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/user_profile_model.dart';
import 'package:sufradepi/data/repositories/user_repository.dart';
import 'package:sufradepi/features/auth/presentation/cubit/session_cubit.dart';
import 'package:sufradepi/services/auth_service.dart';

class NoProfile implements UserRepository {
  @override
  Future<UserProfileModel?> getCurrentUser() async => null;
  @override
  Future<void> upsertUser(UserProfileModel user) async {}
}

void main() {
  test('sign-out waits for cleanup before auth transition', () async {
    final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u'), signedIn: true);
    final gate = Completer<void>();
    var after = false;
    final c = SessionCubit(
      authService: AuthService.withAuth(auth),
      userRepository: NoProfile(),
      beforeSignOut: () => gate.future,
      afterSignOut: () => after = true,
    );
    await Future<void>.delayed(Duration.zero);
    final f = c.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(auth.currentUser?.uid, 'u');
    expect(after, isFalse);
    gate.complete();
    await f;
    expect(auth.currentUser, isNull);
    expect(after, isTrue);
    await c.close();
  });
  test(
    'cleanup failure is explicit and completion hook still releases transition',
    () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u'),
        signedIn: true,
      );
      var after = false;
      final c = SessionCubit(
        authService: AuthService.withAuth(auth),
        userRepository: NoProfile(),
        beforeSignOut: () async => throw StateError('cleanup'),
        afterSignOut: () => after = true,
      );
      await expectLater(c.signOut(), throwsStateError);
      expect(auth.currentUser?.uid, 'u');
      expect(after, isTrue);
      await c.close();
    },
  );
}
