import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/camera_analysis/presentation/camera_capture_chrome.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        'camera dock $language scale $scale preserves capture controls',
        (t) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          var captures = 0, gallery = 0;
          double zoom = 1;
          await t.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark(),
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(
                  c,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CameraCaptureDock(
                    zooms: const [.5, 1, 2],
                    zoom: 1,
                    onZoom: (v) => zoom = v,
                    onCapture: () => captures++,
                    onGallery: () => gallery++,
                  ),
                ),
              ),
            ),
          );
          await t.pump();
          final l = await AppLocalizations.delegate.load(Locale(language));
          await t.tap(find.byTooltip(l.cameraCapture));
          await t.tap(find.byTooltip(l.cameraGallery));
          await t.tap(find.text('2×'));
          expect([captures, gallery], [1, 1]);
          expect(zoom, 2);
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
