import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

class FirebaseInitializer {
  FirebaseInitializer._();

  static final FirebaseInitializer instance = FirebaseInitializer._();

  bool _initialized = false;
  Future<void>? _initializationFuture;

  Future<void> initialize() {
    if (_initialized) {
      return Future.value();
    }

    if (_initializationFuture != null) {
      return _initializationFuture!;
    }

    _initializationFuture = _initializeInternal();
    return _initializationFuture!;
  }

  Future<void> _initializeInternal() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('Firebase initialized successfully.');
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'FirebaseInitializer',
          context: ErrorDescription('Failed to initialize Firebase'),
        ),
      );
      rethrow;
    } finally {
      _initializationFuture = null;
    }
  }
}
