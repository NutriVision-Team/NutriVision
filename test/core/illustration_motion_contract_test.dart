import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/catalog_food_art.dart';
import 'package:sufradepi/core/widgets/egyptian_dish_art.dart';

void main() {
  for (final art in <Widget>[
    const CatalogFoodArt(id: 'usda_foundation_1999634', size: 120),
    const EgyptianDishArt(dishId: 'themealdb_53025', size: 120),
  ]) {
    testWidgets(
      '${art.runtimeType} deliberate tilt and food-photo float stop dynamically for reduced motion',
      (t) async {
        final reduced = ValueNotifier(false);
        addTearDown(reduced.dispose);
        await t.pumpWidget(
          MaterialApp(
            home: ValueListenableBuilder<bool>(
              valueListenable: reduced,
              builder: (c, value, _) => MediaQuery(
                data: MediaQuery.of(c).copyWith(disableAnimations: value),
                child: Scaffold(body: Center(child: art)),
              ),
            ),
          ),
        );
        final transform = find.descendant(
          of: find.byType(art.runtimeType),
          matching: find.byType(Transform),
        );
        List<double> matrix() =>
            t.widget<Transform>(transform.first).transform.storage.toList();
        final initial = matrix();
        final gesture = await t.startGesture(
          t.getCenter(find.byType(art.runtimeType)),
        );
        await gesture.moveBy(const Offset(24, 12));
        await gesture.moveBy(const Offset(15, 4));
        await t.pump();
        expect(matrix(), isNot(equals(initial)));
        expect(
          t.binding.transientCallbackCount,
          art is CatalogFoodArt ? greaterThan(0) : 0,
        );
        reduced.value = true;
        await t.pump();
        expect(matrix(), equals(initial));
        await gesture.moveBy(const Offset(-30, -15));
        await t.pump();
        expect(matrix(), equals(initial));
        await gesture.up();
        await t.pump();
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        expect(t.binding.transientCallbackCount, 0);
      },
    );
  }
}
