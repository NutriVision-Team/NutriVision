import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'package:sufradepi/features/home/presentation/cubit/home_cubit.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import '../goldens/milestone1_screens_test.dart' show Harness;

DailyLogModel water(double amount) => DailyLogModel(
  dateKey: '2026-11-22',
  timezone: 'Africa/Cairo',
  totalCalories: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  totalFiber: 0,
  totalSugar: 0,
  totalSodium: 0,
  calorieTarget: 2000,
  proteinTarget: 100,
  carbsTarget: 200,
  fatTarget: 60,
  waterIntakeMl: amount,
  mealCount: 0,
);

void main() {
  for (final useGo in [false, true]) {
    testWidgets('Home reloads after destination ${useGo ? 'go' : 'pop'}', (
      t,
    ) async {
      final h = await Harness.signedIn();
      h.nutritionRepository.logs = [water(750)];
      await t.pumpWidget(
        h.wrap(
          const HomeScreen(),
          additionalRoutes: [
            GoRoute(
              path: '/water',
              builder: (c, _) => Scaffold(
                body: TextButton(
                  onPressed: () {
                    h.nutritionRepository.logs = [water(1000)];
                    if (useGo) {
                      c.go('/');
                    } else {
                      c.pop();
                    }
                  },
                  child: const Text('Save and return'),
                ),
              ),
            ),
          ],
        ),
      );
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      final router = GoRouter.of(t.element(find.byType(HomeScreen)));
      router.push('/water');
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.tap(find.text('Save and return'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.pump();
      expect((h.homeCubit.state as HomeLoaded).dailyLog!.waterIntakeMl, 1000);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await h.dispose();
    });
  }
}
