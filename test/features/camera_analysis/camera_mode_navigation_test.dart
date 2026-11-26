import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/features/camera_analysis/presentation/camera_analysis_screen.dart';
import 'package:sufradepi/features/camera_analysis/presentation/capture_device.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'camera_screen_test.dart' show FixtureCaptureDevice;

void main() {
  for (final mode in ['voice', 'barcode']) {
    testWidgets('$mode rapid route taps pause once and resume after return', (
      t,
    ) async {
      final device = FixtureCaptureDevice(CaptureStatus.ready);
      final target = mode == 'voice' ? '/voice-meal' : '/barcode';
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => CameraAnalysisScreen(device: device),
          ),
          GoRoute(
            path: target,
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.pop(),
                child: const Text('return to camera'),
              ),
            ),
          ),
        ],
      );
      await t.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c).copyWith(disableAnimations: true),
            child: child!,
          ),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      );
      await t.pumpAndSettle();
      final before = device.starts;
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      final modeText = find.text(
        mode == 'voice' ? l.logHubChipVoice : l.logHubChipBarcode,
      );
      final button = t.widget<TextButton>(
        find.ancestor(of: modeText, matching: find.byType(TextButton)),
      );
      button.onPressed!();
      button.onPressed!();
      await t.pumpAndSettle();
      expect(find.text('return to camera'), findsOneWidget);
      expect(device.pauses, 1);
      expect(device.status, CaptureStatus.paused);
      await t.tap(find.text('return to camera'));
      await t.pumpAndSettle();
      expect(device.starts, greaterThan(before));
      expect(find.byType(CameraAnalysisScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
  }
}
