import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/nebula_background.dart';
import 'package:sufradepi/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('Home quick actions $lang $dark $scale', (t) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.reset);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final key = GlobalKey();
          final calls = <String>[];
          await t.pumpWidget(
            RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                locale: Locale(lang),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: NebulaBackground(
                    child: SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: HomeQuickActions(onOpen: calls.add),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          Future<void> snap(String state) async {
            expect(t.takeException(), isNull);
            await t.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final b = await im.toByteData(format: ui.ImageByteFormat.png);
              await File(
                '/downloads/sufra-recovered/actions1608_${lang}_${dark ? 'dark' : 'light'}_${scale}_$state.png',
              ).writeAsBytes(b!.buffer.asUint8List());
              im.dispose();
            });
          }

          await snap('idle');
          final planner = find.byKey(const ValueKey('home-action/planner'));
          if (lang == 'ar' && scale == 1.0) {
            final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
            await mouse.addPointer(location: const Offset(2, 2));
            for (var n = 0; n < 12; n++) {
              await t.pump(const Duration(milliseconds: 67));
              await snap('motion${n.toString().padLeft(3, '0')}');
            }
            await mouse.moveTo(t.getCenter(planner));
            await t.pump(const Duration(milliseconds: 250));
            await snap('hover');
            for (var n = 12; n < 27; n++) {
              await t.pump(const Duration(milliseconds: 67));
              await snap('motion${n.toString().padLeft(3, '0')}');
            }
            await mouse.down(t.getCenter(planner));
            for (var n = 27; n < 50; n++) {
              await t.pump(const Duration(milliseconds: 67));
              await snap('motion${n.toString().padLeft(3, '0')}');
            }
            await snap('press');
            expect(calls, isEmpty);
            await mouse.up();
            await mouse.removePointer();
            await t.pump(const Duration(milliseconds: 300));
            expect(calls, ['/planner']);
            calls.clear();
          }
          for (final route in ['/planner', '/shopping', '/coach', '/ramadan']) {
            final tile = find.byKey(ValueKey('home-action$route'));
            await t.ensureVisible(tile);
            await t.pump(const Duration(milliseconds: 300));
            await t.tap(
              find.descendant(of: tile, matching: find.byType(InkWell)),
            );
            await t.pump(const Duration(milliseconds: 300));
          }
          expect(calls, ['/planner', '/shopping', '/coach', '/ramadan']);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
  testWidgets('Reduced motion leaves no running idle or held ticker', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(body: HomeQuickActions(onOpen: (_) {})),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 1));
    final gesture = await t.startGesture(
      t.getCenter(find.byKey(const ValueKey('home-action/planner'))),
    );
    await t.pump(const Duration(seconds: 1));
    // Material ink may finish, flowing decorative response must be stopped.
    await gesture.cancel();
    await t.pumpAndSettle();
    expect(t.hasRunningAnimations, isFalse);
  });
}
