import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/onboarding/presentation/onboarding_screen.dart';
import 'package:sufradepi/core/widgets/layered_food_art.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final light in [true, false]) {
    testWidgets('clean onboarding actual animation $light', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await Harness.signedIn();
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: h.wrap(
            OnboardingScreen(preferences: h.preferences),
            themeMode: light ? ThemeMode.light : ThemeMode.dark,
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(seconds: 3));
      final l = await AppLocalizations.delegate.load(const Locale('ar'));
      for (var page = 0; page < 3; page++) {
        if (page > 0) {
          await t.tap(find.text(l.onboardingNext));
          await t.pump();
          await t.pump(const Duration(seconds: 3));
        }
        List<double> matrix() => List<double>.of(
          t
              .widget<Transform>(
                find.descendant(
                  of: find.byType(LayeredFoodArt).last,
                  matching: find.byKey(const ValueKey('food-depth-0')),
                ),
              )
              .transform
              .storage,
        );
        final first = matrix();
        for (var n = 0; n < 20; n++) {
          await t.pump(const Duration(milliseconds: 120));
          await t.runAsync(() async {
            final im =
                await (key.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final b = await im.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '/downloads/sufra-recovered/art1923_${light ? 'light' : 'dark'}_${page}_motion${n.toString().padLeft(3, '0')}.png',
            ).writeAsBytes(b!.buffer.asUint8List());
            im.dispose();
          });
        }
        expect(matrix(), isNot(equals(first)));
        expect(t.takeException(), isNull);
      }
      await t.pumpWidget(const SizedBox());
      await h.dispose();
    });
  }
}
