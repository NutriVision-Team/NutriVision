import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/sufra_button_response.dart';

void main() {
  for (final reduce in [true, false]) {
    testWidgets(
      'press response ${reduce ? 'reduced static' : 'flowing'} and idle static',
      (t) async {
        final key = GlobalKey();
        Widget app(bool pressed) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 200,
                  height: 56,
                  child: SufraButtonResponse(
                    pressed: pressed,
                    hovered: false,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );
        Future<Uint8List> pixels() async {
          late Uint8List bytes;
          await t.runAsync(() async {
            final im =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final d = await im.toByteData(format: ui.ImageByteFormat.rawRgba);
            bytes = d!.buffer.asUint8List();
            im.dispose();
          });
          return bytes;
        }

        await t.pumpWidget(app(true));
        await t.pump(const Duration(milliseconds: 100));
        final a = await pixels();
        await t.pump(const Duration(milliseconds: 300));
        final b = await pixels();
        expect(listEquals(a, b), reduce);
        await t.pumpWidget(app(false));
        await t.pump();
        final c = await pixels();
        await t.pump(const Duration(milliseconds: 300));
        final d = await pixels();
        expect(listEquals(c, d), true);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}

bool listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
