import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bgDark = Color(0xFF050B1F);
  static const orange = Color(0xFFFF9800);
  static const cyan = Color(0xFF38D6F5);
  static const textSoft = Color(0xFFB8C0D9);
  static const glass = Color(0x26FFFFFF);
  static const glassBorder = Color(0x40FFFFFF);
}

class AppText {
  /// للعناوين
  static TextStyle title(double size, {Color color = Colors.white}) =>
      GoogleFonts.lalezar(fontSize: size, color: color, height: 1.3);

  /// للنصوص العادية
  static TextStyle body(double size,
      {Color color = Colors.white, FontWeight? weight}) =>
      GoogleFonts.cairo(
          fontSize: size, color: color, fontWeight: weight, height: 1.5);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
  );
}