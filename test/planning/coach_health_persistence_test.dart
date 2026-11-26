import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'package:sufradepi/features/health_coach/data/coach_health_store.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import 'screens_smoke_test.dart' show SmokeNutritionRepository;

class MemoryHealth extends CoachHealthStore {
  SavedCoachChoices value = const SavedCoachChoices();
  int writes = 0;
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<SavedCoachChoices> load() async {
    await gate?.future;
    if (fail) throw StateError('offline');
    return value;
  }

  @override
  Future<void> save(SavedCoachChoices v, String day) async {
    if (fail) throw StateError('offline');
    writes++;
    value = v;
  }

  @override
  Future<void> deleteDay(String day) async {
    value = SavedCoachChoices(
      profile: value.profile,
      goals: value.goals,
      habits: value.habits,
      fields: value.fields,
      checkins: Map.of(value.checkins)..remove(day),
    );
  }

  @override
  Future<void> deleteAll() async {
    value = const SavedCoachChoices();
  }
}

void main() {
  late String owner;
  late MemoryHealth store;
  CoachCubit make() => CoachCubit(
    userId: 'u1',
    currentUid: () => owner,
    healthStore: store,
    store: SessionCoachStore(ownerUid: 'u1', currentUid: () => owner),
    nutrition: SmokeNutritionRepository(),
    locale: 'en',
    clock: () => DateTime(2026, 11, 24),
  );
  setUp(() {
    owner = 'u1';
    store = MemoryHealth();
  });
  test('no auto writes, only selected fields, reopen and delete', () async {
    final c = make();
    await c.loadSavedHealth();
    c.updateHealthChoices(
      const HealthCoachConsent(),
      const HealthCoachProfile(
        age: 26,
        disclosedConditions: ['private'],
        preferredFoods: ['lentils'],
        goals: ['food variety'],
      ),
    );
    c.chooseHabit('log_meal', true);
    c.markHabit('log_meal', true);
    expect(store.writes, 0);
    await c.saveHealthFields({'preferredFoods', 'goals', 'habits'});
    expect(store.value.profile, {
      'preferredFoods': ['lentils'],
    });
    expect(store.value.fields, contains('habits'));
    expect(store.value.profile.containsKey('conditions'), false);
    expect(c.healthConsent.profileContext, false);
    await c.close();
    final reopened = make();
    await reopened.loadSavedHealth();
    expect(reopened.healthProfile.preferredFoods, ['lentils']);
    expect(reopened.healthProfile.age, isNull);
    expect(reopened.habitDone('log_meal'), true);
    await reopened.deleteHealthDay('2026-11-24');
    expect(reopened.habitDone('log_meal'), false);
    await reopened.deleteSavedHealth();
    expect(store.value.fields, isEmpty);
    await reopened.close();
  });
  test(
    'failed load does not pretend empty saved state, owner switch rejects late load',
    () async {
      final c = make();
      store.fail = true;
      await c.loadSavedHealth();
      expect(c.healthLoadFailed, true);
      store.fail = false;
      store.gate = Completer<void>();
      final f = c.loadSavedHealth();
      owner = 'u2';
      store.gate!.complete();
      await f;
      expect(c.savedHealth.fields, isEmpty);
      expect(() => c.chooseHabit('log_meal', true), throwsStateError);
      await c.close();
    },
  );
  test(
    'failed initial load blocks replacement until explicit reload',
    () async {
      final c = make();
      store.fail = true;
      await c.loadSavedHealth();
      store.fail = false;
      await expectLater(c.saveHealthFields({'goals'}), throwsStateError);
      expect(store.writes, 0);
      await c.loadSavedHealth();
      await c.saveHealthFields({'goals'});
      expect(store.writes, 1);
      await c.close();
    },
  );
  test(
    'failed manual save has no confirmed state and no automatic retry',
    () async {
      final c = make();
      store.fail = true;
      await expectLater(c.saveHealthFields({'goals'}), throwsStateError);
      expect(c.savedHealth.fields, isEmpty);
      expect(store.writes, 0);
      await c.close();
    },
  );
}
