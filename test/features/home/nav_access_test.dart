import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';

void main() {
  testWidgets('Nav keyboard and live reduced motion preserve actions', (
    t,
  ) async {
    var count = 0;
    var reduced = false;
    late StateSetter update;
    await t.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, set) {
            update = set;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: Scaffold(
                bottomNavigationBar: FloatingGlassNavBar(
                  currentIndex: 0,
                  onAdd: () => count++,
                  items: List.generate(
                    4,
                    (i) => NavItem(
                      label: 'Tab $i',
                      icon: Icons.home,
                      onTap: () => count++,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await t.pump();
    final add = find.byIcon(Icons.add);
    final pointer = await t.startGesture(t.getCenter(add));
    await t.pump(const Duration(milliseconds: 250));
    expect(count, 0);
    update(() => reduced = true);
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    // A held native ink splash may remain active; custom decorative phases
    // must be static immediately when reduced motion changes.
    List<CustomPainter> phases() => t
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .expand(
          (w) => [
            if (w.painter != null) w.painter!,
            if (w.foregroundPainter != null) w.foregroundPainter!,
          ],
        )
        .where(
          (p) => [
            '_OrbitPainter',
            '_ResponsePainter',
            '_WaterRefraction',
          ].contains(p.runtimeType.toString()),
        )
        .toList();
    final before = phases();
    expect(before, isNotEmpty);
    await t.pump(const Duration(milliseconds: 250));
    final after = phases();
    expect(after.length, before.length);
    for (var i = 0; i < before.length; i++) {
      expect(after[i].shouldRepaint(before[i]), false);
    }
    await pointer.cancel();
    await t.pump();
    expect(count, 0);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(count, 1);
    await t.tap(add);
    await t.pump();
    expect(count, 2);
    expect(t.takeException(), isNull);
  });
}
