import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import 'package:sufradepi/features/profile_setup/presentation/screens/profile_setup_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final step in [1, 2, 3, 4, 5, 6]) {
    for (final light in [false, true]) {
      testWidgets(
        'setup step$step ${light ? 'light' : 'dark'} 320px 2x no overflow',
        (t) async {
          t.view.devicePixelRatio = 1;
          t.view.physicalSize = const Size(320, 640);
          t.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(() {
            t.view.resetPhysicalSize();
            t.view.resetDevicePixelRatio();
            t.platformDispatcher.clearTextScaleFactorTestValue();
          });
          final h = await Harness.signedIn();
          h.setupCubit.update(
            ProfileSetupData(
              gender: 'male',
              dateOfBirth: DateTime(2000, 8, 7),
              heightCm: 175,
              currentWeightKg: 90,
              targetWeightKg: 80,
              activityLevel: 'moderate',
              nutritionGoal: 'lose',
            ),
          );
          for (var i = 0; i < step; i++) {
            h.setupCubit.next();
          }
          await t.pumpWidget(
            RepaintBoundary(
              key: const ValueKey('setup-shot'),
              child: h.wrap(
                const ProfileSetupScreen(),
                themeMode: light ? ThemeMode.light : ThemeMode.dark,
              ),
            ),
          );
          await t.pump(const Duration(seconds: 1));
          expect(t.takeException(), isNull);
          final path = Platform.environment['SUFRA_SETUP_PIXEL'];
          if (path != null) {
            final boundary = t.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('setup-shot')),
            );
            await t.runAsync(() async {
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File(
                '$path-step$step-${light ? 'light' : 'dark'}.png',
              ).writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await t.pumpWidget(const SizedBox.shrink());
          await h.dispose();
        },
      );
    }
  }
}
