import 'package:flutter/material.dart';
import 'package:sufradepi/core/widgets/interactive_food_bowl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/auth/presentation/screens/login_screen.dart';
import 'package:sufradepi/features/auth/presentation/screens/welcome_screen.dart';
import 'package:sufradepi/features/progress/presentation/widgets/water_glass.dart';
import '../goldens/milestone1_screens_test.dart' show Harness;

void main() {
  for (final (label, screen) in <(String, Widget)>[
    ('bowl', const Center(child: InteractiveFoodBowl())),
    ('login', const LoginScreen()),
    ('welcome', const WelcomeScreen()),
    (
      'water',
      const Center(
        child: SizedBox(width: 200, child: WaterGlass(fraction: .5)),
      ),
    ),
  ]) {
    testWidgets('$label dynamically pauses and resumes reduced motion', (
      t,
    ) async {
      final h = await Harness.signedOut();
      final reduce = ValueNotifier(true);
      addTearDown(reduce.dispose);
      await t.pumpWidget(
        h.wrap(
          ValueListenableBuilder<bool>(
            valueListenable: reduce,
            builder: (c, value, _) => MediaQuery(
              data: MediaQuery.of(c).copyWith(disableAnimations: value),
              child: screen,
            ),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 2));
      await t.pump(const Duration(seconds: 2));
      expect(t.binding.transientCallbackCount, 0);
      reduce.value = false;
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(t.binding.transientCallbackCount, greaterThan(0));
      reduce.value = true;
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(t.binding.transientCallbackCount, 0);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await h.dispose();
    });
  }
}
