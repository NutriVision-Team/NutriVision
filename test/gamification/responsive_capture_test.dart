import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/features/gamification/presentation/progression_screen.dart';
import 'package:sufradepi/features/health_coach/coach_access_host.dart';
import 'progression_screen_test.dart' show FixtureRepository;
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final width in [320.0, 390.0, 768.0, 800.0, 844.0]) {
    testWidgets('integrated host progression $width', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Size(
        width,
        width == 844
            ? 390
            : width <= 390
            ? 844
            : 1280,
      );
      addTearDown(t.view.reset);
      final key = GlobalKey();
      final router = GoRouter(
        initialLocation: '/stats',
        routes: [
          GoRoute(
            path: '/stats',
            builder: (_, _) => ProgressionScreen(
              uid: 'u',
              todayKey: '2026-11-24',
              repository: FixtureRepository(),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await t.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.dark(),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c).copyWith(
              disableAnimations: true,
              textScaler: TextScaler.linear(width == 320 ? 2 : 1),
              padding: const EdgeInsets.only(top: 24, bottom: 32),
            ),
            child: RepaintBoundary(
              key: key,
              child: CoachAccessHost(
                router: router,
                enabled: true,
                child: child!,
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          'build/test_evidence/${const String.fromEnvironment('CAPTURE_STAGE', defaultValue: 'before')}_${width.toInt()}.png',
        ).writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
      await t.scrollUntilVisible(
        find.text('صحتك بالأرقام'),
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
      final scroll = t
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      scroll.jumpTo(scroll.maxScrollExtent);
      await t.pumpAndSettle();
      final last = find.text('التقارير');
      if (last.evaluate().isNotEmpty) {
        expect(last.hitTestable(), findsOneWidget);
        expect(
          t.getRect(last).bottom,
          lessThan(t.getRect(find.byType(FloatingGlassNavBar)).top),
        );
      }
      await t.runAsync(() async {
        final im =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
        File(
          'build/test_evidence/progress_end_${width.toInt()}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        im.dispose();
      });
      expect(t.takeException(), isNull);
    });
  }
}
