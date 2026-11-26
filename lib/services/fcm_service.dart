import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_push_device_backend.dart';
import 'push_device_lifecycle.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'local_notifications_host.dart';

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'sufra_channel',
  'Sufra notifications',
  description: 'Sufra app notifications',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    LocalNotificationsHost.instance.plugin;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  // Native OS handles notification display; never log payloads or identifiers.
}

class FirebaseMessagingService with WidgetsBindingObserver {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  bool _initialized = false;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  PushDeviceLifecycle? _devices;
  final _routes = StreamController<String>.broadcast();
  String? _queuedRoute;
  Stream<String> get routes => _routes.stream;
  String? takePendingRoute() {
    final route = _queuedRoute;
    _queuedRoute = null;
    return route;
  }

  RemoteMessage? _pendingMessage;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(syncOwner());
  }

  Future<void> syncOwner() async {
    if (kIsWeb) return;
    try {
      await _devices?.sync(FirebaseAuth.instance.currentUser?.uid);
    } catch (_) {
      debugPrint('Push device sync unavailable.');
    }
  }

  Future<void> unlinkBeforeSignOut() async {
    if (kIsWeb) return;
    await _devices?.sync(null);
  }

  Future<void>? _initializationFuture;

  Future<void> initialize() {
    // Web push requires separate service worker/VAPID qualification.
    // Do not block web startup on native local-notification initialization.
    if (kIsWeb) return Future.value();
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
      final androidImplementation = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidImplementation?.createNotificationChannel(_androidChannel);

      // One shared initialization (no startup permission prompt, one tap
      // callback). Permission is requested in context from the reminders flow.
      await LocalNotificationsHost.instance.ensureInitialized();

      await _messaging.setForegroundNotificationPresentationOptions(
        // Foreground display is handled below only after the owner check.
        // Letting iOS display automatically would bypass that check and
        // display the same notification twice.
        alert: false,
        badge: false,
        sound: false,
      );

      // Notification permission is intentionally not requested here: it is
      // asked in context when the user first enables a reminder (the same
      // system permission also covers push display).

      // Registration occurs only after an existing granted permission.

      _subscriptions.add(
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage),
      );
      _subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp),
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) _pendingMessage = initialMessage;

      final backend = FirebasePushDeviceBackend(
        await SharedPreferences.getInstance(),
      );
      await backend.prepare();
      _devices = PushDeviceLifecycle(
        backend,
        initialOwner: backend.rememberedOwner,
      );
      _subscriptions.add(
        FirebaseAuth.instance.authStateChanges().listen((user) {
          unawaited(syncOwner());
          final pending = _pendingMessage;
          _pendingMessage = null;
          if (user != null && pending != null) _handleOpenedApp(pending);
        }),
      );
      // Refresh re-reads the current token and never logs its value.
      // ignore: deprecated_member_use
      _subscriptions.add(_messaging.onTokenRefresh.listen((_) => syncOwner()));
      await syncOwner();

      WidgetsBinding.instance.addObserver(this);
      _initialized = true;
    } catch (_) {
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();
      rethrow;
    } finally {
      _initializationFuture = null;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || message.data['uid'] != uid) return;
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    await _localNotificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: 'ic_sufra_notification',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: ownedPushRoute(message.data, uid) == null
          ? null
          : 'sufra:push:$uid:${message.data['type']}',
    );
  }

  void _handleOpenedApp(RemoteMessage message) {
    final route = ownedPushRoute(
      message.data,
      FirebaseAuth.instance.currentUser?.uid,
    );
    if (route != null) {
      final payload =
          'sufra:push:${message.data['uid']}:${message.data['type']}';
      if (_routes.hasListener) {
        _routes.add(payload);
      } else {
        _queuedRoute = payload;
      }
    }
  }
}
