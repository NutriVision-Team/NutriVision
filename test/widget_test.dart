import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/glass_card.dart';
import 'package:sufradepi/core/widgets/progress_widgets.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('SufraProgressBar clamps overflow values', (tester) async {
    await tester.pumpWidget(wrap(const SufraProgressBar(fraction: 1.7)));
    await tester.pump(const Duration(milliseconds: 1600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('GlassCard renders its child and handles taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(GlassCard(onTap: () => taps++, child: const Text('سفرة'))),
    );
    expect(find.text('سفرة'), findsOneWidget);
    await tester.tap(find.text('سفرة'));
    expect(taps, 1);
  });

  testWidgets('CalorieRing renders without overflow at small sizes', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 100,
          child: CalorieRing(fraction: 0.63, size: 80),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1400));
    expect(tester.takeException(), isNull);
  });
}
