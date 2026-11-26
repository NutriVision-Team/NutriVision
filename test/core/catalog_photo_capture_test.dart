import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/food_catalog/data/local_food_repository.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/food_detail_screen.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  testWidgets('licensed food cutouts in actual source detail screens', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = await Harness.signedIn();
    final repo = LocalFoodRepository();
    for (final id in [
      '2646170',
      '328637',
      '2684442',
      '747447',
      '2685577',
      '2710824',
      '1999632',
      '1105314',
      '2258586',
      '746768',
    ]) {
      final food = await t.runAsync(
        () => repo.getFoodById('usda_foundation_$id'),
      );
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: h.wrap(FoodDetailScreen(food: food!)),
        ),
      );
      await t.pump();
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)),
      );
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      final dir = Platform.environment['SUFRA_FOOD_CAPTURE'];
      if (dir != null) {
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
          await File('$dir/$id.png').writeAsBytes(bytes!.buffer.asUint8List());
          im.dispose();
        });
      }
      await t.pumpWidget(const SizedBox());
    }
    await h.dispose();
  });
}
