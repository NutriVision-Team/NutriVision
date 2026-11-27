import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/features/diary/presentation/cubit/diary_cubit.dart';
import '../goldens/milestone1_screens_test.dart' show FakeNutritionRepository;
import 'recent_meals_cubit_test.dart' show meal;

class DelayedDiaryRepository extends FakeNutritionRepository {
  final pending = <String, Completer<List<MealEntryModel>>>{};
  bool failLog = false;
  @override
  Future<List<MealEntryModel>> getMealEntries(String uid, {String? dateKey}) =>
      (pending[dateKey!] = Completer<List<MealEntryModel>>()).future;
  @override
  Future<DailyLogModel?> getDailyLog(String uid, String dateKey) async {
    if (failLog) throw StateError('offline');
    return null;
  }
}

void main() {
  test(
    'diary filters wrong owners and wrong dates without changing totals',
    () async {
      final r = FakeNutritionRepository()
        ..meals = [
          meal(),
          meal(uid: 'other'),
          MealEntryModel.fromMap('other-date', {
            ...meal().toMap(),
            'dateKey': '2026-11-21',
            'createdAt': null,
            'updatedAt': null,
          }),
        ];
      final c = DiaryCubit(
        repository: r,
        uid: 'u1',
        currentUid: () => 'u1',
        date: DateTime(2026, 11, 20),
      );
      await c.load();
      expect(c.state.meals, hasLength(1));
      expect(c.state.calories, 400);
      expect(c.state.calorieTarget, isNull);
      await c.close();
    },
  );
  test('late response cannot replace a more recently selected date', () async {
    final r = DelayedDiaryRepository();
    final c = DiaryCubit(
      repository: r,
      uid: 'u1',
      currentUid: () => 'u1',
      date: DateTime(2026, 11, 20),
    );
    final first = c.load();
    final second = c.load(DateTime(2026, 11, 21));
    r.pending['2026-11-21']!.complete([]);
    await second;
    r.pending['2026-11-20']!.complete([meal()]);
    await first;
    expect(c.state.date.day, 21);
    expect(c.state.meals, isEmpty);
    expect(c.state.loading, isFalse);
    await c.close();
  });
  test('account change suppresses a pending diary response', () async {
    final r = DelayedDiaryRepository();
    String? uid = 'u1';
    final c = DiaryCubit(
      repository: r,
      uid: 'u1',
      currentUid: () => uid,
      date: DateTime(2026, 11, 20),
    );
    final f = c.load();
    uid = 'other';
    r.pending['2026-11-20']!.complete([meal()]);
    await f;
    expect(c.state.meals, isEmpty);
    await c.close();
  });
  test('aggregate read errors are handled, not a fake empty success', () async {
    final r = DelayedDiaryRepository()..failLog = true;
    final c = DiaryCubit(
      repository: r,
      uid: 'u1',
      currentUid: () => 'u1',
      date: DateTime(2026, 11, 20),
    );
    final f = c.load();
    r.pending['2026-11-20']!.complete([]);
    await f;
    expect(c.state.failed, isTrue);
    expect(c.state.loading, isFalse);
    await c.close();
  });
}
