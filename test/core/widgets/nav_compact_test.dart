import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final width in [320.0, 390.0]) {
    for (final ar in [false, true]) {
      for (final dark in [false, true]) {
        for (final scale in [1.0, 1.6, 2.0]) {
          testWidgets('compact nav $width ar$ar dark$dark scale$scale', (
            t,
          ) async {
            t.view.physicalSize = Size(width, 640);
            t.view.devicePixelRatio = 1;
            t.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(t.view.reset);
            addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
            var selected = -1;
            final labels = ar
                ? ['الرئيسية', 'الوجبات', 'تقدمي', 'حسابي']
                : ['Home', 'Meals', 'Progress', 'Profile'];
            await t.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark() : AppTheme.light(),
                home: Directionality(
                  textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
                  child: Scaffold(
                    bottomNavigationBar: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FloatingGlassNavBar(
                        currentIndex: 2,
                        centerLabel: ar ? 'التحليل' : 'Analyze',
                        onAdd: () => selected = 4,
                        items: [
                          for (var i = 0; i < 4; i++)
                            NavItem(
                              label: labels[i],
                              icon: Icons.home,
                              onTap: () => selected = i,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            await t.pump();
            final height = t.getSize(find.byType(FloatingGlassNavBar)).height;
            expect(height, FloatingGlassNavBar.barHeight(t.element(find.byType(FloatingGlassNavBar))));
            for (var i = 0; i < 4; i++) {
              final label = find.text(labels[i]);
              final p = t.renderObject<RenderParagraph>(label);
              expect(p.didExceedMaxLines, false);
              expect(
                p.getMaxIntrinsicWidth(double.infinity),
                lessThanOrEqualTo(p.size.width + .1),
              );
              final hit = find
                  .ancestor(of: label, matching: find.byType(InkWell))
                  .first;
              expect(t.getSize(hit).height, greaterThanOrEqualTo(48));
              await t.tap(label);
              expect(selected, i);
            }
            await t.tap(find.byIcon(Icons.add));
            expect(selected, 4);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox());
          });
        }
      }
    }
  }
}
