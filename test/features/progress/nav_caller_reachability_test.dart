import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:sufradepi/features/progress/presentation/screens/water_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/report_screen.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;
import 'progress_test.dart' as f;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final feature in ['water', 'report', 'home']) {
      testWidgets('$feature $lang 320x6402x end', (t) async {
        t.view.physicalSize = Size(
          double.parse(Platform.environment['SUFRA_REVIEW_WIDTH'] ?? '320'),
          double.parse(Platform.environment['SUFRA_REVIEW_HEIGHT'] ?? '640'),
        );
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final original = FlutterError.onError;
        FlutterError.onError = (d) {
          debugPrint(d.toString());
          original?.call(d);
        };
        addTearDown(() => FlutterError.onError = original);
        final screen = switch (feature) {
          'water' => WaterScreen(
            waterWeightRepository: f.FakeWaterWeightRepository(),
          ),
          'report' => const ReportScreen(),
          _ => HomeScreen(clock: () => DateTime(2026, 11, 22, 18)),
        };
        final wrapped = Builder(
          builder: (c) => Localizations.override(
            context: c,
            locale: Locale(lang),
            child: MediaQuery(
              data: MediaQuery.of(
                c,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: RepaintBoundary(
                key: const ValueKey('pixel'),
                child: screen,
              ),
            ),
          ),
        );
        if (feature == 'home') {
          final h = await Harness.signedIn();
          addTearDown(h.dispose);
          await t.pumpWidget(h.wrap(wrapped));
        } else {
          await f.pumpScreen(
            t,
            wrapped,
            f.FakeNutritionRepository()..logs = [f.log('2026-11-22')],
          );
        }
        await t.pump(const Duration(seconds: 1));
        expect(t.takeException(), isNull);
        final scrolls = find.byType(Scrollable);
        if (scrolls.evaluate().isNotEmpty) {
          for (var i = 0; i < 12; i++) {
            final p = t.state<ScrollableState>(scrolls.first).position;
            p.jumpTo(p.maxScrollExtent);
            await t.pump(const Duration(milliseconds: 100));
          }
        }
        expect(t.takeException(), isNull);
        expect(find.byType(FloatingGlassNavBar), findsOneWidget);
        if (feature == 'water') {
          final horizontal = find.byWidgetPredicate(
            (w) =>
                w is Scrollable &&
                (w.axisDirection == AxisDirection.left ||
                    w.axisDirection == AxisDirection.right),
          );
          expect(horizontal, findsOneWidget);
          final state = t.state<ScrollableState>(horizontal);
          expect(state.position.maxScrollExtent, greaterThan(0));
          final chartText = find.descendant(
            of: horizontal,
            matching: find.byType(Text),
          );
          expect(chartText, findsNWidgets(7));
          final last = chartText.last;
          state.position.jumpTo(state.position.maxScrollExtent);
          await t.pump(const Duration(milliseconds: 300));
          final rect = t.getRect(last);
          expect(rect.left, greaterThanOrEqualTo(16));
          expect(rect.right, lessThanOrEqualTo(t.view.physicalSize.width - 16));
        }
        if (feature == 'report') {
          final expansion = find.byType(ExpansionTile);
          await t.tap(
            find.descendant(of: expansion, matching: find.byType(Text)).first,
          );
          await t.pump(const Duration(milliseconds: 500));
          for (var i = 0; i < 8; i++) {
            final p = t
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position;
            p.jumpTo(p.maxScrollExtent);
            await t.pump(const Duration(milliseconds: 100));
          }
          expect(t.takeException(), isNull);
        }
        if (feature == 'report') {
          final tile = find.byType(ExpansionTile);
          final last = find
              .descendant(of: tile, matching: find.byType(Text))
              .last;
          expect(t.getRect(last).top, greaterThanOrEqualTo(0));
          expect(
            t.getRect(last).bottom,
            lessThan(t.getRect(find.byType(FloatingGlassNavBar)).top),
          );
        }
        final b = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('pixel')),
        );
        await t.runAsync(() async {
          final im = await b.toImage();
          final d = await im.toByteData(format: ui.ImageByteFormat.png);
          File(
            '/downloads/sufra/verification/nav_${feature}_${lang}_end.png',
          ).writeAsBytesSync(d!.buffer.asUint8List());
          im.dispose();
        });
        await t.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
