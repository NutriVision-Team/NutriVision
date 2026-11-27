import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'screens_smoke_test.dart' show SmokeNutritionRepository;

void main() {
  test(
    'coach refreshes explicitly chosen water goal without inventing default',
    () async {
      double? goal;
      final c = CoachCubit(
        userId: 'u',
        store: SessionCoachStore(ownerUid: 'u', currentUid: () => 'u'),
        nutrition: SmokeNutritionRepository(),
        locale: 'en',
        loadWaterTarget: () async => goal,
      );
      expect((await c.readLocalReview()).waterTargetMl, isNull);
      goal = 1750;
      expect((await c.readLocalReview()).waterTargetMl, 1750);
      goal = 2200;
      expect((await c.readLocalReview()).waterTargetMl, 2200);
      goal = double.infinity;
      expect((await c.readLocalReview()).waterTargetMl, isNull);
      await c.close();
    },
  );
}
