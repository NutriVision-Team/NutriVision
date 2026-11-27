import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/dish_float.dart';

void main() {
  testWidgets(
    'hero dish float stays bounded and stops dynamically for reduced motion',
    (t) async {
      final reduced = ValueNotifier(false);
      addTearDown(reduced.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: reduced,
            builder: (c, v, _) => MediaQuery(
              data: MediaQuery.of(c).copyWith(disableAnimations: v),
              child: const DishFloat(child: SizedBox(width: 100, height: 100)),
            ),
          ),
        ),
      );
      final f = find.descendant(
        of: find.byType(DishFloat),
        matching: find.byType(Transform),
      );
      List<List<double>> state() => t
          .widgetList<Transform>(f)
          .map((x) => x.transform.storage.toList())
          .toList();
      final start = state();
      await t.pump(const Duration(milliseconds: 1500));
      expect(state(), isNot(equals(start)));
      final offset = t.widget<Transform>(f.first).transform.storage[13];
      expect(offset, inInclusiveRange(-4.0, 0.0));
      reduced.value = true;
      await t.pump();
      final still = state();
      await t.pump(const Duration(seconds: 2));
      expect(state(), equals(still));
      expect(t.binding.transientCallbackCount, 0);
      await t.pumpWidget(const SizedBox.shrink());
      expect(t.takeException(), isNull);
    },
  );
}
