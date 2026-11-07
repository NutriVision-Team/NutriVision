import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// الخلفية المشتركة لكل الشاشات (الموجات الملونة)
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.bgDark),
        Image.asset('assets/images/bg.png', fit: BoxFit.cover),
        child,
      ],
    );
  }
}