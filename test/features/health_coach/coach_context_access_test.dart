import 'package:sufradepi/features/health_coach/domain/coach_trusted_snapshot.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/health_coach/domain/coach_context_access.dart';

void main() {
  CoachContextGrant grant({
    String version = CoachContextGrant.currentVersion,
  }) => CoachContextGrant(
    accountId: 'owner',
    version: version,
    acceptedAt: DateTime.utc(2026, 11, 25),
    categories: {CoachDataCategory.records},
  );
  CoachToolFact fact({
    String key = 'logged_energy',
    String date = '2026-11-25',
    double? value = 100,
  }) => CoachToolFact(
    key: key,
    category: CoachDataCategory.records,
    value: value,
    unit: CoachToolFact.expectedUnit[key] ?? 'kcal',
    dateKey: date,
    sourceLabel: 'diary',
  );
  List<Map<String, Object?>> select(
    CoachRelevantContext c,
    CoachContextGrant g, {
    String account = 'owner',
    Iterable<CoachToolFact>? facts,
  }) => c.select(
    grant: g,
    activeAccount: account,
    requestedKeys: {'logged_energy'},
    requestedDates: {'2026-11-25'},
    available: facts ?? [fact()],
  );
  test('real snapshot adapter feeds relevant boundary without private IDs', () {
    final snapshot = CoachTrustedSnapshot.forDay(
      dateKey: '2026-11-25',
      meals: [],
      log: DailyLogModel(
        dateKey: '2026-11-25',
        timezone: 'Africa/Cairo',
        totalCalories: 900,
        totalProtein: 90,
        totalCarbs: 100,
        totalFat: 20,
        totalFiber: null,
        totalSugar: null,
        totalSodium: null,
        calorieTarget: 2000,
        proteinTarget: 100,
        carbsTarget: 200,
        fatTarget: 70,
        waterIntakeMl: 750,
        mealCount: 2,
      ),
    );
    final result = select(
      CoachRelevantContext(),
      grant(),
      facts: snapshot.contextFactsForDate('2026-11-25'),
    );
    expect(result.length, 1);
    expect(result.single['value'], 900);
    expect(result.single['source'], 'diary');
    expect(
      result.single.values.any((v) => v.toString().contains('daily_log:')),
      false,
    );
  });
  test('only requested dates and metrics enter context', () {
    final c = CoachRelevantContext();
    final result = select(
      c,
      grant(),
      facts: [
        fact(),
        fact(date: '2026-11-24'),
        fact(key: 'logged_protein'),
      ],
    );
    expect(result.length, 1);
    expect(result.single['date'], '2026-11-25');
    expect(result.single.containsKey('accountId'), false);
  });
  test('wrong account or stale policy cannot share', () {
    expect(select(CoachRelevantContext(), grant(), account: 'other'), isEmpty);
    expect(select(CoachRelevantContext(), grant(version: 'v1')), isEmpty);
  });
  test('withdrawal clears cached facts and denies future selections', () {
    final c = CoachRelevantContext(), g = grant();
    select(c, g);
    expect(c.hasEphemeralContext, true);
    c.withdraw(g);
    expect(c.hasEphemeralContext, false);
    expect(select(c, g), isEmpty);
  });
  test('unknown is null, not zero, and scope is capped', () {
    final c = CoachRelevantContext();
    expect(
      select(c, grant(), facts: [fact(value: null)]).single['status'],
      'unknown',
    );
    expect(
      select(c, grant(), facts: List.generate(30, (_) => fact())).length,
      20,
    );
  });
  test('secret field names, arbitrary sources and invalid numbers fail', () {
    expect(() => fact(key: 'token'), throwsArgumentError);
    expect(() => fact(value: double.nan), throwsArgumentError);
    expect(
      () => CoachToolFact(
        key: 'logged_energy',
        category: CoachDataCategory.records,
        value: 1,
        unit: 'kcal',
        dateKey: '2026-11-25',
        sourceLabel: 'user-private-id',
      ),
      throwsArgumentError,
    );
  });
}
