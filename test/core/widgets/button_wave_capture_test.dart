import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/app_buttons.dart';
import 'package:sufradepi/core/widgets/nebula_background.dart';
import 'package:sufradepi/core/widgets/sufra_button_response.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  testWidgets('actual primary orange hover and blue flowing press', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    var taps = 0;
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: Scaffold(
            body: NebulaBackground(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sufra',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 28),
                    GradientButton(
                      label: 'Review your meal',
                      onPressed: () => taps++,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => taps++,
                      child: const Text('Explore alternatives'),
                    ),
                    const SizedBox(height: 20),
                    IconPillButton(label: 'Continue', onPressed: () => taps++),
                    const SizedBox(height: 20),
                    GlassPillButton(
                      label: 'Another option',
                      onPressed: () => taps++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 1));
    final dir = Directory('/downloads/sufra/verification/button_motion0659')
      ..createSync(recursive: true);
    var i = 0;
    Future<void> frame() async {
      await t.runAsync(() async {
        final im =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final b = await im.toByteData(format: ui.ImageByteFormat.png);
        im.dispose();
        await File(
          '${dir.path}/frame_${(i++).toString().padLeft(3, '0')}.png',
        ).writeAsBytes(b!.buffer.asUint8List());
      });
    }

    for (var n = 0; n < 8; n++) {
      await frame();
      await t.pump(const Duration(milliseconds: 50));
    }
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(t.getCenter(find.byType(GradientButton)));
    await t.pump(const Duration(milliseconds: 400));
    expect(
      t
          .widget<SufraButtonResponse>(find.byType(SufraButtonResponse).first)
          .hovered,
      isTrue,
    );
    for (var n = 0; n < 10; n++) {
      await frame();
      await t.pump(const Duration(milliseconds: 50));
    }
    final touch = await t.startGesture(
      t.getCenter(find.byType(GradientButton)),
    );
    await t.pump(const Duration(milliseconds: 250));
    expect(
      t
          .widget<SufraButtonResponse>(find.byType(SufraButtonResponse).first)
          .pressed,
      isTrue,
    );
    for (var n = 0; n < 25; n++) {
      await frame();
      await t.pump(const Duration(milliseconds: 50));
    }
    await touch.up();
    await mouse.moveTo(const Offset(1, 1));
    await t.pump(const Duration(milliseconds: 400));
    expect(taps, 1);
    for (var n = 0; n < 8; n++) {
      await frame();
      await t.pump(const Duration(milliseconds: 50));
    }
    await mouse.removePointer();
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
