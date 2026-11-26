import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/data/models/water_log_model.dart';
import 'package:sufradepi/features/progress/presentation/screens/water_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'progress_test.dart' as f;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [2.0]) {
        testWidgets('water visual $lang dark$dark scale$scale', (t) async {
          t.view.physicalSize = const Size(320, 640);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.reset);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final key = GlobalKey();
          await f.pumpScreen(
            t,
            RepaintBoundary(
              key: key,
              child: WaterScreen(
                waterWeightRepository: f.FakeWaterWeightRepository()
                  ..water = [
                    WaterLogModel(
                      waterId: 'fixture',
                      amountMl: 750,
                      consumedAt: DateTime(2026, 11, 22, 12),
                      dateKey: '2026-11-22',
                    ),
                  ],
              ),
            ),
            f.FakeNutritionRepository()..logs = [f.log('2026-11-22')],
            locale: Locale(lang),
            theme: dark ? AppTheme.dark() : AppTheme.light(),
          );
          await t.pump(const Duration(seconds: 2));
          for (var page = 0; page < 2; page++) {
            expect(t.takeException(), isNull);
            await t.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final b = await im.toByteData(format: ui.ImageByteFormat.png);
              final stage =
                  Platform.environment['SUFRA_WATER_STAGE'] ?? 'nav1407';
              await File(
                '/downloads/sufra-recovered/nav1407_${stage}_${lang}_${dark ? 'dark' : 'light'}_${scale}_$page.png',
              ).writeAsBytes(b!.buffer.asUint8List());
              im.dispose();
            });
            final position = t
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position;
            for (var i = 0; i < 12; i++) {
              position.jumpTo(position.maxScrollExtent);
              await t.pump(const Duration(milliseconds: 100));
            }
            await t.pump(const Duration(milliseconds: 300));
          }
          await t.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
