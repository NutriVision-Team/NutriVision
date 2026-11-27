import 'package:flutter/material.dart';

/// Selectable accent palettes for the Liquid Theme Switcher (master 5.3).
///
/// Accents are INTERACTIVE colors only (buttons, focused borders, links).
/// Semantic colors - macro nutrients, success, warning, error - live in
/// AppColors and are never replaced by an accent.
class SufraAccent {
  const SufraAccent(this.id, this.color);

  /// Stable persisted identifier (stored in SharedPreferences).
  final String id;
  final Color color;
}

/// The accent catalog. Defaults preserve the current HTML appearance:
/// turquoise in dark mode, primary blue in light mode.
abstract final class SufraAccents {
  static const SufraAccent turquoise = SufraAccent(
    'turquoise',
    Color(0xFF06B6D4),
  );
  static const SufraAccent blue = SufraAccent('blue', Color(0xFF1565C0));
  static const SufraAccent purple = SufraAccent('purple', Color(0xFF7C3AED));
  static const SufraAccent copper = SufraAccent('copper', Color(0xFFFB8C00));
  static const SufraAccent green = SufraAccent('green', Color(0xFF22C55E));

  static const List<SufraAccent> values = [
    turquoise,
    blue,
    purple,
    copper,
    green,
  ];

  static const SufraAccent defaultDark = turquoise;
  static const SufraAccent defaultLight = blue;

  /// Resolve a persisted id; unknown/legacy ids fall back per mode.
  static SufraAccent resolve(String id, {required Brightness brightness}) =>
      values.firstWhere(
        (a) => a.id == id,
        orElse: () =>
            brightness == Brightness.dark ? defaultDark : defaultLight,
      );

  /// Next accent in the catalog (wraps), for the long-press cycle.
  static SufraAccent next(String id) {
    final index = values.indexWhere((a) => a.id == id);
    return values[(index + 1) % values.length];
  }

  /// Accessible text/icon color on top of [accent]: dark ink on bright
  /// accents, white on deep ones (WCAG-friendly in both themes).
  static Color onAccent(Color accent) =>
      ThemeData.estimateBrightnessForColor(accent) == Brightness.light
      ? const Color(0xFF0A1022)
      : Colors.white;
}

/// Theme extension exposing the active accent so widgets can consume it
/// with smooth lerped transitions instead of reading raw tokens.
class SufraAccentColors extends ThemeExtension<SufraAccentColors> {
  const SufraAccentColors({required this.accent, required this.onAccent});

  final Color accent;
  final Color onAccent;

  @override
  SufraAccentColors copyWith({Color? accent, Color? onAccent}) =>
      SufraAccentColors(
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
      );

  @override
  SufraAccentColors lerp(SufraAccentColors? other, double t) {
    if (other == null) return this;
    return SufraAccentColors(
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      onAccent: Color.lerp(onAccent, other.onAccent, t) ?? onAccent,
    );
  }
}

/// Convenience accessor: `context.accentColors`.
extension SufraAccentAccess on BuildContext {
  SufraAccentColors get accentColors {
    final ext = Theme.of(this).extension<SufraAccentColors>();
    assert(ext != null, 'SufraAccentColors is registered by AppTheme');
    return ext ??
        SufraAccentColors(
          accent: SufraAccents.defaultDark.color,
          onAccent: SufraAccents.onAccent(SufraAccents.defaultDark.color),
        );
  }
}
