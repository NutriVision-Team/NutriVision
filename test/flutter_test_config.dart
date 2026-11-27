import 'dart:async';
import 'dart:io';

/// Some responsive tests write screenshots to build/test_evidence (not tracked).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Directory('build/test_evidence').createSync(recursive: true);
  await testMain();
}
