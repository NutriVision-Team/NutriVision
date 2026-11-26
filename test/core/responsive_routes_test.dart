import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/features/health_coach/coach_access_host.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import 'package:sufradepi/features/diary/presentation/screens/diary_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_review_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_log_hub_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/food_detail_screen.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/auth/presentation/screens/login_screen.dart';
import 'package:sufradepi/features/auth/presentation/screens/register_screen.dart';
import 'package:sufradepi/features/auth/presentation/screens/welcome_screen.dart';
import 'package:sufradepi/features/onboarding/presentation/onboarding_screen.dart';
import 'package:sufradepi/features/profile_setup/presentation/screens/profile_setup_screen.dart';
import 'package:sufradepi/features/nutrition_plan/presentation/plan_screen.dart';
import 'package:sufradepi/features/premium/presentation/screens/premium_screen.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;
import '../meal_log/catalog_flow_test.dart' show catalog;

void main() {
  setUpAll(loadRealFonts);
  for (final width in [320.0, 800.0]) {
    for (final name in [
      'home',
      'diary',
      'review',
      'food',
      'log',
      'login',
      'register',
      'welcome',
      'onboarding',
      'setup',
      'plan',
      'premium',
    ]) {
      testWidgets('complete host $name $width', (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(width, width == 320 ? 844 : 1280);
        addTearDown(t.view.reset);
        final h = await Harness.signedIn();
        final screen = switch (name) {
          'home' => HomeScreen(clock: () => DateTime(2026, 11, 22)),
          'diary' => DiaryScreen(initialDate: DateTime(2026, 11, 22)),
          'review' => MealReviewScreen(portion: FoodPortion(catalog(), 150)),
          'food' => FoodDetailScreen(food: catalog()),
          'log' => const MealLogHubScreen(),
          'login' => const LoginScreen(),
          'register' => const RegisterScreen(),
          'welcome' => const WelcomeScreen(),
          'onboarding' => OnboardingScreen(preferences: h.preferences),
          'setup' => const ProfileSetupScreen(),
          'plan' => const PlanScreen(),
          _ => const PremiumScreen(),
        };
        final key = GlobalKey();
        await t.pumpWidget(
          h.wrap(
            Builder(
              builder: (c) => MediaQuery(
                data: MediaQuery.of(c).copyWith(
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 24, bottom: 32),
                  textScaler: TextScaler.linear(width == 320 ? 1.6 : 1),
                ),
                child: RepaintBoundary(
                  key: key,
                  child: CoachAccessHost(
                    router: GoRouter.of(c),
                    enabled: true,
                    child: screen,
                  ),
                ),
              ),
            ),
            locale: Locale(width == 320 ? 'en' : 'ar'),
          ),
        );
        await t.pump(const Duration(seconds: 2));
        await t.runAsync(() async {
          for (final e in find.byType(Image).evaluate()) {
            await precacheImage((e.widget as Image).image, e);
          }
        });
        await t.pump();
        expect(t.takeException(), isNull, reason: '$name width$width');
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await im.toByteData(format: ui.ImageByteFormat.png);
          File(
            'build/test_evidence/route_${name}_${width.toInt()}.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          im.dispose();
        });
        await t.pumpWidget(const SizedBox());
        await h.dispose();
      });
    }
  }
}
