import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'package:sufradepi/data/models/user_profile_model.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/data/repositories/user_repository.dart';
import 'package:sufradepi/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';

class _FakeNutritionRepository implements NutritionRepository {
  NutritionProfileModel? saved;
  Completer<void>? gate;
  int writes = 0;

  @override
  Future<void> saveNutritionProfile(
    String uid,
    NutritionProfileModel profile,
  ) async {
    writes++;
    saved = profile;
    await gate?.future;
  }

  @override
  Future<List<NutritionProfileModel>> getNutritionProfiles(String uid) async =>
      [];

  @override
  Future<void> saveMealEntry(String uid, MealEntryModel meal) async {}

  @override
  Future<void> deleteMealEntry(String uid, String mealId) async {}

  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async => [];

  @override
  Future<void> upsertDailyLog(String uid, DailyLogModel dailyLog) async {}

  @override
  Future<DailyLogModel?> getDailyLog(String uid, String dateKey) async => null;

  @override
  Future<List<DailyLogModel>> getDailyLogs(
    String uid, {
    int limit = 30,
  }) async => [];
}

class _FakeUserRepository implements UserRepository {
  UserProfileModel? user;

  @override
  Future<UserProfileModel?> getCurrentUser() async => user;

  @override
  Future<void> upsertUser(UserProfileModel user) async {
    this.user = user;
  }
}

ProfileSetupData validData() => ProfileSetupData(
  gender: 'male',
  dateOfBirth: DateTime(2000, 8, 7),
  heightCm: 175,
  currentWeightKg: 90,
  targetWeightKg: 80,
  activityLevel: 'moderate',
  nutritionGoal: 'lose',
);

void main() {
  test(
    'explicit clearing invalidates numeric steps without erasing other fields',
    () {
      final original = validData();
      final height = original.copyWith(clearHeight: true);
      final weight = original.copyWith(clearCurrentWeight: true);
      final target = original.copyWith(clearTargetWeight: true);
      expect(height.heightCm, isNull);
      expect(height.isStepValid(2), isFalse);
      expect(height.currentWeightKg, 90);
      expect(weight.currentWeightKg, isNull);
      expect(weight.isStepValid(3), isFalse);
      expect(weight.heightCm, 175);
      expect(target.targetWeightKg, isNull);
      expect(target.isStepValid(4), isFalse);
      expect(target.activityLevel, 'moderate');
      expect(height.copyWith(heightCm: 180).isStepValid(2), isTrue);
    },
  );

  late ProfileSetupCubit cubit;
  late _FakeNutritionRepository nutritionRepository;
  late _FakeUserRepository userRepository;

  setUp(() {
    nutritionRepository = _FakeNutritionRepository();
    userRepository = _FakeUserRepository();
    cubit = ProfileSetupCubit(
      nutritionRepository: nutritionRepository,
      userRepository: userRepository,
    );
  });

  tearDown(() => cubit.close());

  test(
    'account switch during save cannot complete next user or stale state',
    () async {
      String? uid = 'uid-1';
      final scoped = ProfileSetupCubit(
        nutritionRepository: nutritionRepository,
        userRepository: userRepository,
        currentUid: () => uid,
      );
      scoped.ownerChanged(uid);
      scoped.update(validData());
      nutritionRepository.gate = Completer<void>();
      final first = scoped.finish('uid-1');
      final second = await scoped.finish('uid-1');
      expect(second, isNull);
      expect(nutritionRepository.writes, 1);
      uid = 'uid-2';
      scoped.ownerChanged(uid);
      userRepository.user = const UserProfileModel(
        uid: 'uid-2',
        displayName: '',
        onboardingCompleted: false,
      );
      nutritionRepository.gate!.complete();
      expect(await first, isNull);
      expect(userRepository.user!.onboardingCompleted, isFalse);
      expect(scoped.state.step, 0);
      expect(scoped.state.data.heightCm, isNull);
      expect(scoped.state.status, isA<SetupEditing>());
      await scoped.close();
    },
  );
  test(
    'mismatched repository user never becomes onboarding complete',
    () async {
      userRepository.user = const UserProfileModel(
        uid: 'other',
        displayName: '',
        onboardingCompleted: false,
      );
      cubit.update(validData());
      expect(await cubit.finish('uid-1'), isNull);
      expect(userRepository.user!.onboardingCompleted, isFalse);
      expect(cubit.state.status, isA<SetupFailed>());
    },
  );
  test('starts at step 0 and blocks advancing without data', () {
    expect(cubit.state.step, 0);
    expect(cubit.canAdvance, isFalse);
    cubit.next();
    expect(cubit.state.step, 0);
  });

  test('step validation gates next()', () {
    cubit.update(const ProfileSetupData(gender: 'male'));
    expect(cubit.canAdvance, isTrue);
    cubit.next();
    expect(cubit.state.step, 1);
    // Step 1 (date of birth) not filled yet.
    expect(cubit.canAdvance, isFalse);
    cubit.next();
    expect(cubit.state.step, 1);
  });

  test('entered data survives back/forward navigation', () {
    final data = validData();
    cubit.update(data);
    for (var i = 0; i < 6; i++) {
      cubit.next();
    }
    expect(cubit.state.step, 6);
    cubit.back();
    cubit.back();
    expect(cubit.state.step, 4);
    expect(cubit.state.data.heightCm, 175);
    expect(cubit.state.data.nutritionGoal, 'lose');
    cubit.next();
    expect(cubit.state.step, 5);
    expect(cubit.state.data.activityLevel, 'moderate');
  });

  test('does not advance past the last step', () {
    cubit.update(validData());
    for (var i = 0; i < 20; i++) {
      cubit.next();
    }
    expect(cubit.state.step, ProfileSetupState.totalSteps - 1);
  });

  test('finish computes the plan and persists the profile', () async {
    userRepository.user = const UserProfileModel(
      uid: 'uid-1',
      displayName: 'Mostafa',
      onboardingCompleted: false,
    );
    cubit.update(validData());
    final plan = await cubit.finish('uid-1');
    expect(plan, isNotNull);
    expect(cubit.state.status, isA<SetupSaved>());
    expect(nutritionRepository.saved, isNotNull);
    expect(nutritionRepository.saved!.dailyCalorieTarget, plan!.dailyCalories);
    expect(userRepository.user!.onboardingCompleted, isTrue);
  });

  test('finish without a valid step returns null', () async {
    final plan = await cubit.finish('uid-1');
    expect(plan, isNull);
  });
}
