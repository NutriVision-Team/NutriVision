import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'screens_smoke_test.dart' show SmokeNutritionRepository;

class MixedStatusRecords extends SmokeNutritionRepository {
  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async => [
    for (final status in ['confirmed', 'draft'])
      MealEntryModel(
        mealId: status,
        userId: uid,
        dateKey: '2026-11-25',
        consumedAt: DateTime(2026, 11, 25),
        mealType: 'lunch',
        inputMethod: 'manual',
        title: status,
        items: [],
        totalCalories: 100,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        totalFiber: null,
        totalSugar: null,
        totalSodium: null,
        analysisStatus: status,
      ),
    MealEntryModel(
      mealId: 'foreign',
      userId: 'other',
      dateKey: '2026-11-25',
      consumedAt: DateTime(2026, 11, 25),
      mealType: 'lunch',
      inputMethod: 'manual',
      title: 'foreign',
      items: [],
      totalCalories: 500,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      totalFiber: null,
      totalSugar: null,
      totalSodium: null,
      analysisStatus: 'confirmed',
    ),
  ];
}

class OfflineRecords extends SmokeNutritionRepository {
  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async => throw StateError('offline');
}

void main() {
  test(
    'local emergency response remains available when diary is offline',
    () async {
      final c = CoachCubit(
        userId: 'u',
        store: SessionCoachStore(ownerUid: 'u', currentUid: () => 'u'),
        nutrition: OfflineRecords(),
        locale: 'en',
      );
      await c.load();
      expect(c.state.status, CoachStatus.ready);
      await c.send('I have chest pain');
      expect(c.state.entries.last.origin, 'safety');
      expect(c.state.sendFailure, false);
      await c.send('', quickId: 'analyze_week');
      expect(c.state.sendFailure, true);
      await c.close();
    },
  );
  test('Coach numeric reviews contain only confirmed owner meals', () async {
    final c = CoachCubit(
      userId: 'u',
      store: SessionCoachStore(ownerUid: 'u', currentUid: () => 'u'),
      nutrition: MixedStatusRecords(),
      locale: 'en',
      clock: () => DateTime(2026, 11, 25),
    );
    final review = await c.readLocalReview();
    expect(review.meals.length, 1);
    expect(review.meals.single.mealId, 'confirmed');
    await c.close();
  });
  for (final pair in [
    ('en', 'I have chest pain'),
    ('ar', 'عندي ألم في الصدر'),
    ('en', 'change my dose'),
    ('ar', 'عاوز جرعة دواء'),
  ]) {
    test('local-only coach safety preflight ${pair.$1} ${pair.$2}', () async {
      final c = CoachCubit(
        userId: 'u',
        store: SessionCoachStore(ownerUid: 'u', currentUid: () => 'u'),
        nutrition: SmokeNutritionRepository(),
        locale: pair.$1,
      );
      await c.load();
      await c.send(pair.$2);
      expect(c.state.entries.last.origin, 'safety');
      expect(c.state.entries.last.stats, isEmpty);
      expect(c.state.sendFailure, false);
      await c.close();
    });
  }
}
