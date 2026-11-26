import 'package:shared_preferences/shared_preferences.dart';

/// A user-chosen device-local preference, not a medical recommendation.
/// No existing Firestore document is changed. Each account has a separate key.
abstract final class HydrationGoalStore {
  static const defaultMl = 2000.0;
  static String _key(String uid) => 'hydration_goal_ml_v1_$uid';
  static Future<double?> read(String uid) async {
    if (uid.isEmpty) return null;
    final stored = (await SharedPreferences.getInstance()).get(_key(uid));
    final value = stored is num ? stored.toDouble() : null;
    return value != null && value.isFinite && value > 0 && value <= 20000
        ? value
        : null;
  }

  static Future<void> save(String uid, double ml) async {
    if (uid.isEmpty || !ml.isFinite || ml <= 0 || ml > 20000) {
      throw ArgumentError('Invalid hydration preference');
    }
    if (!await (await SharedPreferences.getInstance()).setDouble(
      _key(uid),
      ml,
    )) {
      throw StateError('Preference was not saved');
    }
  }
}
