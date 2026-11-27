import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/utils/decimal_input.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/features/meal_log/domain/edit_logged_meal.dart';
import 'package:sufradepi/features/meal_log/presentation/cubit/meal_detail_cubit.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_detail_screen.dart';
import '../goldens/milestone1_screens_test.dart' show FakeNutritionRepository;
import 'meal_persistence_test.dart' show record;

class DetailRepository extends FakeNutritionRepository {
  Completer<void>? deleteGate;
  Completer<List<MealEntryModel>>? readGate;
  bool deleteFails = false;
  int deleteCalls = 0, saveCalls = 0, readCalls = 0;
  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async {
    readCalls++;
    return readGate == null ? meals : await readGate!.future;
  }

  @override
  Future<void> deleteMealEntry(String uid, String id) async {
    deleteCalls++;
    await deleteGate?.future;
    if (deleteFails) throw StateError('offline');
    await super.deleteMealEntry(uid, id);
  }

  @override
  Future<void> saveMealEntry(String uid, MealEntryModel meal) async {
    saveCalls++;
    await super.saveMealEntry(uid, meal);
  }
}

void main() {
  test(
    'rescaling uses original source amounts without losing unknown nutrients or identity',
    () {
      final original = record(protein: null);
      final updated = editLoggedMeal(
        original,
        title: '  New title  ',
        mealType: 'dinner',
        notes: ' note ',
        weightsInGrams: [250],
        updatedAt: DateTime(2026, 11, 22),
      );
      expect(updated.totalCalories, 500);
      expect(updated.totalProtein, isNull);
      expect(updated.totalSugar, isNull);
      expect(updated.items.single.weightInGrams, 250);
      expect(updated.items.single.dataSource, original.items.single.dataSource);
      expect(updated.mealId, original.mealId);
      expect(updated.userId, original.userId);
      expect(updated.title, 'New title');
      expect(updated.notes, 'note');
      expect(original.items.single.weightInGrams, 100);
    },
  );
  test(
    'edits reject invalid names, weights, ingredient counts and meal types',
    () {
      final original = record();
      for (final weights in [
        [0.0],
        [double.nan],
        [10001.0],
        <double>[],
      ]) {
        expect(
          () => editLoggedMeal(
            original,
            title: 'Meal',
            mealType: 'lunch',
            notes: null,
            weightsInGrams: weights,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => editLoggedMeal(
          original,
          title: ' ',
          mealType: 'lunch',
          notes: null,
        ),
        throwsArgumentError,
      );
      expect(
        () => editLoggedMeal(
          original,
          title: 'Meal',
          mealType: 'other',
          notes: null,
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'changing consumed date recalculates date key without changing owner',
    () {
      final edited = editLoggedMeal(
        record(),
        title: 'Meal',
        mealType: 'lunch',
        notes: null,
        consumedAt: DateTime(2026, 11, 21),
      );
      expect(edited.dateKey, '2026-11-21');
      expect(edited.userId, 'u1');
    },
  );
  test(
    'Arabic and Persian decimal quantities parse without ambiguous grouping',
    () {
      expect(parseDecimalInput('٢٥٠٫٥'), 250.5);
      expect(parseDecimalInput('۲۵۰'), 250);
      expect(parseDecimalInput('100,5'), 100.5);
      expect(parseDecimalInput('1,000'), isNull);
      expect(parseDecimalInput('-1'), isNull);
      expect(parseDecimalInput('NaN'), isNull);
    },
  );
  test('detail links have absolute paths and preserve ID/date parameters', () {
    final link = Uri.parse(
      MealDetailScreen.locationFor(record(id: 'meal with space')),
    );
    expect(link.pathSegments, ['meal', 'meal with space']);
    expect(link.path, startsWith('/meal/'));
    expect(link.queryParameters['date'], '2026-11-20');
  });
  test(
    'detail reads reject wrong owner and wrong date even if repository returns them',
    () async {
      final r = DetailRepository()
        ..meals = [record(uid: 'other'), record(day: 21)];
      final c = MealDetailCubit(
        repository: r,
        uid: 'u1',
        mealId: 'm1',
        dateKey: '2026-11-20',
        currentUid: () => 'u1',
      );
      await c.load();
      expect(c.state.status, MealDetailStatus.missing);
      await c.close();
    },
  );
  test(
    'detail delete ignores duplicate taps and clears the record after success',
    () async {
      final r = DetailRepository()
        ..meals = [record()]
        ..deleteGate = Completer<void>();
      final c = MealDetailCubit(
        repository: r,
        uid: 'u1',
        mealId: 'm1',
        dateKey: '2026-11-20',
        currentUid: () => 'u1',
      );
      await c.load();
      final pending = c.delete();
      await c.delete();
      expect(r.deleteCalls, 1);
      r.deleteGate!.complete();
      await pending;
      expect(c.state.status, MealDetailStatus.deleted);
      expect(r.meals, isEmpty);
      await c.close();
    },
  );
  test(
    'failed deletion retains the meal and can be retried without a fake success',
    () async {
      final r = DetailRepository()
        ..meals = [record()]
        ..deleteFails = true;
      final c = MealDetailCubit(
        repository: r,
        uid: 'u1',
        mealId: 'm1',
        dateKey: '2026-11-20',
        currentUid: () => 'u1',
      );
      await c.load();
      await c.delete();
      expect(c.state.mutationFailed, isTrue);
      expect(c.state.meal, isNotNull);
      r.deleteFails = false;
      await c.delete();
      expect(c.state.status, MealDetailStatus.deleted);
      await c.close();
    },
  );
  test(
    'account change while detail loads clears the old account result',
    () async {
      final r = DetailRepository()
        ..readGate = Completer<List<MealEntryModel>>();
      String? uid = 'u1';
      final c = MealDetailCubit(
        repository: r,
        uid: 'u1',
        mealId: 'm1',
        dateKey: '2026-11-20',
        currentUid: () => uid,
      );
      final pending = c.load();
      uid = 'other';
      r.readGate!.complete([record()]);
      await pending;
      expect(c.state.status, MealDetailStatus.expired);
      expect(c.state.meal, isNull);
      await c.close();
    },
  );
  test('a replacement cannot change meal ownership or document ID', () async {
    final r = DetailRepository()..meals = [record()];
    final c = MealDetailCubit(
      repository: r,
      uid: 'u1',
      mealId: 'm1',
      dateKey: '2026-11-20',
      currentUid: () => 'u1',
    );
    await c.load();
    await c.save(record(id: 'different'));
    await c.save(record(uid: 'other'));
    expect(r.saveCalls, 0);
    expect(c.state.mutationFailed, isTrue);
    await c.close();
  });
}
