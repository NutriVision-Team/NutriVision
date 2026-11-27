import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/config/app_preferences.dart';
import 'package:sufradepi/core/theme/theme_cubit.dart';
import 'package:sufradepi/core/widgets/journey_theme_control.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/auth/presentation/cubit/session_cubit.dart';
import 'package:sufradepi/features/auth/presentation/screens/welcome_screen.dart';
import 'package:sufradepi/features/nutrition_plan/presentation/plan_screen.dart';
import 'package:sufradepi/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/services/auth_service.dart';
import '../../goldens/milestone1_screens_test.dart'
    show FakeUserRepository, FakeNutritionRepository, loadRealFonts;

void main() {
  ThemeCubit? reviewTheme;
  setUp(() async {
    if (Platform.environment['SUFRA_THEME_REVIEW'] == '1') {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      reviewTheme = ThemeCubit(await AppPreferences.load());
    }
  });
  tearDown(() async {
    await reviewTheme?.close();
    reviewTheme = null;
  });
  setUpAll(() async {
    await loadRealFonts();
  });
  for (final lang in ['ar', 'en']) {
    testWidgets('welcome $lang 320x640 2x keeps setup CTA reachable', (
      t,
    ) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Platform.environment['SUFRA_NORMAL_REVIEW'] == '1'
          ? const Size(390, 844)
          : const Size(320, 640);
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
      final session = SessionCubit(
        authService: AuthService.withAuth(MockFirebaseAuth()),
        userRepository: FakeUserRepository(),
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => reviewTheme == null
                ? const WelcomeScreen()
                : BlocProvider.value(
                    value: reviewTheme!,
                    child: const JourneyThemeControl(child: WelcomeScreen()),
                  ),
          ),
          GoRoute(
            path: '/setup',
            builder: (_, _) => const Scaffold(body: Text('setup destination')),
          ),
        ],
      );
      await t.pumpWidget(
        BlocProvider.value(
          value: session,
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.dark(),
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(
                textScaler: TextScaler.linear(
                  Platform.environment['SUFRA_NORMAL_REVIEW'] == '1' ? 1 : 2,
                ),
                disableAnimations: true,
              ),
              child: RepaintBoundary(
                key: const ValueKey('welcome-capture'),
                child: child!,
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 3));
      await t.runAsync(() async {
        final context = t.element(find.byType(Scaffold).first);
        for (final asset in [
          'assets/images/art/hero_art.webp',
          'assets/images/art/neb.jpg',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await t.pump();
      expect(t.takeException(), isNull);
      final l = await AppLocalizations.delegate.load(Locale(lang));
      await t.ensureVisible(find.text(l.welcomeCta));
      await t.pump();
      expect(t.takeException(), isNull);
      final path = Platform.environment['SUFRA_WELCOME_PIXEL'];
      if (path != null) {
        final boundary = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('welcome-capture')),
        );
        await t.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$path-$lang.png').writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await t.tap(find.text(l.welcomeCta));
      await t.pumpAndSettle();
      expect(find.text('setup destination'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await session.close();
    });
    testWidgets('plan $lang 320x640 2x keeps home CTA reachable', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Platform.environment['SUFRA_NORMAL_REVIEW'] == '1'
          ? const Size(390, 844)
          : const Size(320, 640);
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
      final session = SessionCubit(
        authService: AuthService.withAuth(
          MockFirebaseAuth(mockUser: MockUser(uid: 'u1'), signedIn: true),
        ),
        userRepository: FakeUserRepository(),
      );
      final setup = ProfileSetupCubit(
        nutritionRepository: FakeNutritionRepository(),
        userRepository: FakeUserRepository(),
      );
      setup.update(
        ProfileSetupData(
          nutritionGoal: 'lose',
          gender: 'male',
          dateOfBirth: DateTime(2000, 8, 7),
          heightCm: 175,
          currentWeightKg: 90,
          targetWeightKg: 80,
          activityLevel: 'moderate',
        ),
      );
      while (setup.state.step < 6) {
        setup.next();
      }
      await t.runAsync(() => setup.finish('u1'));
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => reviewTheme == null
                ? const PlanScreen()
                : BlocProvider.value(
                    value: reviewTheme!,
                    child: const JourneyThemeControl(child: PlanScreen()),
                  ),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('home destination')),
          ),
        ],
      );
      await t.pumpWidget(
        BlocProvider.value(
          value: session,
          child: BlocProvider.value(
            value: setup,
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.dark(),
              locale: Locale(lang),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c).copyWith(
                  textScaler: TextScaler.linear(
                    Platform.environment['SUFRA_NORMAL_REVIEW'] == '1' ? 1 : 2,
                  ),
                  disableAnimations: true,
                ),
                child: RepaintBoundary(
                  key: const ValueKey('welcome-capture'),
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 3));
      await t.runAsync(() async {
        final context = t.element(find.byType(Scaffold).first);
        for (final asset in [
          'assets/images/art/hero_art.webp',
          'assets/images/art/neb.jpg',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await t.pump();
      expect(t.takeException(), isNull);
      final l = await AppLocalizations.delegate.load(Locale(lang));
      await t.ensureVisible(find.text(l.planCta));
      await t.pump();
      expect(t.takeException(), isNull);
      final path = Platform.environment['SUFRA_PLAN_PIXEL'];
      if (path != null) {
        final boundary = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('welcome-capture')),
        );
        await t.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$path-$lang.png').writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await t.tap(find.text(l.planCta));
      await t.pumpAndSettle();
      expect(find.text('home destination'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await session.close();
      await setup.close();
    });
  }
}
