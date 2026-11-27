import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every drawable referenced by main manifest exists in source', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    for (final match in RegExp(
      r'@drawable/([a-z0-9_]+)',
    ).allMatches(manifest)) {
      final name = match.group(1)!;
      final files = Directory(
        'android/app/src/main/res',
      ).listSync(recursive: true).whereType<File>();
      expect(
        files.any((f) => f.path.split('/').last.split('.').first == name),
        isTrue,
        reason: 'Missing Android drawable $name, resource linking would fail',
      );
    }
  });
}
