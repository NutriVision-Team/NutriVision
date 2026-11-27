import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:sufradepi/features/health_coach/coach_access_host.dart';
import 'package:sufradepi/features/progress/presentation/screens/water_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/weight_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/stats_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/report_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/export_report_screen.dart';
import 'package:sufradepi/features/dashboard/presentation/destination_hubs.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'progress_test.dart' as f;

void main() {
  setUpAll(loadRealFonts);
  for (final width in [320.0, 390.0, 800.0]) {
    for (final name in [
      'water',
      'weight',
      'stats',
      'report',
      'export',
      'meals',
      'profile',
    ]) {
      testWidgets('integrated $name width$width', (t) async {
        final height = width <= 390 ? 844.0 : 1280.0;
        t.view.physicalSize = Size(width, height);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final screen = switch (name) {
          'water' => WaterScreen(
            waterWeightRepository: f.FakeWaterWeightRepository(),
          ),
          'weight' => WeightScreen(
            waterWeightRepository: f.FakeWaterWeightRepository(),
          ),
          'stats' => StatsScreen(
            waterWeightRepository: f.FakeWaterWeightRepository(),
          ),
          'report' => const ReportScreen(),
          'export' => ExportReportScreen(
            waterWeightRepository: f.FakeWaterWeightRepository(),
          ),
          'meals' => const MealsHubScreen(),
          _ => const ProfileHubScreen(),
        };
        final router = GoRouter(
          initialLocation: '/sample',
          routes: [
            GoRoute(path: '/sample', builder: (_, _) => const SizedBox()),
          ],
        );
        addTearDown(router.dispose);
        final key = GlobalKey();
        await f.pumpScreen(
          t,
          MediaQuery(
            data: MediaQueryData(
              size: Size(width, height),
              padding: const EdgeInsets.only(top: 24, bottom: 32),
              disableAnimations: true,
              textScaler: TextScaler.linear(width == 320 ? 2 : 1),
            ),
            child: RepaintBoundary(
              key: key,
              child: CoachAccessHost(
                router: router,
                enabled: true,
                child: screen,
              ),
            ),
          ),
          f.FakeNutritionRepository()..logs = [f.log('2026-11-22')],
          theme: width == 800 ? AppTheme.dark() : AppTheme.light(),
        );
        await t.pump(const Duration(seconds: 2));
        expect(t.takeException(), isNull);
        final scaffold = t.getRect(find.byType(Scaffold).first);
        expect(scaffold.width, width);
        expect(scaffold.bottom, height);
        final nav = find.byType(FloatingGlassNavBar);
        if (nav.evaluate().isNotEmpty) {
          final rect = t.getRect(nav.first);
          expect(rect.bottom, lessThanOrEqualTo(height - 32));
          expect(height - 32 - rect.bottom, lessThanOrEqualTo(12));
        }
        // Only the host paints a nebula image. Nested bodies reuse the scope.
        final nebImages = find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == 'assets/images/art/neb.jpg',
        );
        expect(nebImages, findsNWidgets(width == 800 ? 1 : 0));
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          File(
            'build/test_evidence/${name}_${width.toInt()}.png',
          ).writeAsBytesSync(b!.buffer.asUint8List());
          im.dispose();
        });
        final scrolls = find.byType(Scrollable);
        if (scrolls.evaluate().isNotEmpty) {
          for (var i = 0; i < 3; i++) {
            await t.drag(scrolls.first, const Offset(0, -600));
            await t.pump(const Duration(milliseconds: 100));
          }
          expect(t.takeException(), isNull);
          final position = t.state<ScrollableState>(scrolls.first).position;
          position.jumpTo(position.maxScrollExtent);
          await t.pump();
          if (name == 'profile') {
            final last = find.text('الخصوصية والاستخدام');
            expect(last.hitTestable(), findsOneWidget);
            expect(t.getRect(last).bottom, lessThan(t.getRect(nav).top));
          }
          await t.runAsync(() async {
            final im =
                await (key.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
            File(
              'build/test_evidence/${name}_end_${width.toInt()}.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            im.dispose();
          });
        }
        await t.pumpWidget(const SizedBox());
      });
    }
  }
}
