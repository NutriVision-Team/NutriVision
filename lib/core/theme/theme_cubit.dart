import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/app_preferences.dart';

/// Theme mode plus independently persisted per-mode accent ids (master 5.3).
class ThemeState {
  const ThemeState({
    required this.mode,
    required this.lightAccentId,
    required this.darkAccentId,
  });

  final ThemeMode mode;
  final String lightAccentId;
  final String darkAccentId;

  ThemeState copyWith({
    ThemeMode? mode,
    String? lightAccentId,
    String? darkAccentId,
  }) => ThemeState(
    mode: mode ?? this.mode,
    lightAccentId: lightAccentId ?? this.lightAccentId,
    darkAccentId: darkAccentId ?? this.darkAccentId,
  );

  @override
  bool operator ==(Object other) =>
      other is ThemeState &&
      other.mode == mode &&
      other.lightAccentId == lightAccentId &&
      other.darkAccentId == darkAccentId;

  @override
  int get hashCode => Object.hash(mode, lightAccentId, darkAccentId);
}

/// Holds and persists the application [ThemeMode] and per-mode accents.
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._preferences)
    : super(
        ThemeState(
          mode: _modeFromString(_preferences.themeMode),
          lightAccentId: _preferences.lightAccentId,
          darkAccentId: _preferences.darkAccentId,
        ),
      );

  final AppPreferences _preferences;

  static ThemeMode _modeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  static String _stringFromMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  bool get isDark => state.mode == ThemeMode.dark;

  /// The accent id that applies to a given brightness.
  String accentIdFor(Brightness brightness) =>
      brightness == Brightness.dark ? state.darkAccentId : state.lightAccentId;

  Future<void> toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state.mode) return;
    emit(state.copyWith(mode: mode));
    await _preferences.setThemeMode(_stringFromMode(mode));
  }

  /// Persist the accent for one mode only; the other mode keeps its own.
  Future<void> setAccent(Brightness brightness, String accentId) async {
    final current = accentIdFor(brightness);
    if (current == accentId) return;
    if (brightness == Brightness.dark) {
      emit(state.copyWith(darkAccentId: accentId));
      await _preferences.setDarkAccentId(accentId);
    } else {
      emit(state.copyWith(lightAccentId: accentId));
      await _preferences.setLightAccentId(accentId);
    }
  }
}

/// Holds and persists the application locale.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._preferences) : super(Locale(_preferences.localeCode));

  final AppPreferences _preferences;

  Future<void> setLocale(Locale locale) async {
    if (!const {'ar', 'en'}.contains(locale.languageCode) || locale == state) {
      return;
    }
    emit(locale);
    await _preferences.setLocaleCode(locale.languageCode);
  }

  Future<void> toggle() => setLocale(
    state.languageCode == 'ar' ? const Locale('en') : const Locale('ar'),
  );
}
