import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sufradepi/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/progress/presentation/screens/report_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'progress_test.dart' as fixture;

void main() {
  setUpAll(loadRealFonts);
  testWidgets('logged-day indicator is neutral below and above target', (
    tester,
  ) async {
    for (final calories in [100.0, 2200.0, 5000.0]) {
      final n = fixture.FakeNutritionRepository()
        ..logs = [fixture.log('2026-11-22', cal: calories)];
      await fixture.pumpScreen(tester, const ReportScreen(), n);
      final cell = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('report-recorded-2026-11-22')),
      );
      expect((cell.decoration as BoxDecoration).color, AppColors.cyanLight);
      expect(find.text('الأيام اللي سجلت فيها أكلك'), findsOneWidget);
      expect(
        find.textContaining('المتوسط من الأيام اللي سجلت فيها: 1 من 7'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  for (final (w, scale) in [
    (320.0, 1.0),
    (390.0, 1.0),
    (320.0, 2.0),
    (390.0, 2.0),
  ]) {
    testWidgets(
      'report exposes measured averages and coverage at width$w scale$scale',
      (tester) async {
        tester.view.physicalSize = Size(w * 2, 1688);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final originalHandler = FlutterError.onError;
        FlutterError.onError = (d) {
          debugPrint(d.toString());
          originalHandler?.call(d);
        };
        addTearDown(() => FlutterError.onError = originalHandler);
        final key = GlobalKey();
        final n = fixture.FakeNutritionRepository()
          ..logs = [fixture.log('2026-11-22')];
        await fixture.pumpScreen(
          tester,
          RepaintBoundary(key: key, child: const ReportScreen()),
          n,
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.scrollUntilVisible(
          find.byType(ExpansionTile),
          200,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 12,
        );
        await tester.drag(find.byType(ListView).first, const Offset(0, -220));
        await tester.pump();
        await tester.tap(find.byType(ExpansionTile));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('متوسط القيم المسجّلة'), findsNWidgets(2));
        expect(find.textContaining('من ٧ يوم فيه قيمة مسجّلة'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra/verification/report_measured_${w.toInt()}_${scale.toInt()}.png',
          ).writeAsBytes(b!.buffer.asUint8List());
          image.dispose();
        });
        await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra/verification/report_bottom_${w.toInt()}_${scale.toInt()}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
