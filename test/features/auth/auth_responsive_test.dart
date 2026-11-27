import 'package:sufradepi/core/widgets/app_buttons.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/auth/presentation/screens/login_screen.dart';
import 'package:sufradepi/features/auth/presentation/screens/register_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  testWidgets('normal registration CTA is disabled until explicit consent', (
    t,
  ) async {
    final h = await Harness.signedOut();
    await t.pumpWidget(h.wrap(const RegisterScreen()));
    await t.pump(const Duration(seconds: 1));
    final button = find.byType(IconPillButton);
    expect(t.widget<IconPillButton>(button).onPressed, isNull);
    final checkbox = find.byType(CheckboxListTile);
    await t.ensureVisible(checkbox);
    await t.tap(checkbox);
    await t.pump();
    expect(t.widget<IconPillButton>(button).onPressed, isNotNull);
    await t.tap(checkbox);
    await t.pump();
    expect(t.widget<IconPillButton>(button).onPressed, isNull);
    await t.pumpWidget(const SizedBox.shrink());
    await h.dispose();
  });
  for (final language in ['ar', 'en']) {
    for (final register in [false, true]) {
      for (final light in [false, true]) {
        testWidgets(
          'auth $language ${register ? 'register' : 'login'} ${light ? 'light' : 'dark'} 320px 2x no overflow',
          (t) async {
            t.view.devicePixelRatio = 1;
            t.view.physicalSize = const Size(320, 640);
            t.platformDispatcher.textScaleFactorTestValue = 2;
            addTearDown(() {
              t.view.resetPhysicalSize();
              t.view.resetDevicePixelRatio();
              t.platformDispatcher.clearTextScaleFactorTestValue();
            });
            final h = await Harness.signedOut();
            await t.pumpWidget(
              RepaintBoundary(
                key: const ValueKey('auth-shot'),
                child: h.wrap(
                  register ? const RegisterScreen() : const LoginScreen(),
                  locale: Locale(language),
                  themeMode: light ? ThemeMode.light : ThemeMode.dark,
                ),
              ),
            );
            await t.pump(const Duration(seconds: 1));
            expect(t.takeException(), isNull);
            await t.drag(
              find.byType(SingleChildScrollView).first,
              const Offset(0, -2000),
            );
            await t.pump();
            expect(t.takeException(), isNull);
            if (register) {
              final checkbox = find.byType(CheckboxListTile);
              expect(t.widget<CheckboxListTile>(checkbox).value, isFalse);
              expect(
                t.widget<GradientButton>(find.byType(GradientButton)).onPressed,
                isNull,
              );
              await t.ensureVisible(checkbox);
              await t.tap(checkbox);
              await t.pump();
              expect(t.widget<CheckboxListTile>(checkbox).value, isTrue);
              expect(
                t.widget<GradientButton>(find.byType(GradientButton)).onPressed,
                isNotNull,
              );
              await t.tap(checkbox);
              await t.pump();
              expect(
                t.widget<GradientButton>(find.byType(GradientButton)).onPressed,
                isNull,
              );
              await t.drag(
                find.byType(SingleChildScrollView).first,
                const Offset(0, -2000),
              );
              await t.pump();
            }
            final pixel = Platform.environment['SUFRA_AUTH_PIXEL'];
            if (pixel != null) {
              final b = t.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('auth-shot')),
              );
              await t.runAsync(() async {
                final image = await b.toImage();
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                File(
                  '$pixel-$language-${register ? 'register' : 'login'}-${light ? 'light' : 'dark'}.png',
                ).writeAsBytesSync(data!.buffer.asUint8List());
                image.dispose();
              });
            }
            await t.pumpWidget(const SizedBox.shrink());
            await h.dispose();
          },
        );
      }
    }
  }
}
