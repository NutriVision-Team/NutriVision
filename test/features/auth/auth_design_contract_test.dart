import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/app_buttons.dart';
import 'package:sufradepi/core/widgets/sprite_avatar.dart';
import 'package:sufradepi/features/auth/presentation/screens/login_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final registration in [false, true]) {
    testWidgets('auth original artwork crop contract register=$registration', (
      t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthPlateArt(size: 270, registration: registration),
          ),
        ),
      );
      final plates = t
          .widgetList<SpriteAvatar>(find.byType(SpriteAvatar))
          .toList();
      expect(plates.length, 4);
      expect(
        plates.every((p) => p.asset == 'assets/images/art/spA.webp'),
        isTrue,
      );
      expect((
        plates.first.col,
        plates.first.row,
      ), registration ? (3, 0) : (0, 0));
      expect(find.byType(GoogleProviderBadge), findsNothing);
      await t.pumpWidget(const SizedBox.shrink());
    });
  }
  for (final direction in [TextDirection.rtl, TextDirection.ltr]) {
    testWidgets(
      'auth CTA icon position/direction $direction does not double mirror',
      (t) async {
        await t.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                body: Center(
                  child: IconPillButton(label: 'Continue', onPressed: () {}),
                ),
              ),
            ),
          ),
        );
        final icon = t.widget<Icon>(find.byType(Icon));
        expect(icon.textDirection, TextDirection.ltr);
        expect(
          icon.icon,
          direction == TextDirection.rtl
              ? Icons.chevron_left_rounded
              : Icons.chevron_right_rounded,
        );
        final label = t.getCenter(find.text('Continue'));
        final arrow = t.getCenter(find.byType(Icon));
        expect(arrow.dx < label.dx, direction == TextDirection.rtl);
      },
    );
  }
  testWidgets('login artwork has actual270pxreference height', (t) async {
    final h = await Harness.signedOut();
    await t.pumpWidget(h.wrap(const LoginScreen()));
    expect(t.widget<AuthPlateArt>(find.byType(AuthPlateArt)).size, 270);
    await t.pumpWidget(const SizedBox.shrink());
    await h.dispose();
  });
}
