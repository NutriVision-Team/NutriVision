import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/config/app_preferences.dart';
import 'package:sufradepi/core/theme/theme_cubit.dart';

void main() {
  Future<ThemeCubit> buildCubit([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await AppPreferences.load();
    return ThemeCubit(prefs);
  }

  test('defaults preserve the current HTML appearance', () async {
    final cubit = await buildCubit();
    expect(cubit.state.mode, ThemeMode.dark);
    expect(cubit.state.lightAccentId, isEmpty);
    expect(cubit.state.darkAccentId, isEmpty);
    expect(cubit.isDark, isTrue);
  });

  test('toggle flips mode and persists it', () async {
    final cubit = await buildCubit();
    await cubit.toggle();
    expect(cubit.state.mode, ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
    await cubit.toggle();
    expect(cubit.state.mode, ThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');
  });

  test('accents persist independently per mode', () async {
    final cubit = await buildCubit();
    await cubit.setAccent(Brightness.dark, 'copper');
    await cubit.setAccent(Brightness.light, 'green');
    expect(cubit.state.darkAccentId, 'copper');
    expect(cubit.state.lightAccentId, 'green');
    expect(cubit.accentIdFor(Brightness.dark), 'copper');
    expect(cubit.accentIdFor(Brightness.light), 'green');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('accent_dark'), 'copper');
    expect(prefs.getString('accent_light'), 'green');

    // Survives a reload (persisted separately, not shared state).
    // No setMockInitialValues here: that would reset the mock store.
    final reloaded = ThemeCubit(await AppPreferences.load());
    expect(reloaded.state.darkAccentId, 'copper');
    expect(reloaded.state.lightAccentId, 'green');
  });

  test('setting the same accent twice is a no-op', () async {
    final cubit = await buildCubit();
    await cubit.setAccent(Brightness.dark, 'copper');
    final before = cubit.state;
    await cubit.setAccent(Brightness.dark, 'copper');
    expect(identical(cubit.state, before), isTrue);
  });
  test('rapid unawaited accent writes settle in call order', () async {
    final cubit = await buildCubit();
    final writes = <Future<void>>[
      cubit.setAccent(Brightness.dark, 'copper'),
      cubit.setAccent(Brightness.dark, 'purple'),
      cubit.setAccent(Brightness.dark, 'green'),
    ];
    await Future.wait(writes);
    expect(cubit.state.darkAccentId, 'green');
    // The persisted value matches the final state after reload.
    final reloaded = ThemeCubit(await AppPreferences.load());
    expect(reloaded.state.darkAccentId, 'green');
  });

  test('rapid unawaited mode toggles persist the final mode', () async {
    final cubit = await buildCubit();
    await Future.wait([cubit.toggle(), cubit.toggle(), cubit.toggle()]);
    expect(cubit.state.mode, ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
  });
}
