import 'package:flutter/material.dart';

import 'app_accents.dart';
import 'app_colors.dart';
import '../widgets/glass_highlight.dart';
import '../widgets/sufra_button_response.dart';

/// Material 3 foundation with the Sufra design system applied on top.
abstract final class AppTheme {
  static const String fontFamily = String.fromEnvironment(
    'SUFRA_FONT_FAMILY',
    defaultValue: 'SufraBody',
  );
  static const List<String> fontFallback = ['Cairo', 'Tajawal', 'Reem Kufi'];
  static const String displayFontFamily = String.fromEnvironment(
    'SUFRA_DISPLAY_FONT_FAMILY',
    defaultValue: 'SufraDisplay',
  );

  /// [accent] is the interactive accent for this theme (master 5.3).
  /// Defaults preserve the current HTML appearance. Semantic colors
  /// (error, macro nutrients, success) never follow the accent.
  static ThemeData dark({Color accent = AppColors.turquoise}) {
    final onAccent = SufraAccents.onAccent(accent);
    final scheme = ColorScheme.dark(
      primary: accent,
      onPrimary: onAccent,
      secondary: AppColors.aiPurple,
      onSecondary: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
    );

    return _base(
      scheme,
      accent: accent,
      onAccent: onAccent,
    ).copyWith(scaffoldBackgroundColor: AppColors.darkBackground);
  }

  static ThemeData light({Color accent = AppColors.primaryBlue}) {
    final onAccent = SufraAccents.onAccent(accent);
    final scheme = ColorScheme.light(
      primary: accent,
      onPrimary: onAccent,
      secondary: AppColors.aiPurple,
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      error: AppColors.error,
      onError: Colors.white,
    );

    return _base(
      scheme,
      accent: accent,
      onAccent: onAccent,
    ).copyWith(scaffoldBackgroundColor: AppColors.lightBackground);
  }

  /// Role-based typography from the user's supplied fonts.
  /// heading: Azahar Display Black (AR) / Bebas Neue (EN) at heavy weight.
  /// sub: Azahar Black 800. note: Azahar demi 400 (Hail Elastic stretches letters). Body/explanation: Azahar demi 400/600.
  static TextStyle _role(
    TextStyle? base, {
    bool heading = false,
    bool sub = false,
    bool note = false,
  }) {
    final b = base ?? const TextStyle();
    if (heading) {
      return b.copyWith(
        fontFamily: displayFontFamily,
        fontFamilyFallback: const ['SufraBody', ...fontFallback],
        fontWeight: FontWeight.w900,
      );
    }
    if (sub) {
      return b.copyWith(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
        fontWeight: FontWeight.w800,
      );
    }
    return b.copyWith(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      fontWeight: FontWeight.w400,
    );
  }

  static ThemeData _base(
    ColorScheme scheme, {
    required Color accent,
    required Color onAccent,
  }) {
    final textTheme = Typography.material2021().black
        .apply(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallback,
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .copyWith(
          displayLarge: _role(
            Typography.material2021().black.displayLarge,
            heading: true,
          ),
          displayMedium: _role(
            Typography.material2021().black.displayMedium,
            heading: true,
          ),
          displaySmall: _role(
            Typography.material2021().black.displaySmall,
            heading: true,
          ),
          headlineLarge: _role(
            Typography.material2021().black.headlineLarge,
            heading: true,
          ),
          headlineMedium: _role(
            Typography.material2021().black.headlineMedium,
            heading: true,
          ),
          headlineSmall: _role(
            Typography.material2021().black.headlineSmall,
            heading: true,
          ),
          titleLarge: _role(
            Typography.material2021().black.titleLarge,
            heading: true,
          ),
          titleMedium: _role(
            Typography.material2021().black.titleMedium,
            sub: true,
          ),
          titleSmall: _role(
            Typography.material2021().black.titleSmall,
            sub: true,
          ),
          labelLarge: _role(
            Typography.material2021().black.labelLarge,
            sub: true,
          ),
          labelMedium: _role(
            Typography.material2021().black.labelMedium,
            sub: true,
          ),
          labelSmall: _role(
            Typography.material2021().black.labelSmall,
            note: true,
          ),
          bodySmall: _role(
            Typography.material2021().black.bodySmall,
            note: true,
          ),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SufraPageTransitions(),
          TargetPlatform.iOS: SufraPageTransitions(),
          TargetPlatform.linux: SufraPageTransitions(),
          TargetPlatform.macOS: SufraPageTransitions(),
          TargetPlatform.windows: SufraPageTransitions(),
        },
      ),
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      // Orange glow on hover, blue on press, for every Material ink surface
      // (chips, list tiles, icon buttons, inkwells).
      hoverColor: AppColors.orangeDeep.withValues(alpha: .16),
      highlightColor: AppColors.primaryBlue.withValues(alpha: .22),
      splashColor: AppColors.turquoise.withValues(alpha: .30),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface.withValues(alpha: .96),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: accent.withValues(alpha: .28)),
        ),
        headerBackgroundColor: accent.withValues(alpha: .12),
        headerForegroundColor: scheme.onSurface,
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: TextStyle(
          fontFamily: displayFontFamily,
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          height: 1.65,
          color: scheme.onSurface,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: scheme.brightness == Brightness.dark
                  ? AppColors.cyanLight
                  : AppColors.primaryBlue,
              backgroundColor: accent.withValues(alpha: .08),
              minimumSize: const Size(48, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              side: BorderSide(color: accent.withValues(alpha: .3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ).copyWith(
              backgroundBuilder: (context, states, child) =>
                  SufraButtonResponse(
                    pressed:
                        states.contains(WidgetState.pressed) &&
                        !states.contains(WidgetState.disabled),
                    hovered:
                        states.contains(WidgetState.hovered) &&
                        !states.contains(WidgetState.disabled),
                    child: child ?? const SizedBox(),
                  ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: scheme.brightness == Brightness.dark
                  ? AppColors.cyanLight
                  : AppColors.primaryBlue,
              backgroundColor: accent.withValues(alpha: .07),
              minimumSize: const Size(48, 44),
              side: BorderSide(color: accent.withValues(alpha: .5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w700,
              ),
            ).copyWith(
              backgroundBuilder: (context, states, child) =>
                  SufraButtonResponse(
                    pressed:
                        states.contains(WidgetState.pressed) &&
                        !states.contains(WidgetState.disabled),
                    hovered:
                        states.contains(WidgetState.hovered) &&
                        !states.contains(WidgetState.disabled),
                    child: GlassHighlight(
                      showBorder: false,
                      child: child ?? const SizedBox(),
                    ),
                  ),
            ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              minimumSize: const Size(48, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w700,
              ),
            ).copyWith(
              backgroundBuilder: (context, states, child) =>
                  SufraButtonResponse(
                    pressed:
                        states.contains(WidgetState.pressed) &&
                        !states.contains(WidgetState.disabled),
                    hovered:
                        states.contains(WidgetState.hovered) &&
                        !states.contains(WidgetState.disabled),
                    child: GlassHighlight(
                      showBorder: false,
                      child: child ?? const SizedBox(),
                    ),
                  ),
            ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              minimumSize: const Size(48, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w700,
              ),
            ).copyWith(
              backgroundBuilder: (context, states, child) =>
                  SufraButtonResponse(
                    pressed:
                        states.contains(WidgetState.pressed) &&
                        !states.contains(WidgetState.disabled),
                    hovered:
                        states.contains(WidgetState.hovered) &&
                        !states.contains(WidgetState.disabled),
                    child: GlassHighlight(
                      showBorder: false,
                      child: child ?? const SizedBox(),
                    ),
                  ),
            ),
      ),
      extensions: [SufraAccentColors(accent: accent, onAccent: onAccent)],
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surface,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: scheme.onSurface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.brightness == Brightness.dark
            ? const Color(0x14FFFFFF)
            : const Color(0x0A14213B),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: scheme.brightness == Brightness.dark
              ? AppColors.textMuted
              : AppColors.lightTextMuted,
          fontSize: 15,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: scheme.brightness == Brightness.dark
                ? const Color(0x33FFFFFF)
                : const Color(0x3314213B),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: scheme.brightness == Brightness.dark
                ? const Color(0x33FFFFFF)
                : const Color(0x3314213B),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}

/// Text style helpers matching the design's typography roles.
extension SufraTextStyles on BuildContext {
  /// Reem Kufi display style used for brand titles and numbers.
  TextStyle displayStyle({double size = 30, Color? color}) => TextStyle(
    fontFamily: Localizations.localeOf(this).languageCode == 'ar'
        ? AppTheme.displayFontFamily
        : 'SufraLatinDisplay',
    fontFamilyFallback: const [
      'SufraDisplay',
      'SufraBody',
      ...AppTheme.fontFallback,
    ],
    // Bebas Neue (EN) is a single heavy weight; Azahar Display Black (AR) w900.
    fontWeight: Localizations.localeOf(this).languageCode == 'ar'
        ? FontWeight.w900
        : FontWeight.w400,
    fontSize: size,
    color: color ?? Theme.of(this).colorScheme.onSurface,
  );

  /// Scoped Arabic shaping correction for verified affected destinations.
  TextStyle readableDisplayStyle({double size = 30, Color? color}) =>
      displayStyle(size: size, color: color);

  /// Calligraphy accent (accent words, blessings): Aref Ruqaa Bold (AR),
  /// Hello Valentina (EN script).
  TextStyle accentStyle({double size = 18, Color? color}) => TextStyle(
    fontFamily: Localizations.localeOf(this).languageCode == 'ar'
        ? 'SufraCalligraphy'
        : 'SufraLatinScript',
    fontFamilyFallback: const ['SufraBody', ...AppTheme.fontFallback],
    fontWeight: FontWeight.w700,
    fontSize: size,
    color: color ?? Theme.of(this).colorScheme.onSurface,
  );

  /// Short decorative badge/label: Lift swash (AR) / Ethnocentric (EN).
  TextStyle badgeStyle({double size = 12, Color? color}) {
    final ar = Localizations.localeOf(this).languageCode == 'ar';
    return TextStyle(
      fontFamily: ar ? 'SufraSwash' : 'SufraLatinDisplay',
      fontFamilyFallback: const ['SufraBody', ...AppTheme.fontFallback],
      fontWeight: ar ? FontWeight.w800 : FontWeight.w600,
      fontSize: ar ? size + 2 : size - 2,
      color: color,
    );
  }

  /// Short greeting: Hail Elastic Light (AR) / Hello Valentina (EN).
  TextStyle greetingStyle({double size = 13, Color? color}) {
    final ar = Localizations.localeOf(this).languageCode == 'ar';
    return TextStyle(
      fontFamily: ar ? 'SufraLight' : 'SufraLatinScript',
      fontFamilyFallback: const ['SufraBody', ...AppTheme.fontFallback],
      fontWeight: ar ? FontWeight.w300 : FontWeight.w400,
      fontSize: size,
      color: color,
    );
  }

  /// Big hero numbers: Akira Expanded (EN) / Azahar Display (AR).
  TextStyle heroNumberStyle({double size = 40, Color? color}) {
    final ar = Localizations.localeOf(this).languageCode == 'ar';
    return TextStyle(
      fontFamily: ar ? AppTheme.displayFontFamily : 'SufraLatinDisplay',
      fontFamilyFallback: const ['SufraBody', ...AppTheme.fontFallback],
      fontWeight: ar ? FontWeight.w900 : FontWeight.w800,
      fontSize: ar ? size : size * .72,
      color: color ?? Theme.of(this).colorScheme.onSurface,
    );
  }

  /// Buttons and tabs: Azahar Black 800.
  TextStyle buttonStyle({double size = 15, Color? color}) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontFamilyFallback: AppTheme.fontFallback,
    fontWeight: FontWeight.w800,
    fontSize: size,
    color: color,
  );

  /// Notes, hints, captions: Aref Ruqaa (AR) / Baltime (EN), a notch larger for legibility.
  TextStyle mutedStyle({double size = 13, Color? color}) {
    final ar = Localizations.localeOf(this).languageCode == 'ar';
    return TextStyle(
      fontFamily: ar ? 'SufraCalligraphy' : 'SufraLatinScript',
      fontFamilyFallback: const ['SufraBody', ...AppTheme.fontFallback],
      fontWeight: FontWeight.w400,
      fontSize: ar ? size + 1 : size + 2,
      color:
          color ??
          (Theme.of(this).brightness == Brightness.dark
              ? AppColors.textMuted
              : AppColors.lightTextMuted),
    );
  }

  /// Explanations, clarifications and disclaimers: Azahar demi (AR) / Aref Ruqaa Bold (EN).
  TextStyle explainStyle({double size = 13, Color? color}) {
    final ar = Localizations.localeOf(this).languageCode == 'ar';
    return TextStyle(
      fontFamily: ar ? 'SufraBody' : 'SufraCalligraphy',
      fontFamilyFallback: const ['SufraBody', ...AppTheme.fontFallback],
      fontWeight: ar ? FontWeight.w600 : FontWeight.w700,
      fontSize: size,
      height: 1.6,
      color: color,
    );
  }

  /// Sufra's own messages to the user (coach replies, tips): Aref Ruqaa.
  TextStyle messageStyle({double size = 14, Color? color}) {
    final ar = Localizations.localeOf(this).languageCode == 'ar';
    return TextStyle(
      fontFamily: 'SufraCalligraphy',
      fontFamilyFallback: const ['SufraBody', ...AppTheme.fontFallback],
      fontWeight: ar ? FontWeight.w700 : FontWeight.w400,
      fontSize: size + 1,
      height: 1.7,
      color: color,
    );
  }
}

/// A short directional fade/slide for pushed pages; no transform when reduced.
class SufraPageTransitions extends PageTransitionsBuilder {
  const SufraPageTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    final direction = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: curved.drive(
          Tween(begin: Offset(.035 * direction, 0), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}
