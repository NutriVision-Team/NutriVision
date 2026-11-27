import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'package:sufradepi/features/progress/presentation/cubit/progress_cubit.dart';
import 'progress_test.dart' as fixture;

class HistoricalNutrition extends fixture.FakeNutritionRepository {
  final requested = <String>[];
  final data = <String, DailyLogModel>{};
  Completer<DailyLogModel?>? pending;
  @override
  Future<DailyLogModel?> getDailyLog(String uid, String dateKey) async {
    requested.add(dateKey);
    return pending == null ? data[dateKey] : pending!.future;
  }
}

void main() {
  test(
    'historical range inclusive, chronological, partial missing data unknown',
    () async {
      final r = HistoricalNutrition()
        ..data['2025-02-02'] = fixture.log('2025-02-02');
      final c = ProgressCubit(
        nutritionRepository: r,
        uid: 'u',
        currentUid: () => 'u',
      );
      await c.loadRange(DateTime(2025, 2, 1), DateTime(2025, 2, 3));
      expect(r.requested, ['2025-02-01', '2025-02-02', '2025-02-03']);
      expect(c.state.days.length, 3);
      expect(c.state.days.first.calories, isNull);
      expect(c.state.days[1].calories, isNotNull);
      expect(c.state.days.last.tracked, isFalse);
      await c.close();
    },
  );
  test(
    'mismatched historical date fails rather than showing another day',
    () async {
      final r = HistoricalNutrition()
        ..data['2025-02-02'] = fixture.log('2025-02-03');
      final c = ProgressCubit(
        nutritionRepository: r,
        uid: 'u',
        currentUid: () => 'u',
      );
      await c.loadRange(DateTime(2025, 2, 2), DateTime(2025, 2, 2));
      expect(c.state.failed, isTrue);
      await c.close();
    },
  );
  test('account switch drops late range; closed cubit does not emit', () async {
    String? uid = 'u';
    final r = HistoricalNutrition()..pending = Completer<DailyLogModel?>();
    final c = ProgressCubit(
      nutritionRepository: r,
      uid: 'u',
      currentUid: () => uid,
    );
    final f = c.loadRange(DateTime(2025), DateTime(2025));
    uid = 'other';
    r.pending!.complete(fixture.log('2025-01-01'));
    await f;
    expect(c.state.days, isEmpty);
    await c.close();
  });
  test('range bound prevents unbounded reads', () async {
    final r = HistoricalNutrition();
    final c = ProgressCubit(
      nutritionRepository: r,
      uid: 'u',
      currentUid: () => 'u',
    );
    await expectLater(
      c.loadRange(DateTime(2024), DateTime(2026)),
      throwsArgumentError,
    );
    expect(r.requested, isEmpty);
    await c.close();
  });
}
