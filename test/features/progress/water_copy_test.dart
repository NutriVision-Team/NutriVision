import 'package:flutter/material.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/water_log_model.dart';
import 'package:sufradepi/features/progress/presentation/screens/water_screen.dart';
import 'progress_test.dart' as f;

void main() {
  testWidgets(
    'water labels preserve consumed versus goal in generated positional APIs',
    (tester) async {
      await f.pumpScreen(
        tester,
        WaterScreen(
          waterWeightRepository: f.FakeWaterWeightRepository()
            ..water = [
              WaterLogModel(
                waterId: 'water',
                amountMl: 750,
                consumedAt: DateTime(2026, 11, 22, 12),
                dateKey: '2026-11-22',
              ),
            ],
        ),
        f.FakeNutritionRepository(),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester
            .widget<FloatingGlassNavBar>(find.byType(FloatingGlassNavBar))
            .currentIndex,
        2,
      );
      expect(find.text('٣ من ٨ أكواب'), findsOneWidget);
      expect(find.text('٧٥٠ من ٢,٠٠٠ مل'), findsOneWidget);
      expect(find.text('٨ من ٣ أكواب'), findsNothing);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .375,
      );
    },
  );
}
