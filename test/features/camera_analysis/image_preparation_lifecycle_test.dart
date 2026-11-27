import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/camera_analysis/data/meal_image_preparer.dart';
import 'package:sufradepi/features/camera_analysis/presentation/camera_analysis_screen.dart';
import 'package:sufradepi/features/camera_analysis/presentation/capture_device.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'camera_screen_test.dart' show FixtureCaptureDevice;

class WaitingPreparer extends MealImagePreparer {
  ImagePreparationCancellation? token;
  @override
  Future<PreparedMealImage> prepare(
    String sourcePath, {
    ImagePreparationCancellation? cancellation,
  }) {
    token = cancellation;
    final result = Completer<PreparedMealImage>();
    cancellation!.onCancel(
      () => result.completeError(
        const ImagePreparationException(ImagePreparationFailure.cancelled),
      ),
    );
    return result.future;
  }
}

void main() {
  for (final dispose in [false, true]) {
    testWidgets(
      'preparation cancelled by ${dispose ? "dispose" : "inactive lifecycle"}',
      (tester) async {
        final preparer = WaitingPreparer();
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CameraAnalysisScreen(
              device: FixtureCaptureDevice(CaptureStatus.denied),
              preparer: preparer,
              pickGallery: () async => 'synthetic-unchanged-source',
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Choose image from gallery'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Choose image from gallery'));
        await tester.pump(const Duration(milliseconds: 500));
        expect(preparer.token, isNotNull);
        expect(preparer.token!.isCancelled, isFalse);
        if (dispose) {
          await tester.pumpWidget(const SizedBox());
        } else {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          await tester.pump();
        }
        expect(preparer.token!.isCancelled, isTrue);
        expect(tester.takeException(), isNull);
        if (!dispose) {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  }
}
