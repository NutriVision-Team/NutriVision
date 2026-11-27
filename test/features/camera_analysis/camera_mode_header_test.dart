import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/camera_analysis/presentation/camera_mode_header.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

void main() {
  for (final locale in ['ar', 'en']) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('camera mode header $locale scale $scale retains routes', (
        t,
      ) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        var voice = 0, barcode = 0, close = 0;
        await t.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: CameraModeHeader(
                onClose: () => close++,
                onVoice: () => voice++,
                onBarcode: () => barcode++,
                onFlash: null,
                flashEnabled: false,
              ),
            ),
          ),
        );
        await t.pump();
        final l = await AppLocalizations.delegate.load(Locale(locale));
        await t.tap(find.text(l.logHubChipVoice));
        await t.ensureVisible(find.text(l.logHubChipBarcode));
        await t.tap(find.text(l.logHubChipBarcode));
        await t.tap(find.byTooltip(l.cameraClose));
        expect([voice, barcode, close], [1, 1, 1]);
        expect(find.text(l.logHubChipPhoto), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }
}
