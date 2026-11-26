import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The single owner of the app's [FlutterLocalNotificationsPlugin]
/// initialization. Both Firebase Messaging foreground display and local
/// reminders use this host, so there is one initialize call and one tap
/// callback. It never asks for notification permission: permission is
/// requested in context (see reminders), not at startup.
class LocalNotificationsHost {
  LocalNotificationsHost._();
  static final LocalNotificationsHost instance = LocalNotificationsHost._();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<String?> _taps = StreamController<String?>.broadcast();
  Future<void>? _init;
  String? _initialPayload;
  String? takeInitialPayload() {
    final result = _initialPayload;
    _initialPayload = null;
    return result;
  }

  /// Payload of every tapped notification (null payload for push taps).
  Stream<String?> get taps => _taps.stream;

  Future<void> ensureInitialized() => _init ??= _initialize();

  Future<void> _initialize() async {
    try {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_sufra_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Notification payloads are not logged.
          _taps.add(response.payload);
        },
      );
      final launch = await plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        _initialPayload = launch?.notificationResponse?.payload;
      }
    } catch (_) {
      _init = null;
      rethrow;
    }
  }
}
