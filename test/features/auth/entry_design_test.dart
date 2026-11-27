import 'dart:io';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/auth/presentation/screens/login_screen.dart';
import 'package:sufradepi/features/auth/presentation/screens/register_screen.dart';
import 'package:sufradepi/features/auth/presentation/screens/welcome_screen.dart';
import 'package:sufradepi/features/onboarding/presentation/onboarding_screen.dart';
import 'package:sufradepi/features/nutrition_plan/presentation/plan_screen.dart';
import 'package:sufradepi/features/profile_setup/presentation/screens/profile_setup_screen.dart';
import 'package:sufradepi/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final light in [true, false]) {
      for (final scale in [1.0, 1.6]) {
        for (final f in [
          'login',
          'register',
          'welcome',
          'onboard',
          'setup',
          'plan',
        ]) {
          testWidgets('entry design $f $lang $light $scale', (t) async {
            t.view.physicalSize = scale > 1
                ? const Size(320, 640)
                : const Size(390, 844);
            t.view.devicePixelRatio = 1;
            addTearDown(t.view.reset);
            t.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
            final h = await Harness.signedOut(authenticated: true);
            h.setupCubit.update(
              ProfileSetupData(
                gender: 'male',
                dateOfBirth: DateTime(2000, 8, 7),
                heightCm: 175,
                currentWeightKg: 90,
                targetWeightKg: 80,
                activityLevel: 'moderate',
                nutritionGoal: 'lose',
              ),
            );
            if (f == 'plan') {
              while (h.setupCubit.state.step < 6) {
                h.setupCubit.next();
              }
              await t.runAsync(() => h.setupCubit.finish('u1'));
            }
            Widget screen = switch (f) {
              'login' => const LoginScreen(),
              'register' => const RegisterScreen(),
              'welcome' => const WelcomeScreen(),
              'onboard' => OnboardingScreen(preferences: h.preferences),
              'setup' => const ProfileSetupScreen(),
              _ => const PlanScreen(),
            };
            final key = GlobalKey();
            await t.pumpWidget(
              RepaintBoundary(
                key: key,
                child: h.wrap(
                  screen,
                  locale: Locale(lang),
                  themeMode: light ? ThemeMode.light : ThemeMode.dark,
                ),
              ),
            );
            await t.pump(const Duration(seconds: 3));
            Future<void> shot(String part) async {
              expect(t.takeException(), isNull);
              await t.runAsync(() async {
                for (final e in find.byType(Image).evaluate()) {
                  await precacheImage((e.widget as Image).image, e);
                }
              });
              await t.pump();
              await t.runAsync(() async {
                final im =
                    await (key.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage();
                final b = await im.toByteData(format: ui.ImageByteFormat.png);
                await File(
                  '/downloads/sufra-recovered/entry1830_${f}_${lang}_${light ? 'light' : 'dark'}_${scale}_$part.png',
                ).writeAsBytes(b!.buffer.asUint8List());
                im.dispose();
              });
            }

            await shot('top');
            if (f == 'onboard' && lang == 'ar' && scale == 1) {
              for (var frame = 0; frame < 24; frame++) {
                await t.pump(const Duration(milliseconds: 160));
                await shot('motion${frame.toString().padLeft(3, '0')}');
              }
            }

            if (f == 'welcome' && lang == 'ar' && scale == 1) {
              for (var frame = 0; frame < 30; frame++) {
                await t.pump(const Duration(milliseconds: 160));
                await shot('motion${frame.toString().padLeft(3, '0')}');
              }
            }
            if (f == 'setup') {
              for (var step = 1; step < 7; step++) {
                h.setupCubit.next();
                await t.pump();
                await t.pump(const Duration(milliseconds: 400));
                await shot('step$step');
              }
            }
            if (f == 'onboard') {
              final l = await AppLocalizations.delegate.load(Locale(lang));
              for (var n = 1; n <= 2; n++) {
                await t.tap(find.text(l.onboardingNext));
                await t.pump();
                await t.pump(const Duration(milliseconds: 500));
                await t.pump(const Duration(seconds: 2));
                await shot('page$n');
              }
            }
            if (f == 'onboard') {
              final target = find.byKey(
                const ValueKey('onboarding-page-2-scroll'),
              );
              await t.drag(target, const Offset(0, -1400));
              await t.pump();
              await t.pump(const Duration(milliseconds: 500));
              await shot('readable');
            } else if (find.byType(Scrollable).evaluate().isNotEmpty) {
              await t.drag(
                find.byType(Scrollable).first,
                const Offset(0, -1800),
              );
              await t.pump(const Duration(milliseconds: 400));
              await shot('scroll');
            }
            await t.pumpWidget(const SizedBox());
            await h.dispose();
          });
        }
      }
    }
  }
}
