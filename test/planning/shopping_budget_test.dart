import 'package:flutter_test/flutter_test.dart';
import 'package:clock/clock.dart';
import 'package:sufradepi/features/shopping/presentation/cubit/shopping_cubit.dart';
import 'package:sufradepi/features/shopping/data/shopping_repository.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import '../features/progress/progress_test.dart' show FakeNutritionRepository;
import 'support/planning_memory_firestore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'budget uses active target, rejects missing target and account switch',
    () async {
      final repo = FakeNutritionRepository();
      var uid = 'u';
      final c = ShoppingCubit(
        userId: 'u',
        currentUid: () => uid,
        nutrition: repo,
        repository: FirestoreShoppingRepository(PlanningMemoryFirestore()),
        foods: LocalFoodDataSource(),
      );
      expect(await c.remainingToday(), isNull);
      repo.activeProfile = NutritionProfileModel(
        profileId: 'fixture',
        gender: 'male',
        dateOfBirth: DateTime(2000),
        heightCm: 180,
        currentWeightKg: 80,
        targetWeightKg: 75,
        activityLevel: 'sedentary',
        nutritionGoal: 'maintain',
        dailyCalorieTarget: 197,
        proteinTarget: 100,
        carbsTarget: 100,
        fatTarget: 50,
      );
      await withClock(Clock.fixed(DateTime(2026, 11, 25)), () async {
        expect(await c.remainingToday(), 197);
      });
      uid = 'other';
      expect(await c.remainingToday(), isNull);
      await c.close();
    },
  );
}
