import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final config in [
    ('ar', ThemeMode.light, 390.0, 1.0),
    ('en', ThemeMode.light, 320.0, 2.0),
    ('ar', ThemeMode.dark, 320.0, 2.0),
  ]) {
    testWidgets('home controlled $config loaded top and bottom', (t) async {
      t.view.physicalSize = Size(config.$3, 844);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = config.$4;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final originalHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(details.toString());
        originalHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalHandler);
      final h = await Harness.signedIn();
      await h.homeCubit.load('u1');
      final key = GlobalKey();
      await t.runAsync(() async {
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: h.wrap(
              const HomeScreen(),
              locale: Locale(config.$1),
              themeMode: config.$2,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      for (final end in [false, true]) {
        if (end) {
          final p = t
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position;
          for (var attempt = 0; attempt < 4; attempt++) {
            p.jumpTo(p.maxScrollExtent);
            await t.pump(const Duration(milliseconds: 200));
          }
        }
        expect(t.takeException(), isNull);
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra/verification/home_${config.$1}_${config.$2.name}_${config.$3}_${end ? 'bottom' : 'top'}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          im.dispose();
        });
      }
      await t.pumpWidget(const SizedBox());
      await h.dispose();
    });
  }
}
