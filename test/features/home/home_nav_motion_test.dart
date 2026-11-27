import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';

void main() {
  testWidgets('nav press feedback releases and tap executes once', (
    tester,
  ) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingGlassNavBar(
            currentIndex: 0,
            onAdd: () => count++,
            items: List.generate(
              4,
              (i) => NavItem(
                label: 'tab $i',
                icon: Icons.home,
                onTap: () => count++,
              ),
            ),
          ),
        ),
      ),
    );
    final target = find.text('tab 1');
    final gesture = await tester.startGesture(tester.getCenter(target));
    await tester.pump(const Duration(milliseconds: 130));
    expect(
      tester
          .widget<AnimatedScale>(
            find.ancestor(of: target, matching: find.byType(AnimatedScale)),
          )
          .scale,
      .94,
    );
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 350));
    expect(count, 1);
    expect(
      tester
          .widget<AnimatedScale>(
            find.ancestor(of: target, matching: find.byType(AnimatedScale)),
          )
          .scale,
      1,
    );
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(const Duration(milliseconds: 350));
    expect(count, 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reduced motion disables press transform and label transition', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: FloatingGlassNavBar(
              currentIndex: 0,
              onAdd: () {},
              items: List.generate(
                4,
                (i) => NavItem(label: 'tab $i', icon: Icons.home, onTap: () {}),
              ),
            ),
          ),
        ),
      ),
    );
    final target = find.text('tab 0');
    final g = await tester.startGesture(tester.getCenter(target));
    await tester.pump();
    expect(
      tester
          .widget<AnimatedScale>(
            find.ancestor(of: target, matching: find.byType(AnimatedScale)),
          )
          .scale,
      1,
    );
    expect(
      tester
          .widget<AnimatedDefaultTextStyle>(
            find
                .ancestor(
                  of: target,
                  matching: find.byType(AnimatedDefaultTextStyle),
                )
                .first,
          )
          .duration,
      Duration.zero,
    );
    await g.cancel();
    await tester.pump(const Duration(milliseconds: 350));
  });
}
