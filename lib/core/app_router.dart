import 'package:flutter/material.dart';
import '../screens/onboarding_screen.dart';
import '../screens/welcome_screen.dart';
import '../services/auth_service.dart';

/// بيحدد الشاشة اللي بعد تسجيل الدخول:
/// أول مرة للحساب → Onboarding، وغير كده → الترحيب
Future<Widget> screenAfterAuth() async {
  try {
    final needs = await AuthService.instance.needsOnboarding();
    return needs ? const OnboardingScreen() : const WelcomeScreen();
  } catch (_) {
    return const WelcomeScreen();
  }
}