import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Opt-in only. Never uses debug attestation in a release build and never
/// activates production attestation before registration is verified.
Future<void> initializeSyntheticAiAppCheck() async {
  const enabled = bool.fromEnvironment('SUFRA_SYNTHETIC_AI_TEST');
  if (!kDebugMode || !enabled) return;
  await FirebaseAppCheck.instance.activate(
    providerAndroid: const AndroidDebugProvider(),
    providerApple: const AppleDebugProvider(),
  );
}
