import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/recipes/presentation/widgets/discovery_widgets.dart';

void main() {
  testWidgets('HTML sxf endpoints midpoint and dynamic reduced motion', (
    t,
  ) async {
    final reduced = ValueNotifier(false);
    addTearDown(reduced.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: reduced,
          builder: (c, v, _) => MediaQuery(
            data: MediaQuery.of(c).copyWith(disableAnimations: v),
            child: const DiscoveryFloat(
              child: SizedBox(width: 160, height: 160),
            ),
          ),
        ),
      ),
    );
    final transforms = find.descendant(
      of: find.byType(DiscoveryFloat),
      matching: find.byType(Transform),
    );
    double y() => t.widget<Transform>(transforms.at(0)).transform.storage[13];
    double angle() => math.atan2(
      t.widget<Transform>(transforms.at(1)).transform.storage[1],
      t.widget<Transform>(transforms.at(1)).transform.storage[0],
    );
    expect(y(), 0);
    await t.pump(const Duration(milliseconds: 1800));
    expect(y(), closeTo(-7, .001));
    expect(angle(), closeTo(2 * math.pi / 180, .00001));
    await t.pump(const Duration(milliseconds: 1800));
    expect(y(), closeTo(0, .001));
    reduced.value = true;
    await t.pump();
    expect(y(), 0);
    expect(angle(), 0);
    await t.pump(const Duration(seconds: 8));
    expect(y(), 0);
    await t.pumpWidget(const SizedBox());
    expect(t.binding.transientCallbackCount, 0);
  });
}
