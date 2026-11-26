import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/features/planner/data/planner_repository.dart';
import 'package:sufradepi/features/planner/domain/weekly_plan_generator.dart';
import 'package:sufradepi/features/planner/presentation/cubit/planner_cubit.dart';
import 'owner_lifecycle_test.dart' show profile;
import 'support/planning_memory_firestore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'source catalog generate swap close reopen readback and owner isolation',
    () async {
      final db = PlanningMemoryFirestore();
      final nutrition = FirestoreNutritionRepository(db);
      await nutrition.saveNutritionProfile('qa', profile());
      final foods = await LocalFoodDataSource().getAll();
      final generator = WeeklyPlanGenerator(catalog: foods);
      final repo = FirestorePlannerRepository(db);
      var seed = 1;
      PlannerCubit make(String uid) => PlannerCubit(
        userId: uid,
        currentUid: () => uid,
        repository: repo,
        nutrition: nutrition,
        generator: generator,
        today: DateTime(2026, 11, 25),
        seedProvider: () => seed++,
      );
      final c = make('qa');
      expect(await c.generate(), true);
      final original = c.state.plan!;
      final meal = original.meals.first;
      await c.replaceMeal(meal.mealId);
      final edited = c.state.plan!;
      expect(edited.meals.first.foods, isNot(orderedEquals(meal.foods)));
      final snapshot = edited.meals.map((m) => m.toMap()).toList();
      await c.close();
      final reopened = make('qa');
      await reopened.load();
      expect(
        reopened.state.plan!.meals.map((m) => m.toMap()).toList(),
        snapshot,
      );
      final other = make('another');
      await other.load();
      expect(other.state.plan, isNull);
      await reopened.close();
      await other.close();
    },
  );
}
