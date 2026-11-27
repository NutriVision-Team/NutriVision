import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/app_states.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'shared loading empty error retry skeleton width$width scale$scale',
        (t) async {
          t.view.physicalSize = Size(width, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          var retries = 0;
          final k = GlobalKey();
          await t.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark(),
              locale: const Locale('ar'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (ctx, ch) => MediaQuery(
                data: MediaQuery.of(
                  ctx,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: ch!,
              ),
              home: RepaintBoundary(
                key: k,
                child: Scaffold(
                  body: SafeArea(
                    child: ListView(
                      children: [
                        const SizedBox(height: 170, child: AppLoadingView()),
                        const SizedBox(
                          height: 170,
                          child: AppEmptyView(
                            message: 'مفيش بيانات مسجّلة لسه',
                          ),
                        ),
                        AppErrorView(onRetry: () => retries++),
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: SkeletonBlock(height: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.pump(const Duration(seconds: 1));
          expect(t.takeException(), isNull);
          await t.ensureVisible(find.text('حاول تاني'));
          await t.tap(find.text('حاول تاني'));
          expect(retries, 1);
          await t.pump();
          await t.pump(const Duration(milliseconds: 300));
          await t.runAsync(() async {
            final im =
                await (k.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final b = await im.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '/downloads/sufra/verification/states_${width.toInt()}_${scale.toInt()}.png',
            ).writeAsBytes(b!.buffer.asUint8List());
            im.dispose();
          });
          await t.pumpWidget(const SizedBox.shrink());
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
