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
      for (final scale in [1.0, 1.6]) {
        testWidgets('water visual $lang dark$dark scale$scale', (t) async {
          t.view.physicalSize = const Size(390, 844);
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
          final quick = find.text(lang == 'ar' ? '+ ٢٥٠ مل' : '+ 250 ml');
          final tapArea = find
              .ancestor(of: quick, matching: find.byType(InkWell))
              .first;
          expect(t.getSize(tapArea).height, greaterThanOrEqualTo(48));
          final track = t.widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          );
          expect(
            track.backgroundColor,
            (dark ? AppTheme.dark() : AppTheme.light()).colorScheme.onSurface
                .withValues(alpha: .12),
          );
          for (var page = 0; page < 3; page++) {
            if (page == 2) {
              final custom = find.text(lang == 'ar' ? 'مخصص' : 'Custom');
              await t.ensureVisible(custom);
              await t.tap(custom);
              await t.pump(const Duration(milliseconds: 300));
            }
            expect(t.takeException(), isNull);
            await t.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final b = await im.toByteData(format: ui.ImageByteFormat.png);
              final stage =
                  Platform.environment['SUFRA_WATER_STAGE'] ?? 'after';
              await File(
                '/downloads/sufra-recovered/water1400_${stage}_${lang}_${dark ? 'dark' : 'light'}_${scale}_$page.png',
              ).writeAsBytes(b!.buffer.asUint8List());
              im.dispose();
            });
            await t.drag(find.byType(ListView).first, const Offset(0, -500));
            await t.pump(const Duration(milliseconds: 300));
          }
          await t.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
