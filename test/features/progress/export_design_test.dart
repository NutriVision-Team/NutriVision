import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/app_buttons.dart';
import 'package:sufradepi/features/progress/presentation/screens/export_report_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'progress_test.dart' as fixture;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('export actual screen $lang dark$dark scale$scale', (
          t,
        ) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.reset);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final key = GlobalKey();
          await fixture.pumpScreen(
            t,
            RepaintBoundary(
              key: key,
              child: ExportReportScreen(
                waterWeightRepository: fixture.FakeWaterWeightRepository(),
              ),
            ),
            fixture.FakeNutritionRepository()
              ..logs = [fixture.log('2026-11-22')],
            locale: Locale(lang),
            theme: dark ? AppTheme.dark() : AppTheme.light(),
          );
          await t.pump(const Duration(seconds: 1));
          expect(find.byType(GradientButton), findsNWidgets(2));
          for (var page = 0; page < 2; page++) {
            expect(t.takeException(), isNull);
            await t.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final b = await im.toByteData(format: ui.ImageByteFormat.png);
              await File(
                '/downloads/sufra-recovered/export1355_${lang}_${dark ? 'dark' : 'light'}_${scale}_$page.png',
              ).writeAsBytes(b!.buffer.asUint8List());
              im.dispose();
            });
            await t.drag(
              find.byType(SingleChildScrollView).last,
              const Offset(0, -600),
            );
            await t.pump(const Duration(milliseconds: 350));
          }
          // Hover and held press only. Cancel avoids creating a file or opening the OS share sheet.
          final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
          await mouse.addPointer(location: Offset.zero);
          final target = t.getCenter(find.byType(GradientButton).first);
          await t.drag(
            find.byType(SingleChildScrollView).last,
            const Offset(0, 3000),
          );
          await t.pump(const Duration(milliseconds: 350));
          await mouse.moveTo(target);
          await t.pump(const Duration(milliseconds: 300));
          if (lang == 'en' && scale == 1.0) {
            await t.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final b = await im.toByteData(format: ui.ImageByteFormat.png);
              await File(
                '/downloads/sufra-recovered/export1355_hover_${dark ? 'dark' : 'light'}.png',
              ).writeAsBytes(b!.buffer.asUint8List());
              im.dispose();
            });
          }
          final finger = await t.startGesture(target);
          for (var frame = 0; frame < 7; frame++) {
            await t.pump(const Duration(milliseconds: 166));
            if (lang == 'en' && scale == 1.0) {
              await t.runAsync(() async {
                final im =
                    await (key.currentContext!.findRenderObject()!
                            as RenderRepaintBoundary)
                        .toImage();
                final b = await im.toByteData(format: ui.ImageByteFormat.png);
                await File(
                  '/downloads/sufra-recovered/export1355_press_${dark ? 'dark' : 'light'}_$frame.png',
                ).writeAsBytes(b!.buffer.asUint8List());
                im.dispose();
              });
            }
          }
          await finger.cancel();
          await mouse.removePointer();
          await t.pump();
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
