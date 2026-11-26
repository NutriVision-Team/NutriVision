import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/features/home/presentation/cubit/home_cubit.dart';
import 'package:sufradepi/features/health_coach/domain/coach_trusted_snapshot.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/features/camera_analysis/domain/photo_meal_resolver.dart';
import 'package:sufradepi/features/camera_analysis/domain/food_recognition_provider.dart';
import 'package:sufradepi/features/meal_log/domain/catalog_meal_draft.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/meal_log/presentation/cubit/meal_save_cubit.dart';
import 'package:sufradepi/features/progress/presentation/cubit/progress_cubit.dart';
import 'package:sufradepi/features/progress/data/water_weight_repository.dart';
import '../support/memory_firestore.dart';
import '../features/progress/progress_test.dart' show FakeUserRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'reviewed sourced portions survive retry/restart and reconcile Home, weekly report, local Coach cards, edit/delete and water',
    () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final key =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final db = MemoryFirestore();
      var owner = 'u';
      final repo = FirestoreNutritionRepository(db);
      final profile = NutritionProfileModel(
        profileId: 'p',
        gender: 'male',
        dateOfBirth: DateTime(2000),
        heightCm: 175,
        currentWeightKg: 80,
        targetWeightKg: 75,
        activityLevel: 'moderate',
        nutritionGoal: 'lose',
        dailyCalorieTarget: 2100,
        proteinTarget: 100,
        carbsTarget: 250,
        fatTarget: 70,
      );
      db.seed('users/u/nutrition_profiles/p', db.resolve(profile.toMap()));
      final foods = await LocalFoodDataSource().getAll();
      // This is a fixed candidate contract, NOT successful live recognition.
      final resolved = const PhotoMealResolver().resolve(
        const FoodRecognitionResult(
          items: [
            RecognitionCandidate(
              name: 'cooked rice',
              foodState: 'cooked',
              suggestedPortionGrams: 150,
            ),
          ],
        ),
        foods,
      );
      final draft = CatalogMealDraft(resolved.values);
      final saver = MealSaveCubit(
        draft: draft,
        repository: repo,
        uid: owner,
        currentUid: () => owner,
        mealType: 'lunch',
        inputMethod: 'photo',
        clock: () => now,
      );
      db.failAfterCommit = true;
      await saver.save();
      expect(saver.state, MealSaveStatus.failure);
      await saver.save();
      expect(saver.state, MealSaveStatus.saved);
      await saver.close();
      final restarted = FirestoreNutritionRepository(db);
      final first = (await restarted.getMealEntries(
        owner,
        dateKey: key,
      )).single;
      expect(first.totalCalories, 195);
      expect(first.items.single.dataSource, contains('USDA'));
      final water = FirestoreWaterWeightRepository(
        db,
        activeUserId: () => owner,
      );
      await water.addWaterLog(owner, 250, now, operationId: 'integrated-water');
      final home = HomeCubit(
        userRepository: FakeUserRepository(),
        nutritionRepository: restarted,
        clock: () => now,
      );
      final report = ProgressCubit(
        nutritionRepository: restarted,
        uid: owner,
        currentUid: () => owner,
        clock: () => now,
      );
      Future<void> check(double? calories, int meals) async {
        await home.load(owner);
        await report.load();
        expect(
          home.state,
          isA<HomeLoaded>(),
          reason: home.state is HomeFailure
              ? (home.state as HomeFailure).message
              : null,
        );
        final h = home.state as HomeLoaded;
        expect(h.eatenCalories, calories ?? 0);
        expect(h.dailyLog!.waterIntakeMl, 250);
        expect(h.todaysMeals.length, meals);
        expect(report.state.failed, false);
        expect(report.state.averages.trackedDays, meals == 0 ? 0 : 1);
        expect(report.state.averages.calories, calories);
        final snapshot = CoachTrustedSnapshot.forDay(
          dateKey: key,
          meals: h.todaysMeals,
          log: h.dailyLog,
        );
        expect(snapshot.metrics.first.value, calories);
        expect(snapshot.metrics.last.value, 250);
      }

      await check(195, 1);
      // Editing the existing ID must replace its amount, not add another meal.
      final edited = CatalogMealDraft([FoodPortion(resolved[0]!.food, 200)])
          .toMeal(
            uid: owner,
            id: first.mealId,
            at: now,
            mealType: 'lunch',
            inputMethod: 'photo',
          );
      await restarted.saveMealEntry(owner, edited);
      await check(260, 1);
      // Over-target is reported numerically, never clamped to a fake target.
      final over = CatalogMealDraft([FoodPortion(resolved[0]!.food, 2000)])
          .toMeal(
            uid: owner,
            id: first.mealId,
            at: now,
            mealType: 'lunch',
            inputMethod: 'photo',
          );
      await restarted.saveMealEntry(owner, over);
      await check(2600, 1);
      expect(report.state.days.last.adherence, closeTo(2600 / 2100, 0.0001));
      await restarted.deleteMealEntry(owner, first.mealId);
      await check(null, 0);
      expect(await restarted.getMealEntries('other'), isEmpty);
      await home.close();
      await report.close();
    },
  );
}
