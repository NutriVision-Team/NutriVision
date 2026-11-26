import 'package:sufradepi/data/models/weight_log_model.dart';
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'package:sufradepi/features/progress/presentation/cubit/weight_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/progress/data/water_weight_repository.dart';
import 'package:sufradepi/features/progress/domain/day_nutrition.dart';
import 'package:sufradepi/features/progress/presentation/cubit/water_cubit.dart';
import '../../support/memory_firestore.dart';
import 'progress_test.dart' as fixture;

class AmbiguousWater extends fixture.FakeWaterWeightRepository {
  final attempts = <({String? id, double amount, DateTime at})>[];
  bool first = true;
  @override
  Future<void> addWaterLog(
    String uid,
    double amount,
    DateTime at, {
    String? operationId,
  }) async {
    attempts.add((id: operationId, amount: amount, at: at));
    if (first) {
      first = false;
      throw StateError('Lost acknowledgement');
    }
  }
}

void main() {
  final at = DateTime.utc(2026, 11, 22, 12);
  NutritionProfileModel profile(double start, double target) =>
      NutritionProfileModel(
        profileId: 'p',
        gender: 'male',
        dateOfBirth: DateTime(2000),
        heightCm: 175,
        currentWeightKg: start,
        targetWeightKg: target,
        activityLevel: 'moderate',
        nutritionGoal: target < start ? 'lose' : 'gain',
        dailyCalorieTarget: 2000,
        proteinTarget: 100,
        carbsTarget: 200,
        fatTarget: 70,
      );
  List<WeightLogModel> weights(double start, double current) => [
    WeightLogModel(
      weightId: 'new',
      weightKg: current,
      recordedAt: DateTime(2026, 11, 22),
      dateKey: '2026-11-22',
    ),
    WeightLogModel(
      weightId: 'old',
      weightKg: start,
      recordedAt: DateTime(2026, 11, 1),
      dateKey: '2026-11-01',
    ),
  ];
  test(
    'weight progress follows the selected goal direction, not absolute distance',
    () {
      expect(
        WeightState(
          logs: weights(90, 95),
          activeProfile: profile(90, 80),
        ).goalFraction,
        0,
      );
      expect(
        WeightState(
          logs: weights(90, 85),
          activeProfile: profile(90, 80),
        ).goalFraction,
        .5,
      );
      expect(
        WeightState(
          logs: weights(60, 65),
          activeProfile: profile(60, 70),
        ).goalFraction,
        .5,
      );
      expect(
        WeightState(
          logs: weights(60, 55),
          activeProfile: profile(60, 70),
        ).goalFraction,
        0,
      );
    },
  );

  test(
    'water retries reuse ID and payload, increment once, and preserve meal fields',
    () async {
      final db = MemoryFirestore()
        ..seed('users/u1/daily_logs/2026-11-22', {
          'mealCount': 2,
          'totalCalories': 700.0,
          'waterIntakeMl': 100.0,
          'calorieTarget': 2100.0,
          'timezone': 'Africa/Cairo',
        });
      final repo = FirestoreWaterWeightRepository(db, activeUserId: () => 'u1');
      db.failAfterCommit = true;
      await expectLater(
        repo.addWaterLog('u1', 250, at, operationId: 'water_one'),
        throwsStateError,
      );
      await repo.addWaterLog('u1', 250, at, operationId: 'water_one');
      final daily = db.documents['users/u1/daily_logs/2026-11-22']!;
      expect(daily['waterIntakeMl'], 350);
      expect(daily['mealCount'], 2);
      expect(daily['totalCalories'], 700);
      expect(daily['calorieTarget'], 2100);
      expect(daily['timezone'], 'Africa/Cairo');
      expect(
        db.documents.keys.where((k) => k.contains('/water_logs/')),
        hasLength(1),
      );
      await expectLater(
        repo.addWaterLog('u1', 500, at, operationId: 'water_one'),
        throwsStateError,
      );
      expect(daily['waterIntakeMl'], 350);
    },
  );
  test(
    'water-only days do not fabricate nutrition totals or goal snapshots',
    () async {
      final db = MemoryFirestore();
      final repo = FirestoreWaterWeightRepository(db, activeUserId: () => 'u1');
      await repo.addWaterLog('u1', 250, at, operationId: 'water_two');
      final d = db.documents['users/u1/daily_logs/2026-11-22']!;
      expect(d.keys.toSet(), {'dateKey', 'waterIntakeMl', 'updatedAt'});
    },
  );
  test('water write failure is atomic before commit', () async {
    final db = MemoryFirestore()..failNextCommit = true;
    final repo = FirestoreWaterWeightRepository(db, activeUserId: () => 'u1');
    await expectLater(
      repo.addWaterLog('u1', 250, at, operationId: 'fail'),
      throwsStateError,
    );
    expect(db.documents, isEmpty);
  });
  test(
    'weight operation is idempotent and preserves its first timestamp',
    () async {
      final db = MemoryFirestore();
      final repo = FirestoreWaterWeightRepository(db, activeUserId: () => 'u1');
      db.failAfterCommit = true;
      await expectLater(
        repo.addWeightLog('u1', 80, at, operationId: 'weight_one'),
        throwsStateError,
      );
      final original = Map.of(db.documents['users/u1/weight_logs/weight_one']!);
      await repo.addWeightLog('u1', 80, at, operationId: 'weight_one');
      expect(db.documents['users/u1/weight_logs/weight_one'], original);
      await expectLater(
        repo.addWeightLog('u1', 81, at, operationId: 'weight_one'),
        throwsStateError,
      );
      expect(
        db.documents.keys.where((k) => k.contains('/weight_logs/')),
        hasLength(1),
      );
    },
  );
  test(
    'account changes before the transaction read completes prevent staging writes',
    () async {
      final db = MemoryFirestore();
      String? uid = 'u1';
      final repo = FirestoreWaterWeightRepository(db, activeUserId: () => uid);
      final pending = repo.addWaterLog('u1', 250, at, operationId: 'late');
      uid = 'u2';
      await expectLater(pending, throwsStateError);
      expect(db.documents, isEmpty);
    },
  );
  test(
    'invalid values and unsafe operation IDs cannot create records',
    () async {
      final db = MemoryFirestore();
      final repo = FirestoreWaterWeightRepository(db, activeUserId: () => 'u1');
      for (final value in [0.0, -1.0, double.nan, double.infinity]) {
        await expectLater(
          repo.addWaterLog('u1', value, at, operationId: 'bad'),
          throwsArgumentError,
        );
        await expectLater(
          repo.addWeightLog('u1', value, at, operationId: 'bad'),
          throwsArgumentError,
        );
      }
      await expectLater(
        repo.addWaterLog('u1', 250, at, operationId: '../other'),
        throwsArgumentError,
      );
      expect(db.documents, isEmpty);
    },
  );
  test(
    'water controller retains operation identity and rejects a different amount until retry',
    () async {
      final repo = AmbiguousWater();
      int tick = 0;
      final cubit = WaterCubit(
        waterWeightRepository: repo,
        nutritionRepository: fixture.FakeNutritionRepository(),
        uid: 'u1',
        currentUid: () => 'u1',
        clock: () => DateTime(2026, 11, 22, 12, tick++),
      );
      await cubit.addWater(250);
      expect(cubit.state.failed, isTrue);
      await cubit.addWater(500);
      expect(repo.attempts, hasLength(1));
      await cubit.retryOrLoad();
      expect(repo.attempts, hasLength(2));
      expect(repo.attempts.first, repo.attempts.last);
      expect(cubit.pendingAmount, isNull);
      await cubit.close();
    },
  );
  test(
    'historical intake cannot inherit a missing target or mismatched comparison window',
    () {
      final days = [
        DayNutrition(
          dateKey: '2026-11-21',
          date: DateTime(2026, 11, 21),
          tracked: true,
          calories: 1000,
          calorieTarget: 2000,
        ),
        DayNutrition(
          dateKey: '2026-11-22',
          date: DateTime(2026, 11, 22),
          tracked: true,
          calories: 3000,
        ),
      ];
      final average = NutritionAverages.of(days);
      expect(average.calories, 2000);
      expect(average.calorieTarget, isNull);
      expect(
        NutritionAverages.percent(average.calories, average.calorieTarget),
        isNull,
      );
    },
  );
}
