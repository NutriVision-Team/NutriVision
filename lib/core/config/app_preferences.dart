import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central access point for small local preferences that must survive
/// restarts: onboarding flag, theme mode and locale.
///
/// Exposes a [Listenable] so the router can refresh redirects when any of
/// these values change.
class AppPreferences extends ChangeNotifier {
  AppPreferences._(this._prefs);

  static const String _keyOnboardingSeen = 'onboarding_seen';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLocale = 'locale';
  static const String _keyAccentLight = 'accent_light';
  static const String _keyAccentDark = 'accent_dark';

  final SharedPreferences _prefs;

  static Future<AppPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences._(prefs);
  }

  bool get onboardingSeen => _prefs.getBool(_keyOnboardingSeen) ?? false;

  Future<void> setOnboardingSeen() async {
    await _prefs.setBool(_keyOnboardingSeen, true);
    notifyListeners();
  }

  /// 'system' | 'light' | 'dark'
  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'dark';

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
    notifyListeners();
  }

  /// Accent ids, persisted INDEPENDENTLY per theme mode (master 5.3):
  /// choosing an accent in one mode never overwrites the other mode's.
  /// Empty means the mode default (blue for light, turquoise for dark).
  String get lightAccentId => _prefs.getString(_keyAccentLight) ?? '';

  Future<void> setLightAccentId(String id) async {
    await _prefs.setString(_keyAccentLight, id);
    notifyListeners();
  }

  String get darkAccentId => _prefs.getString(_keyAccentDark) ?? '';

  Future<void> setDarkAccentId(String id) async {
    await _prefs.setString(_keyAccentDark, id);
    notifyListeners();
  }

  /// 'ar' | 'en'
  String get localeCode {
    final code = _prefs.getString(_keyLocale);
    return const {'ar', 'en'}.contains(code) ? code! : 'ar';
  }

  Future<void> setLocaleCode(String code) async {
    if (!const {'ar', 'en'}.contains(code)) return;
    await _prefs.setString(_keyLocale, code);
    notifyListeners();
  }
}
