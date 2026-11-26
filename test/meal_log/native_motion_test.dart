import 'package:sufradepi/core/widgets/nebula_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/layered_food_art.dart';
import 'package:sufradepi/core/widgets/method_cube.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

Widget host(Widget child, {bool reduced = false}) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: Center(child: child)),
  ),
);
List<double> matrix(WidgetTester tester, String key) => List<double>.of(
  tester.widget<Transform>(find.byKey(ValueKey(key))).transform.storage,
);
void main() {
  testWidgets('background updates when reduced motion changes at runtime', (
    t,
  ) async {
    const background = SizedBox(
      width: 300,
      height: 400,
      child: NebulaBackground(child: SizedBox()),
    );
    await t.pumpWidget(host(background));
    expect(t.hasRunningAnimations, isTrue);
    await t.pumpWidget(host(background, reduced: true));
    await t.pump(const Duration(seconds: 1));
    expect(t.hasRunningAnimations, isFalse);
    await t.pumpWidget(host(background));
    expect(t.hasRunningAnimations, isTrue);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'layered art has nine planes, responds to drag, and releases with inertia',
    (t) async {
      await t.pumpWidget(
        host(
          const LayeredFoodArt(
            asset: 'assets/images/art/w1.webp',
            hint: 'Rotate',
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 1800));
      expect(find.byKey(const ValueKey('food-depth-8')), findsOneWidget);
      final initial = matrix(t, 'food-depth-0');
      final gesture = await t.startGesture(
        t.getCenter(find.byType(LayeredFoodArt)),
      );
      await gesture.moveBy(const Offset(30, 0));
      await t.pump();
      await gesture.moveBy(const Offset(30, 0));
      await t.pump();
      final dragged = matrix(t, 'food-depth-0');
      expect(dragged, isNot(equals(initial)));
      await gesture.up();
      await t.pump(const Duration(milliseconds: 32));
      expect(matrix(t, 'food-depth-0'), isNot(equals(dragged)));
      await t.pumpWidget(const SizedBox());
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'reduced motion freezes automatic layered art but permits deliberate rotation',
    (t) async {
      await t.pumpWidget(
        host(
          const LayeredFoodArt(
            asset: 'assets/images/art/w1.webp',
            hint: 'Rotate',
          ),
          reduced: true,
        ),
      );
      final initial = matrix(t, 'food-depth-0');
      await t.pump(const Duration(seconds: 2));
      expect(matrix(t, 'food-depth-0'), equals(initial));
      await t.drag(find.byType(LayeredFoodArt), const Offset(80, 0));
      await t.pump();
      final dragged = matrix(t, 'food-depth-0');
      expect(dragged, isNot(equals(initial)));
      await t.pump(const Duration(seconds: 2));
      expect(matrix(t, 'food-depth-0'), equals(dragged));
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('cube culls rear faces and rotates on a fourteen-second cycle', (
    t,
  ) async {
    await t.pumpWidget(host(const MethodCube()));
    await t.pump(const Duration(milliseconds: 1));
    final initial = matrix(t, 'method-cube-face-0');
    await t.pump(const Duration(seconds: 7));
    expect(find.byKey(const ValueKey('method-cube-face-0')), findsNothing);
    expect(find.byKey(const ValueKey('method-cube-face-2')), findsOneWidget);
    await t.pump(const Duration(seconds: 7));
    final completed = matrix(t, 'method-cube-face-0');
    for (var i = 0; i < initial.length; i++) {
      expect(completed[i], closeTo(initial[i], 0.000001));
    }
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('cube respects reduced motion', (t) async {
    await t.pumpWidget(host(const MethodCube(), reduced: true));
    final initial = matrix(t, 'method-cube-face-0');
    await t.pump(const Duration(seconds: 7));
    expect(matrix(t, 'method-cube-face-0'), equals(initial));
    await t.pumpWidget(const SizedBox());
  });
}
