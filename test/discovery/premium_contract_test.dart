import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/premium/presentation/screens/premium_screen.dart';
import '../goldens/milestone1_screens_test.dart' show Harness;

void main() {
  testWidgets('premium no commit and dynamic reduced motion back', (t) async {
    final h = await Harness.signedIn();
    final reduced = ValueNotifier(false);
    addTearDown(reduced.dispose);
    var backs = 0;
    await t.pumpWidget(
      h.wrap(
        ValueListenableBuilder(
          valueListenable: reduced,
          builder: (c, v, _) => MediaQuery(
            data: MediaQuery.of(c).copyWith(disableAnimations: v),
            child: PremiumScreen(onBack: () => backs++),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(t.binding.transientCallbackCount, greaterThan(0));
    reduced.value = true;
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(t.binding.transientCallbackCount, 0);
    await t.drag(find.byType(Scrollable).first, const Offset(0, -650));
    await t.pump(const Duration(seconds: 1));
    final disabled = find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          w.properties.button == true &&
          w.properties.enabled == false,
    );
    expect(disabled, findsOneWidget);
    await t.drag(find.byType(Scrollable).first, const Offset(0, 1000));
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.byIcon(Icons.close_rounded));
    expect(backs, 1);
    reduced.value = false;
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(t.binding.transientCallbackCount, greaterThan(0));
    expect(find.byType(FilledButton), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await h.dispose();
  });
}
