import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final scale in [1.0, 1.6]) {
      for (final dark in [false, true]) {
        testWidgets('Integrated navigation capture $lang $scale $dark', (
          t,
        ) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(t.view.reset);
          final h = await Harness.signedIn();
          final key = GlobalKey();
          await t.runAsync(() async {
            await t.pumpWidget(
              RepaintBoundary(
                key: key,
                child: h.wrap(
                  const HomeScreen(),
                  locale: Locale(lang),
                  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
            );
            await Future<void>.delayed(const Duration(milliseconds: 200));
          });
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
          await mouse.addPointer(location: const Offset(2, 2));
          Future<void> snap(int n) async {
            await t.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final b = await im.toByteData(format: ui.ImageByteFormat.png);
              await File(
                '/downloads/sufra-recovered/nav1638_${lang}_${scale}_${dark ? 'dark' : 'light'}_${n.toString().padLeft(3, '0')}.png',
              ).writeAsBytes(b!.buffer.asUint8List());
              im.dispose();
            });
          }

          final motionCase = lang == 'ar' && scale == 1.0;
          for (var n = 0; n < (motionCase ? 48 : 1); n++) {
            if (n == 8) await mouse.moveTo(t.getCenter(find.byIcon(Icons.add)));
            if (n == 18) await mouse.down(t.getCenter(find.byIcon(Icons.add)));
            if (n == 35) await mouse.cancel();
            if (n == 36) {
              await mouse.moveTo(
                t.getCenter(find.text(lang == 'ar' ? 'اليومية' : 'Diary')),
              );
            }
            await t.pump(const Duration(milliseconds: 67));
            await snap(n);
          }
          await mouse.removePointer();
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
          await h.dispose();
        });
      }
    }
  }
}
