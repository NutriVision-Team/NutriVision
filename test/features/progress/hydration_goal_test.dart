import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:sufradepi/features/home/presentation/cubit/home_cubit.dart';
import 'package:sufradepi/features/progress/presentation/screens/water_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/features/progress/data/hydration_goal_store.dart';
import 'package:sufradepi/features/progress/presentation/cubit/water_cubit.dart';
import 'package:sufradepi/features/progress/presentation/cubit/progress_cubit.dart';
import 'progress_test.dart' as f;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'water goal dialog saves the explicit choice without dismissal errors',
    (tester) async {
      await f.pumpScreen(
        tester,
        WaterScreen(waterWeightRepository: f.FakeWaterWeightRepository()),
        f.FakeNutritionRepository(),
      );
      await tester.scrollUntilVisible(
        find.text('غيّر هدف الميّه'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('غيّر هدف الميّه'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.enterText(find.byType(TextField), '2300');
      await tester.tap(find.text('احفظ'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(await HydrationGoalStore.read('u1'), 2300);
      expect(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(WaterScreen)),
          ).waterGoalChosenNote,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test(
    'explicit water choice is separate per account and survives a new load',
    () async {
      expect(await HydrationGoalStore.read('u'), isNull);
      await HydrationGoalStore.save('u', 2300);
      expect(await HydrationGoalStore.read('u'), 2300);
      expect(await HydrationGoalStore.read('other'), isNull);
      final w = WaterCubit(
        waterWeightRepository: f.FakeWaterWeightRepository(),
        nutritionRepository: f.FakeNutritionRepository(),
        uid: 'u',
        currentUid: () => 'u',
      );
      await w.load();
      expect(w.state.goalMl, 2300);
      expect(w.state.goalChosen, isTrue);
      await w.chooseGoal(1750);
      expect(w.state.goalMl, 1750);
      final p = ProgressCubit(
        nutritionRepository: f.FakeNutritionRepository(),
        uid: 'u',
        currentUid: () => 'u',
      );
      await p.load();
      expect(p.state.hydrationGoalMl, 1750);
      final home = HomeCubit(
        userRepository: f.FakeUserRepository(),
        nutritionRepository: f.FakeNutritionRepository(),
      );
      await home.load('u1');
      expect((home.state as HomeLoaded).hydrationGoalMl, isNull);
      await HydrationGoalStore.save('u1', 1750);
      await home.load('u1');
      expect((home.state as HomeLoaded).hydrationGoalMl, 1750);
      await home.close();
      await p.loadRange(DateTime(2026, 11, 1), DateTime(2026, 11, 2));
      expect(p.state.hydrationGoalMl, 1750);
      await p.close();
      await w.close();
    },
  );
  test('invalid or unowned goal cannot write', () async {
    for (final n in [0.0, -1.0, double.nan, double.infinity, 20001.0]) {
      await expectLater(HydrationGoalStore.save('u', n), throwsArgumentError);
    }
    await expectLater(HydrationGoalStore.save('', 2000), throwsArgumentError);
    expect(await HydrationGoalStore.read('u'), isNull);
    String? owner = 'u';
    final w = WaterCubit(
      waterWeightRepository: f.FakeWaterWeightRepository(),
      nutritionRepository: f.FakeNutritionRepository(),
      uid: 'u',
      currentUid: () => owner,
    );
    owner = 'other';
    await w.chooseGoal(2500);
    expect(await HydrationGoalStore.read('u'), isNull);
    await w.close();
  });
  test('default remains disclosed as not user chosen', () async {
    final w = WaterCubit(
      waterWeightRepository: f.FakeWaterWeightRepository(),
      nutritionRepository: f.FakeNutritionRepository(),
      uid: 'u',
      currentUid: () => 'u',
    );
    await w.load();
    expect(w.state.goalMl, 2000);
    expect(w.state.goalChosen, isFalse);
    await w.close();
  });
}
