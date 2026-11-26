import 'package:sufradepi/core/widgets/glass_highlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/glass_card.dart';

void main() {
  testWidgets(
    'glass reflection follows outer geometry regardless of content padding',
    (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 220,
                  height: 120,
                  child: GlassCard(
                    blur: false,
                    padding: EdgeInsets.zero,
                    child: Text('First'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  height: 120,
                  child: GlassCard(
                    blur: false,
                    padding: EdgeInsets.all(24),
                    child: Text('Second'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final highlights = find.byType(GlassHighlight);
      expect(highlights, findsNWidgets(2));
      expect(t.getSize(highlights.at(0)), t.getSize(highlights.at(1)));
      expect(t.getSize(highlights.at(0)).width, greaterThan(215));
      expect(t.getSize(highlights.at(0)).height, greaterThan(115));
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('action card exposes button and keeps keyboard activation', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    var count = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassCard(
            onTap: () => count++,
            child: const Text('Recipe details'),
          ),
        ),
      ),
    );
    expect(
      t
          .getSemantics(find.byType(GlassCard))
          .getSemanticsData()
          .flagsCollection
          .isButton,
      isTrue,
    );
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(count, 1);
    semantics.dispose();
  });
  testWidgets('non-action card is not presented as a button', (t) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GlassCard(child: Text('Nutrition'))),
      ),
    );
    expect(
      t
          .getSemantics(find.byType(GlassCard))
          .getSemanticsData()
          .flagsCollection
          .isButton,
      isFalse,
    );
    semantics.dispose();
  });
}
