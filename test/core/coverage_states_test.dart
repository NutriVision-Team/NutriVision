import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/app_states.dart';
import 'package:sufradepi/features/splash/presentation/splash_screen.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final light in [true, false]) {
      for (final scale in [1.0, 1.6]) {
        for (final page in ['splash', 'loading', 'empty', 'error']) {
          testWidgets('final $page $lang $light $scale', (t) async {
            t.view.physicalSize = scale > 1
                ? const Size(320, 640)
                : const Size(390, 844);
            t.view.devicePixelRatio = 1;
            addTearDown(t.view.reset);
            t.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
            final h = await Harness.signedOut();
            final key = GlobalKey();
            var retried = 0;
            await t.pumpWidget(
              RepaintBoundary(
                key: key,
                child: h.wrap(
                  Builder(
                    builder: (c) => switch (page) {
                      'splash' => const SplashScreen(),
                      'loading' => const Scaffold(body: AppLoadingView()),
                      'empty' => Scaffold(
                        body: AppEmptyView(
                          message: lang == 'ar'
                              ? 'لسه مفيش سجلات'
                              : 'No records yet',
                        ),
                      ),
                      _ => Scaffold(
                        body: AppErrorView(onRetry: () => retried++),
                      ),
                    },
                  ),
                  locale: Locale(lang),
                  themeMode: light ? ThemeMode.light : ThemeMode.dark,
                ),
              ),
            );
            await t.pump();
            await t.pump(const Duration(seconds: 3));
            await t.runAsync(() async {
              for (final e in find.byType(Image).evaluate()) {
                await precacheImage((e.widget as Image).image, e);
              }
            });
            await t.pump();
            expect(t.takeException(), isNull);
            await t.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final b = await im.toByteData(format: ui.ImageByteFormat.png);
              im.dispose();
              await File(
                '/downloads/sufra-recovered/coverage1944_${page}_${lang}_${light ? 'light' : 'dark'}_$scale.png',
              ).writeAsBytes(b!.buffer.asUint8List());
            });
            if (page == 'error') {
              await t.tap(find.text(lang == 'ar' ? 'حاول تاني' : 'Try again'));
              expect(retried, 1);
            }
            await t.pumpWidget(const SizedBox());
            await h.dispose();
          });
        }
      }
    }
  }
}
