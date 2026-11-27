import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Firebase configured rules source exists and retains deployed protections',
    () {
      final config =
          jsonDecode(File('firebase.json').readAsStringSync()) as Map;
      final path = (config['firestore'] as Map)['rules'] as String;
      final rules = File(path);
      expect(
        rules.existsSync(),
        isTrue,
        reason: 'Never hand over a missing rules source',
      );
      final text = rules.readAsStringSync();
      expect(text, contains('match /users/{uid}/health_profile/{id}'));
      expect(
        text,
        contains("allow read: if resource.data.isPublished == true;"),
      );
      expect(text, isNot(contains('isPublished == true || true')));
      expect(text, contains('healthEnvelope'));
      expect(text, contains('isOwner(uid)'));
    },
  );
}
