import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'package:sufradepi/data/models/weight_log_model.dart';
import 'package:sufradepi/features/progress/presentation/cubit/weight_cubit.dart';
import 'progress_test.dart' as f;

class Stored extends f.FakeNutritionRepository {
  int writes = 0;
  bool drop = false;
  Completer<void>? beforeRead;
  @override
  Future<List<NutritionProfileModel>> getNutritionProfiles(String uid) async {
    await beforeRead?.future;
    return super.getNutritionProfiles(uid);
  }

  @override
  Future<void> saveNutritionProfile(String uid, NutritionProfileModel p) async {
    writes++;
    if (!drop) activeProfile = p;
  }
}

NutritionProfileModel profile({
  String goal = 'lose',
  List<String> restrictions = const [],
}) => NutritionProfileModel(
  profileId: 'primary',
  gender: 'male',
  dateOfBirth: DateTime(2000),
  heightCm: 175,
  currentWeightKg: 90,
  targetWeightKg: 80,
  activityLevel: 'moderate',
  nutritionGoal: goal,
  dailyCalorieTarget: 2397,
  proteinTarget: 180,
  carbsTarget: 240,
  fatTarget: 80,
  allergies: const ['sesame'],
  dietaryPreferences: const ['vegetarian'],
  healthRestrictions: restrictions,
  createdAt: DateTime(2026),
);
void main() {
  test(
    'goal uses latest weight, persists/reloads and preserves history and health fields',
    () async {
      final n = Stored()..activeProfile = profile();
      final w = f.FakeWaterWeightRepository()
        ..weight = [
          WeightLogModel(
            weightId: 'old',
            weightKg: 90,
            recordedAt: DateTime(2026, 11, 1),
            dateKey: '2026-11-01',
          ),
          WeightLogModel(
            weightId: 'new',
            weightKg: 88,
            recordedAt: DateTime(2026, 11, 20),
            dateKey: '2026-11-20',
          ),
        ];
      final c = WeightCubit(
        waterWeightRepository: w,
        nutritionRepository: n,
        uid: 'u',
        currentUid: () => 'u',
        clock: () => DateTime(2026, 11, 24),
      );
      await c.load();
      final p = c.previewGoal(78, 'lose');
      expect(p.currentWeightKg, 88);
      expect(p.allergies, ['sesame']);
      expect(p.createdAt, DateTime(2026));
      expect(await c.saveGoal(p), true);
      expect(c.state.targetWeight, 78);
      expect(w.weight.length, 2);
      expect(w.weight.first.weightKg, 90);
      expect(n.writes, 1);
      expect(p.dailyCalorieTarget, isNot(2397));
      await c.close();
    },
  );
  test(
    'invalid direction/nonfinite and disclosed restriction reject without writes',
    () async {
      final n = Stored()..activeProfile = profile();
      final c = WeightCubit(
        waterWeightRepository: f.FakeWaterWeightRepository(),
        nutritionRepository: n,
        uid: 'u',
        currentUid: () => 'u',
      );
      await c.load();
      for (final p in [
        (95.0, 'lose'),
        (70.0, 'gain'),
        (80.0, 'maintain'),
        (double.nan, 'lose'),
      ]) {
        expect(() => c.previewGoal(p.$1, p.$2), throwsStateError);
      }
      n.activeProfile = profile(restrictions: ['kidney']);
      await c.load();
      expect(() => c.previewGoal(70, 'lose'), throwsStateError);
      expect(n.writes, 0);
      await c.close();
    },
  );
  test('changed account during fresh read cannot save', () async {
    var owner = 'u';
    final n = Stored()..activeProfile = profile();
    final c = WeightCubit(
      waterWeightRepository: f.FakeWaterWeightRepository(),
      nutritionRepository: n,
      uid: 'u',
      currentUid: () => owner,
    );
    await c.load();
    final p = c.previewGoal(75, 'lose');
    n.beforeRead = Completer<void>();
    final save = c.saveGoal(p);
    owner = 'other';
    n.beforeRead!.complete();
    expect(await save, false);
    expect(n.writes, 0);
    await c.close();
  });
  test('missing write readback is not called saved', () async {
    final n = Stored()
      ..activeProfile = profile()
      ..drop = true;
    final c = WeightCubit(
      waterWeightRepository: f.FakeWaterWeightRepository(),
      nutritionRepository: n,
      uid: 'u',
      currentUid: () => 'u',
    );
    await c.load();
    expect(await c.saveGoal(c.previewGoal(75, 'lose')), false);
    expect(c.state.failed, true);
    expect(c.state.targetWeight, 80);
    await c.close();
  });
}
