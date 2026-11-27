import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/app_buttons.dart';
import 'package:sufradepi/core/widgets/sufra_button_response.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  testWidgets('pill hover and press preserve one action', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    var taps = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconPillButton(label: 'Continue', onPressed: () => taps++),
                  const SizedBox(height: 24),
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
    );
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    for (final type in [IconPillButton, GlassPillButton]) {
      final target = find.byType(type);
      await mouse.moveTo(t.getCenter(target));
      await t.pump();
      final response = find.descendant(
        of: target,
        matching: find.byType(SufraButtonResponse),
      );
      expect(t.widget<SufraButtonResponse>(response).hovered, true);
      final touch = await t.startGesture(t.getCenter(target));
      await t.pump(const Duration(milliseconds: 200));
      expect(t.widget<SufraButtonResponse>(response).pressed, true);
      await t.runAsync(() async {
        final im =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final b = await im.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/downloads/sufra/verification/pill_${type}_pressed.png',
        ).writeAsBytes(b!.buffer.asUint8List());
        im.dispose();
      });
      await touch.up();
      await mouse.moveTo(const Offset(1, 1));
      await t.pump();
    }
    expect(taps, 2);
    expect(t.takeException(), isNull);
    await mouse.removePointer();
    await t.pumpWidget(const SizedBox());
  });
}
