import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/progress/export/report_pdf.dart';
import 'package:sufradepi/features/progress/presentation/screens/export_report_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'progress_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);
  testWidgets(
    'real report boundary produces a local PDF and captures its complete preview',
    (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final nutrition = fixture.FakeNutritionRepository()
        ..logs = [fixture.log('2026-11-22')];
      await fixture.pumpScreen(
        tester,
        ExportReportScreen(
          waterWeightRepository: fixture.FakeWaterWeightRepository(),
        ),
        nutrition,
      );
      await tester.pump(const Duration(seconds: 2));
      final finder = find.descendant(
        of: find.byType(ExportReportScreen),
        matching: find.byWidgetPredicate(
          (w) => w is RepaintBoundary && w.key is GlobalKey,
        ),
      );
      expect(finder, findsOneWidget);
      final boundary = tester.widget<RepaintBoundary>(finder),
          key = boundary.key! as GlobalKey;
      final result = await tester.runAsync(() async {
        final dir = Directory('/downloads/sufra/verification');
        await dir.create(recursive: true);
        final file = await ReportPdfExporter.export(key, directory: dir);
        final pdf = await file.copy('${dir.path}/report_fixture.pdf');
        await file.delete();
        final object =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await object.toImage(pixelRatio: 2);
        try {
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          await File(
            '${dir.path}/report_fixture_preview.png',
          ).writeAsBytes(data.buffer.asUint8List());
        } finally {
          image.dispose();
        }
        return pdf.readAsBytes();
      });
      expect(String.fromCharCodes(result!.take(4)), '%PDF');
      expect(result.length, greaterThan(10000));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
