import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import 'package:sufradepi/features/home/presentation/widgets/home_recipe_section.dart';
import 'package:sufradepi/features/recipes/data/datasources/local_recipe_data_source.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;
import 'home_journey_test.dart' show Repository;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('Home walk $lang $dark $scale', (t) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.reset);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final h = await Harness.signedIn();
          final r = Repository();
          final key = GlobalKey();
          await t.pumpWidget(
            RepaintBoundary(
              key: key,
              child: h.wrap(
                HomeScreen(
                  clock: () => DateTime(2026, 11, 22, 12),
                  progression: r,
                ),
                locale: Locale(lang),
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              ),
            ),
          );
          await t.runAsync(() async {
            for (final path in [
              'assets/images/sufra_logo.webp',
              'assets/images/art/neb.jpg',
              'assets/images/generated_food/shakshuka.png',
              'assets/images/reference_food/ful.png',
              'assets/images/reference_food/taameya.png',
              'assets/images/reference_food/koshari.png',
            ]) {
              await precacheImage(AssetImage(path), key.currentContext!);
            }
            await Future<void>.delayed(const Duration(milliseconds: 300));
          });
          await t.pump();
          await t.pump(const Duration(seconds: 2));
          final pos = t
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position;
          for (var i = 0; i < 16; i++) {
            if (i > 0) {
              await t.runAsync(() async {
                pos.jumpTo((i * 500.0).clamp(0, pos.maxScrollExtent));
                await t.pump();
              });
              await t.runAsync(() async {
                await Future<void>.delayed(const Duration(milliseconds: 80));
              });
              await t.pump(const Duration(milliseconds: 1600));
            }
            if (i == 1 && scale == 1.6) {
              expect(find.text('22/180'), findsNothing);
              expect(find.text('180'), findsWidgets);
              expect(find.text('240'), findsWidgets);
            }
            // A ListView child mounts only near its viewport. Wait after each
            // newly mounted asset Future rather than before the first scroll.
            final section = find.byType(HomeRecipeSection);
            if (section.evaluate().isNotEmpty) {
              final future = find.descendant(
                of: section,
                matching: find.byType(FutureBuilder<List<LocalRecipeRecord>>),
              );
              for (var wait = 0; wait < 50; wait++) {
                await t.runAsync(
                  () => Future<void>.delayed(const Duration(milliseconds: 20)),
                );
                await t.pump(const Duration(milliseconds: 40));
                if (t
                        .widget<FutureBuilder<List<LocalRecipeRecord>>>(future)
                        .future ==
                    null) {
                  break;
                }
                final loading = find.descendant(
                  of: section,
                  matching: find.byType(CircularProgressIndicator),
                );
                if (loading.evaluate().isEmpty) break;
              }
              expect(
                find.descendant(
                  of: section,
                  matching: find.byType(CircularProgressIndicator),
                ),
                findsNothing,
                reason: 'Recipe asset must settle after lazy child mounts',
              );
            }
            expect(t.takeException(), isNull);
            await t.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final b = await im.toByteData(format: ui.ImageByteFormat.png);
              await File(
                '/downloads/sufra-recovered/home1543_${lang}_${dark ? 'dark' : 'light'}_${scale}_$i.png',
              ).writeAsBytes(b!.buffer.asUint8List());
              im.dispose();
            });
            if (pos.pixels >= pos.maxScrollExtent) break;
          }
          await t.pumpWidget(const SizedBox.shrink());
          await r.changes.close();
          await h.dispose();
        });
      }
    }
  }
}
