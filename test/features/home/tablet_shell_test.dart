import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';

import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

/// Renders Home inside the real app shell (background host plus responsive
/// frame) on phone, tablet and desktop widths and checks the background is
/// painted across the whole viewport, not only inside a narrow column.
void main() {
  setUpAll(loadRealFonts);

  for (final size in const [Size(390, 844), Size(800, 1280), Size(1280, 800)]) {
    testWidgets('Home fills ${size.width.toInt()}x${size.height.toInt()}', (
      t,
    ) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await Harness.signedIn();
      final key = GlobalKey();
      await t.runAsync(() async {
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: h.wrap(
              HomeScreen(clock: () => DateTime(2026, 11, 22, 18)),
              appShell: true,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 350));
        await precacheImage(
          const AssetImage('assets/images/art/spA.webp'),
          t.element(find.byType(HomeScreen)),
        );
        await precacheImage(
          const AssetImage('assets/images/art/neb.jpg'),
          t.element(find.byType(HomeScreen)),
        );
      });
      await t.pump(const Duration(seconds: 2));
      await t.pump(const Duration(seconds: 1));

      final home = t.getRect(find.byType(HomeScreen));
      expect(home.width, lessThanOrEqualTo(960));
      if (size.width <= 960) expect(home.width, size.width);

      late ui.Image image;
      late ByteData bytes;
      await t.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        image = await boundary.toImage();
        bytes = (await image.toByteData())!;
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          'build/test_evidence/tablet_shell_${size.width.toInt()}x${size.height.toInt()}.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
      });
      // The nebula photo is vivid: sampled pixels in the outer margin (or the
      // screen edge on phones) must not all equal the flat base colour.
      var vivid = 0;
      for (var y = 0; y < image.height; y += 40) {
        for (var x = 0; x < 24; x += 6) {
          final i = (y * image.width + x) * 4;
          final r = bytes.getUint8(i);
          final g = bytes.getUint8(i + 1);
          final b = bytes.getUint8(i + 2);
          if ((r - 0x0A).abs() + (g - 0x10).abs() + (b - 0x22).abs() > 40) {
            vivid++;
          }
        }
      }
      expect(vivid, greaterThan(3), reason: 'nebula visible at the left edge');
      await t.pumpWidget(const SizedBox());
      await h.dispose();
    });
  }
}
