import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/ordered_number_pair.dart';

void main() {
  for (final values in [(1, 3), (420, 2397)]) {
    testWidgets(
      'ordered pair ${values.$1}/${values.$2} stays left-to-right within Arabic layout',
      (t) async {
        await t.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: OrderedNumberPair(first: values.$1, second: values.$2),
              ),
            ),
          ),
        );
        final finder = find.byKey(const ValueKey('ordered-number-pair-text'));
        final text = t.widget<Text>(finder);
        expect(text.textDirection, TextDirection.ltr);
        expect(text.data, '${values.$1} / ${values.$2}');
        final paragraph = t.renderObject<RenderParagraph>(
          find.descendant(of: finder, matching: find.byType(RichText)),
        );
        final first = paragraph
            .getBoxesForSelection(
              TextSelection(
                baseOffset: 0,
                extentOffset: values.$1.toString().length,
              ),
            )
            .first;
        final start = values.$1.toString().length + 3;
        final second = paragraph
            .getBoxesForSelection(
              TextSelection(
                baseOffset: start,
                extentOffset: start + values.$2.toString().length,
              ),
            )
            .first;
        expect(first.left, lessThan(second.left));
      },
    );
  }
}
