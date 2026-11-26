import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/onboarding/presentation/onboarding_screen.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  testWidgets('settled three onboarding reference-size pages', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = await Harness.signedIn();
    final k = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: k,
        child: h.wrap(
          Builder(
            builder: (c) => MediaQuery(
              data: MediaQuery.of(c).copyWith(disableAnimations: true),
              child: OnboardingScreen(preferences: h.preferences),
            ),
          ),
        ),
      ),
    );
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await t.pump(const Duration(seconds: 2));
    for (var i = 0; i < 3; i++) {
      await t.runAsync(() async {
        for (var n = 1; n <= 3; n++) {
          await precacheImage(
            AssetImage('assets/images/art/w$n.webp'),
            t.element(find.byType(OnboardingScreen)),
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
      final dir = Platform.environment['SUFRA_FOOD_CAPTURE'];
      if (dir != null) {
        await t.runAsync(() async {
          final im =
              await (k.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$dir/onboarding_$i.png',
          ).writeAsBytes(b!.buffer.asUint8List());
          im.dispose();
        });
      }
      if (i < 2) {
        await t.tap(find.text('التالي'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
      }
    }
    await t.pumpWidget(const SizedBox());
    await h.dispose();
  });
}
