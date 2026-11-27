import 'dart:async';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/user_profile_model.dart';
import 'package:sufradepi/data/repositories/user_repository.dart';
import 'package:sufradepi/features/auth/presentation/cubit/session_cubit.dart';
import 'package:sufradepi/services/auth_service.dart';

class ProfileProbe implements UserRepository {
  int reads = 0;
  bool fail = false;
  @override
  Future<UserProfileModel?> getCurrentUser() async {
    reads++;
    if (fail) throw StateError('write/read failed');
    return null;
  }

  @override
  Future<void> upsertUser(UserProfileModel user) async {}
}

void main() {
  test('auth routing waits for operation and reloads after success', () async {
    final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u'));
    final repo = ProfileProbe();
    final c = SessionCubit(
      authService: AuthService.withAuth(auth),
      userRepository: repo,
    );
    await Future<void>.delayed(Duration.zero);
    final gate = Completer<void>();
    final operation = c.completeAuthOperation(() async {
      await auth.signInWithEmailAndPassword(
        email: 'u@example.com',
        password: 'fixture',
      );
      await gate.future;
    });
    await Future<void>.delayed(Duration.zero);
    expect(c.state, isA<SessionUnauthenticated>());
    expect(repo.reads, 0);
    await expectLater(c.completeAuthOperation(() async {}), throwsStateError);
    gate.complete();
    await operation;
    expect(c.state, isA<SessionAuthenticated>());
    expect(repo.reads, 1);
    await c.close();
  });
  test('cancel/error releases hold and next operation can run', () async {
    final auth = MockFirebaseAuth();
    final c = SessionCubit(
      authService: AuthService.withAuth(auth),
      userRepository: ProfileProbe(),
    );
    await expectLater(
      c.completeAuthOperation(() async => throw StateError('cancel')),
      throwsStateError,
    );
    expect(c.state, isA<SessionUnauthenticated>());
    expect(await c.completeAuthOperation(() async => 7), 7);
    await c.close();
  });
  test(
    'profile failure becomes explicit session failure without stuck hold',
    () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u'),
        signedIn: true,
      );
      final repo = ProfileProbe()..fail = true;
      final c = SessionCubit(
        authService: AuthService.withAuth(auth),
        userRepository: repo,
      );
      await c.completeAuthOperation(() async {});
      expect(c.state, isA<SessionFailure>());
      repo.fail = false;
      await c.completeAuthOperation(() async {});
      expect(c.state, isA<SessionAuthenticated>());
      await c.close();
    },
  );
}
