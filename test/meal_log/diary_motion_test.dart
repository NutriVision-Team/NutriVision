import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/features/diary/presentation/screens/diary_screen.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;
import 'package:sufradepi/features/food_catalog/data/local_food_repository.dart';

void main() {
  setUpAll(loadRealFonts);
  for (final dark in [true, false]) {
    testWidgets('Diary real interaction motion $dark', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await Harness.signedIn();
      final food = (await t.runAsync(
        () => LocalFoodRepository().getFoodById('usda_sr_168878'),
      ))!;
      h.nutritionRepository.meals = [
        FoodPortion(food, 150).toMeal(
          uid: 'u1',
          id: 'motion',
          at: DateTime(2026, 11, 22, 14),
          mealType: 'lunch',
        ),
      ];
      final key = GlobalKey();
      await t.runAsync(() async {
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: h.wrap(
              DiaryScreen(initialDate: DateTime(2026, 11, 22)),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              additionalRoutes: [
                GoRoute(
                  path: '/meal/:id',
                  builder: (c, s) => Scaffold(
                    body: Text(
                      'Detail ${s.pathParameters['id']} ${s.uri.queryParameters['date']}',
                    ),
                  ),
                ),
                GoRoute(
                  path: '/log',
                  builder: (_, _) => const Scaffold(body: Text('Add route')),
                ),
              ],
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      final row = find.byKey(const ValueKey('diary-meal-motion'));
      await t.ensureVisible(row);
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(2, 2));
      for (var n = 0; n < 52; n++) {
        if (n == 12) await mouse.moveTo(t.getCenter(row));
        if (n == 24) await mouse.down(t.getCenter(row));
        if (n == 46) await mouse.cancel();
        await t.pump(const Duration(milliseconds: 90));
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra-recovered/diary1702_${dark ? 'dark' : 'light'}_${n.toString().padLeft(3, '0')}.png',
          ).writeAsBytes(b!.buffer.asUint8List());
          im.dispose();
        });
      }
      await mouse.removePointer();
      expect(t.takeException(), isNull);
      await t.tap(row);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Detail motion 2026-11-22'), findsOneWidget);
      GoRouter.of(t.element(find.text('Detail motion 2026-11-22'))).pop(true);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('diary-meal-motion')), findsOneWidget);
      final add = find.text('+ ضيف أكلة').first;
      await t.ensureVisible(add);
      await t.pump();
      await t.tap(add);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Add route'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await h.dispose();
    });
  }
}
