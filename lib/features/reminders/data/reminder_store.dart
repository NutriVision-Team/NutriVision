import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reminder_models.dart';

/// On-device settings, one record per account. Times are device-specific
/// and kept off the server, so there are no Firestore writes here.
class ReminderStore {
  ReminderStore(this._prefs);
  final SharedPreferences _prefs;

  static String key(String uid) => 'reminders.v1.$uid';

  ReminderSettings load(String uid) {
    if (uid.isEmpty) return ReminderSettings.empty;
    return ReminderSettings.fromJson(_prefs.getString(key(uid)));
  }

  Future<void> save(String uid, ReminderSettings settings) async {
    if (uid.isEmpty) throw ArgumentError.value(uid, 'uid');
    final ok = await _prefs.setString(key(uid), settings.toJson());
    if (!ok) throw StateError('Could not store reminder settings');
  }

  static const _pendingKey = 'reminders.pendingCancel';
  static const _ownerKey = 'reminders.scheduledOwner';

  /// True while a cancel-all has been started but not verified. Survives
  /// process death, so the next start retries before scheduling anything.
  bool get pendingCancel => _prefs.getBool(_pendingKey) ?? false;
  Future<void> setPendingCancel(bool v) async {
    final ok = v
        ? await _prefs.setBool(_pendingKey, true)
        : await _prefs.remove(_pendingKey);
    if (!ok) throw StateError('Could not store pending-cancel flag');
  }

  /// The account whose reminders may currently be scheduled on the OS.
  String? get scheduledOwner => _prefs.getString(_ownerKey);
  Future<void> setScheduledOwner(String? uid) async {
    final ok = (uid == null || uid.isEmpty)
        ? await _prefs.remove(_ownerKey)
        : await _prefs.setString(_ownerKey, uid);
    if (!ok) throw StateError('Could not store scheduled owner');
  }
}
