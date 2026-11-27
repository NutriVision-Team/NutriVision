import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/user_profile_model.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/features/gamification/domain/progression_engine.dart';
import 'package:sufradepi/features/gamification/data/progression_repository.dart';
import '../features/progress/progress_test.dart' show FakeNutritionRepository;

class Config implements ProgressionConfigSource {
  Future<void> Function()? wait;
  @override
  Future<ProgressionConfig> load() async {
    await wait?.call();
    return ProgressionConfig.fromJson(
      jsonDecode(File('assets/data/progression.json').readAsStringSync()),
    );
  }
}

void main() {
  late FakeNutritionRepository meals;
  late String uid;
  late Config config;
  ReadOnlyProgressionRepository repo({UserProfileModel? profile}) =>
      ReadOnlyProgressionRepository(
        nutrition: meals,
        currentUid: () => uid,
        profile: () => profile,
        configSource: config,
      );
  setUp(() {
    meals = FakeNutritionRepository();
    uid = 'u';
    config = Config();
  });
  test('completed profile has no invented activity date or streak', () async {
    final s = await repo(
      profile: const UserProfileModel(
        uid: 'u',
        displayName: 'x',
        onboardingCompleted: true,
      ),
    ).load('u', '2026-11-24');
    expect(s.profile.xp, 20);
    expect(s.profile.activeDays, isEmpty);
    expect(s.profile.currentStreak, 0);
    expect(s.profile.badges, {'journey'});
  });
  test('account changes during await abort before returning data', () async {
    final gate = Completer<void>();
    config.wait = () => gate.future;
    final future = repo().load('u', '2026-11-24');
    uid = 'v';
    gate.complete();
    await expectLater(future, throwsStateError);
  });
  test('profile mismatch fails closed', () async {
    await expectLater(
      repo(
        profile: const UserProfileModel(uid: 'other', displayName: 'x'),
      ).load('u', '2026-11-24'),
      throwsStateError,
    );
  });
  test('source read failure is not zero progress', () async {
    meals.failReads = true;
    await expectLater(repo().load('u', '2026-11-24'), throwsStateError);
  });
  test('no owner means no read', () async {
    uid = '';
    await expectLater(repo().load('u', '2026-11-24'), throwsStateError);
  });
  test(
    'unconnected evidence cannot unlock recipe or learning badges',
    () async {
      final s = await repo().load('u', '2026-11-24');
      expect(s.profile.badges, isNot(contains('learner')));
      expect(s.profile.badges, isNot(contains('cook')));
    },
  );
  test(
    'another account meal record is not filtered into a plausible result',
    () async {
      meals.meals = [
        MealEntryModel(
          mealId: 'm',
          userId: 'other',
          dateKey: '2026-11-24',
          consumedAt: DateTime(2026, 11, 24),
          mealType: 'lunch',
          inputMethod: 'manual',
          title: 'meal',
          items: [],
          totalCalories: 100,
          totalProtein: null,
          totalCarbs: null,
          totalFat: null,
          totalFiber: null,
          totalSugar: null,
          totalSodium: null,
          analysisStatus: 'confirmed',
        ),
      ];
      await expectLater(repo().load('u', '2026-11-24'), throwsStateError);
    },
  );
}
