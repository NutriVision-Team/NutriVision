import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final size in [const Size(844, 390), const Size(1024, 768)]) {
    testWidgets('wide large navigation preserves labels and callbacks $size', (
      t,
    ) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      var selected = -1;
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: FloatingGlassNavBar(
                    showIcons: false,
                    currentIndex: 0,
                    onAdd: () => selected = 4,
                    items: [
                      for (final pair in [
                        'Home',
                        'Diary',
                        'Progress',
                        'Account',
                      ].indexed)
                        NavItem(
                          label: pair.$2,
                          icon: Icons.home,
                          onTap: () => selected = pair.$1,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.getSize(find.byType(FloatingGlassNavBar)).height, greaterThanOrEqualTo(176));
      for (final pair in ['Home', 'Diary', 'Progress', 'Account'].indexed) {
        final target = find.text(pair.$2);
        expect(target.hitTestable(), findsOneWidget);
        await t.tap(target);
        expect(selected, pair.$1);
      }
      await t.tap(find.byIcon(Icons.add));
      expect(selected, 4);
      expect(t.takeException(), isNull);
    });
  }
}
