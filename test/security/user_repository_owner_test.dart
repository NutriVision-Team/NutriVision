import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/user_profile_model.dart';
import 'package:sufradepi/data/repositories/user_repository.dart';
import '../planning/support/planning_memory_firestore.dart';

void main() {
  const profile = UserProfileModel(uid: 'a', displayName: 'A');
  test(
    'profile writes require authenticated matching owner and preserve merge',
    () async {
      final db = PlanningMemoryFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'a'),
        signedIn: true,
      );
      final repo = FirestoreUserRepository(db, auth);
      db.seed('users/a', {'kept': true});
      await repo.upsertUser(profile);
      expect(db.documents['users/a']!['kept'], isTrue);
      expect(db.documents['users/a']!['uid'], 'a');
      await expectLater(
        repo.upsertUser(const UserProfileModel(uid: 'b', displayName: 'B')),
        throwsA(isA<Exception>()),
      );
      expect(db.documents.containsKey('users/b'), isFalse);
      await auth.signOut();
      await expectLater(repo.upsertUser(profile), throwsA(isA<Exception>()));
    },
  );
  test('profile read rejects mismatched document payload', () async {
    final db = PlanningMemoryFirestore();
    final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'a'), signedIn: true);
    db.seed('users/a', {'uid': 'b', 'displayName': 'B'});
    await expectLater(
      FirestoreUserRepository(db, auth).getCurrentUser(),
      throwsA(isA<Exception>()),
    );
  });
}
