import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final language in ['ar', 'en']) {
    for (final size in [const Size(320, 740), const Size(390, 844)]) {
      testWidgets('Home $language remains usable at $size with2xtext', (
        tester,
      ) async {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final h = await Harness.signedIn();
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: h.wrap(
              HomeScreen(clock: () => DateTime(2026, 11, 22, 18)),
              locale: Locale(language),
            ),
          ),
        );
        await tester.runAsync(() async {
          await precacheImage(
            const AssetImage('assets/images/art/neb.jpg'),
            tester.element(find.byType(HomeScreen)),
          );
          await precacheImage(
            const AssetImage('assets/images/sufra_logo.webp'),
            tester.element(find.byType(HomeScreen)),
          );
        });
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);

        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 1.5);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra/verification/home_${language}_large_${size.width.toInt()}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
        for (var i = 0; i < 5; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -500));
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await h.dispose();
      });
    }
  }
}
