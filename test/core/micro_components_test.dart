import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/app_buttons.dart';
import 'package:sufradepi/core/widgets/progress_widgets.dart';
import 'package:sufradepi/core/widgets/glass_card.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final light in [true, false]) {
    testWidgets('render shared micro interactions $light', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await Harness.signedIn();
      final key = GlobalKey();
      final selected = ValueNotifier(0);
      addTearDown(selected.dispose);
      var presses = 0;
      final calls = <String>[];
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (m) async {
          if (m.method == 'HapticFeedback.vibrate') {
            calls.add(m.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: h.wrap(
            ValueListenableBuilder(
              valueListenable: selected,
              builder: (c, v, _) => Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'تفاعلات سفرة',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const GlassCard(
                        child: Text(
                          'نفس مكوّنات التطبيق',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CalorieRing(
                        fraction: v == 0 ? .25 : .7,
                        child: Text(v == 0 ? '25%' : '70%'),
                      ),
                      const SizedBox(height: 24),
                      SufraProgressBar(fraction: v == 0 ? .25 : .7),
                      const SizedBox(height: 24),
                      GradientButton(
                        label: 'تسجيل',
                        onPressed: () {
                          presses++;
                          selected.value = 1;
                        },
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FloatingGlassNavBar(
                    currentIndex: v,
                    onAdd: () {},
                    items: [
                      for (var i = 0; i < 4; i++)
                        NavItem(
                          label: ['الرئيسية', 'اليومية', 'تقدمي', 'حسابي'][i],
                          icon: [
                            Icons.home,
                            Icons.book,
                            Icons.bar_chart,
                            Icons.person,
                          ][i],
                          onTap: () => selected.value = i,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            themeMode: light ? ThemeMode.light : ThemeMode.dark,
          ),
        ),
      );
      await t.pump(const Duration(seconds: 2));
      Future<void> shot(int n) async {
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          im.dispose();
          await File(
            '/downloads/sufra-recovered/micro1932_${light ? 'light' : 'dark'}_${n.toString().padLeft(3, '0')}.png',
          ).writeAsBytes(b!.buffer.asUint8List());
        });
      }

      final g = await t.startGesture(t.getCenter(find.text('تسجيل')));
      await t.pump(const Duration(milliseconds: 100));
      await shot(0);
      await g.up();
      await t.pump();
      for (var n = 1; n < 16; n++) {
        await t.pump(const Duration(milliseconds: 100));
        await shot(n);
      }
      expect(presses, 1);
      expect(calls, isNotEmpty);
      await t.tap(find.text('تقدمي'));
      await t.pump();
      for (var n = 16; n < 23; n++) {
        await t.pump(const Duration(milliseconds: 50));
        await shot(n);
      }
      expect(selected.value, 2);
      expect(calls.length, 2);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await h.dispose();
    });
  }
}
