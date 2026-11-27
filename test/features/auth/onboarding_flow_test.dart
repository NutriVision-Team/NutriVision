import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/config/app_preferences.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/onboarding/presentation/onboarding_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

void main() {
  for (final lang in ['ar', 'en']) {
    testWidgets('onboarding $lang 320x640 2x next pages and finish persist', (
      t,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPreferences.load();
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(320, 640);
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => OnboardingScreen(preferences: prefs),
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('login destination')),
          ),
        ],
      );
      await t.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.dark(),
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
      );
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
      final l = await AppLocalizations.delegate.load(Locale(lang));
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text(l.onboardingNext));
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        expect(t.takeException(), isNull);
      }
      await t.tap(find.text(l.onboardingStart));
      await t.pumpAndSettle();
      expect(prefs.onboardingSeen, isTrue);
      expect(find.text('login destination'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
  }
}
