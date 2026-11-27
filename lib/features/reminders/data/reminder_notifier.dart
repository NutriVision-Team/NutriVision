import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../services/local_notifications_host.dart';
import '../../../services/fcm_service.dart';
import '../domain/reminder_models.dart';
import '../domain/reminder_plan.dart';

/// Platform boundary for scheduling. Faked in tests; the real one below
/// needs a device to verify.
abstract interface class ReminderNotifier {
  Future<bool> areNotificationsEnabled();

  /// Shows the system prompt where one exists. Returns the resulting state.
  Future<bool> requestPermission();

  Future<void> schedule(
    PlannedReminder reminder, {
    required tz.TZDateTime first,
    required ReminderTexts texts,
  });

  Future<void> cancel(int id);

  /// IDs the OS still holds as pending. Used to verify a cancel-all.
  Future<Set<int>> pendingIds();
}

/// Device timezone as a tz [tz.Location]. Throws if it cannot be resolved,
/// so the caller never schedules in a guessed zone.
Future<tz.Location> deviceLocation() async {
  tzdata.initializeTimeZones();
  final info = await FlutterTimezone.getLocalTimezone();
  final location = tz.getLocation(info.identifier);
  tz.setLocalLocation(location);
  return location;
}

class LocalReminderNotifier implements ReminderNotifier {
  LocalReminderNotifier({LocalNotificationsHost? host})
    : _host = host ?? LocalNotificationsHost.instance;
  final LocalNotificationsHost _host;

  FlutterLocalNotificationsPlugin get _plugin => _host.plugin;

  @override
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    await _host.ensureInitialized();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.areNotificationsEnabled() ??
            false;
      case TargetPlatform.iOS:
        final o = await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.checkPermissions();
        return o?.isEnabled ?? false;
      default:
        return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await _host.ensureInitialized();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android 13+ shows the POST_NOTIFICATIONS prompt; older versions
        // return true because no runtime permission exists.
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      case TargetPlatform.iOS:
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true);
      default:
        break;
    }
    final enabled = await areNotificationsEnabled();
    if (enabled) {
      await FirebaseMessagingService.instance.syncOwner();
    }
    return enabled;
  }

  AndroidNotificationDetails _android(ReminderKind kind, ReminderTexts t) =>
      switch (kind) {
        ReminderKind.water => AndroidNotificationDetails(
          'sufra_reminders_water',
          t.waterChannel,
          icon: 'ic_sufra_notification',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        ReminderKind.meal => AndroidNotificationDetails(
          'sufra_reminders_meals',
          t.mealChannel,
          icon: 'ic_sufra_notification',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        ReminderKind.weight => AndroidNotificationDetails(
          'sufra_reminders_weight',
          t.weightChannel,
          icon: 'ic_sufra_notification',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      };

  @override
  Future<void> schedule(
    PlannedReminder r, {
    required tz.TZDateTime first,
    required ReminderTexts texts,
  }) async {
    await _host.ensureInitialized();
    await _plugin.zonedSchedule(
      id: r.id,
      title: texts.title,
      body: r.body,
      scheduledDate: first,
      notificationDetails: NotificationDetails(
        android: _android(r.kind, texts),
        iOS: const DarwinNotificationDetails(),
      ),
      // Inexact: no SCHEDULE_EXACT_ALARM permission needed. A reminder may
      // arrive a few minutes late in Doze, which is fine for these kinds.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: r.weekday == null
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
      payload: r.payload,
    );
  }

  @override
  Future<void> cancel(int id) async {
    // Web does not schedule native OS reminders on this origin/device.
    if (kIsWeb) return;
    await _host.ensureInitialized();
    await _plugin.cancel(id: id);
  }

  @override
  Future<Set<int>> pendingIds() async {
    if (kIsWeb) return <int>{};
    await _host.ensureInitialized();
    final list = await _plugin.pendingNotificationRequests();
    return {for (final r in list) r.id};
  }
}
