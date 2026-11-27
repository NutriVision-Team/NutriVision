import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/auth/presentation/screens/login_screen.dart';
import 'package:sufradepi/features/auth/presentation/screens/register_screen.dart';
import 'package:sufradepi/features/auth/presentation/screens/welcome_screen.dart';
import 'package:sufradepi/features/dashboard/presentation/destination_hubs.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import 'package:sufradepi/features/diary/presentation/screens/diary_screen.dart';

import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

/// Main screens inside the real app shell at tablet width: they fill the
/// width, show the background, and render without layout errors.
void main() {
  setUpAll(loadRealFonts);

  final screens = <String, (bool, Widget Function())>{
    'home': (true, () => HomeScreen(clock: () => DateTime(2026, 11, 22, 18))),
    'diary': (true, () => DiaryScreen(initialDate: DateTime(2026, 11, 22))),
    'profile': (true, () => const ProfileHubScreen()),
    'meals': (true, () => const MealsHubScreen()),
    'welcome': (true, () => const WelcomeScreen()),
    'login': (false, () => const LoginScreen()),
    'register': (false, () => const RegisterScreen()),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} at 800 wide in the app shell', (t) async {
      t.view.physicalSize = const Size(800, 1280);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = entry.value.$1
          ? await Harness.signedIn()
          : await Harness.signedOut();
      final key = GlobalKey();
      await t.runAsync(() async {
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: h.wrap(entry.value.$2(), appShell: true),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 350));
        final context = t.element(find.byType(Scaffold).first);
        for (final a in const [
          'assets/images/art/neb.jpg',
          'assets/images/art/spA.webp',
        ]) {
          await precacheImage(AssetImage(a), context);
        }
      });
      await t.pump(const Duration(seconds: 2));
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      late ui.Image image;
      late ByteData bytes;
      await t.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        image = await boundary.toImage();
        bytes = (await image.toByteData())!;
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          'build/test_evidence/wide_${entry.key}_800x1280.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
      });
      var vivid = 0;
      for (var y = 0; y < image.height; y += 40) {
        for (var x = 0; x < 24; x += 6) {
          final i = (y * image.width + x) * 4;
          if ((bytes.getUint8(i) - 0x0A).abs() +
                  (bytes.getUint8(i + 1) - 0x10).abs() +
                  (bytes.getUint8(i + 2) - 0x22).abs() >
              40) {
            vivid++;
          }
        }
      }
      expect(vivid, greaterThan(3), reason: 'background visible');
      await t.pumpWidget(const SizedBox());
      await h.dispose();
    });
  }
}
