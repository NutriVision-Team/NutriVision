import 'package:flutter/material.dart';

/// Central Sufra color tokens extracted from the design reference.
/// Never scatter literal colors across screen files; use these tokens.
abstract final class AppColors {
  // Brand
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color aiPurple = Color(0xFF7C3AED);
  static const Color turquoise = Color(0xFF06B6D4);
  static const Color copper = Color(0xFFFB8C00);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0A1022);
  static const Color darkSurface = Color(0xFF111A33);
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textMuted = Color(0xFFB6C2DD);

  // Accent shades used across the design
  static const Color cyanLight = Color(0xFF67E8F9);
  static const Color orangeLight = Color(0xFFFDBA74);
  static const Color greenLight = Color(0xFF4ADE80);
  static const Color purpleLight = Color(0xFFA78BFA);
  static const Color pinkLight = Color(0xFFFB7185);
  static const Color gold = Color(0xFFF8D58A);
  static const Color goldDeep = Color(0xFFB9812B);
  static const Color orangeDeep = Color(0xFFEA580C);
  static const Color blueDeep = Color(0xFF0D47A1);

  // Macro nutrients
  static const Color macroProtein = turquoise;
  static const Color macroCarbs = copper;
  static const Color macroFat = aiPurple;

  // Light theme
  static const Color lightBackground = Color(0xFFF6F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF14213B);
  static const Color lightTextMuted = Color(0xFF5B6B8C);

  // Common glass decorations (dark)
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x21FFFFFF), Color(0x0AFFFFFF)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, turquoise],
  );

  static const LinearGradient copperGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [copper, orangeDeep],
  );

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [aiPurple, turquoise],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, goldDeep],
  );
}
