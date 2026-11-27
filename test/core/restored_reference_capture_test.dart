import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:sufradepi/features/recipes/presentation/screens/recipe_suggestion_screen.dart';
import '../discovery/discovery_features_test.dart'
    show StaticActivityLoader, activity;
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  testWidgets('restored original art actual owner font captures', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = await Harness.signedIn();
    for (final entry in <String, Widget>{
      'achievements': AchievementsScreen(
        userId: 'owner',
        todayKey: '2026-11-23',
        loader: StaticActivityLoader(activity()),
      ),
      'recipes': const RecipeSuggestionScreen(),
    }.entries) {
      final k = GlobalKey();
      await t.runAsync(() async {
        await t.pumpWidget(RepaintBoundary(key: k, child: h.wrap(entry.value)));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await t.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/images/art/spC.webp'),
          t.element(find.byType(MaterialApp)),
        );
      });
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      final dir = Platform.environment['SUFRA_FOOD_CAPTURE'];
      if (dir != null) {
        await t.runAsync(() async {
          final im =
              await (k.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$dir/${entry.key}_owner.png',
          ).writeAsBytes(b!.buffer.asUint8List());
          im.dispose();
        });
      }
      await t.pumpWidget(const SizedBox());
    }
    await h.dispose();
  });
}
