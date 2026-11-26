import 'package:flutter/foundation.dart';

/// Optional integrations must never prevent the core app from starting.
/// The caller intentionally does not await this work on the startup path.
Future<bool> initializeOptionalMessaging(
  Future<void> Function() initialize,
) async {
  try {
    await initialize();
    return true;
  } catch (_) {
    // No provider diagnostics, tokens, payloads or user data in logs.
    debugPrint('Optional push notifications are unavailable.');
    return false;
  }
}
