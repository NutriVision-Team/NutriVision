import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/features/coach/domain/coach_engine.dart';

MealEntryModel meal(String id, String dateKey, double calories) =>
    MealEntryModel(
      mealId: id,
      userId: 'u1',
      dateKey: dateKey,
      consumedAt: DateTime.parse('${dateKey}T12:00:00'),
      mealType: 'lunch',
      inputMethod: 'manual',
      title: 'وجبة $id',
      items: const [],
      totalCalories: calories,
      totalProtein: 20,
      totalCarbs: 30,
      totalFat: 10,
      totalFiber: 5,
      totalSugar: 5,
      totalSodium: 100,
      analysisStatus: 'verified',
    );

DailyLogModel log(String dateKey, {double water = 0, int mealCount = 2}) =>
    DailyLogModel(
      dateKey: dateKey,
      timezone: 'Africa/Cairo',
      totalCalories: 1800,
      totalProtein: 80,
      totalCarbs: 200,
      totalFat: 60,
      totalFiber: 20,
      totalSugar: 30,
      totalSodium: 1500,
      calorieTarget: 2000,
      proteinTarget: 120,
      carbsTarget: 200,
      fatTarget: 70,
      waterIntakeMl: water,
      mealCount: mealCount,
    );

void main() {
  const engine = RuleBasedCoach();
  const todayKey = '2026-11-22';

  CoachData data({
    List<MealEntryModel> meals = const [],
    List<DailyLogModel> logs = const [],
    double? target,
    double? waterTarget,
    String locale = 'ar',
  }) => CoachData(
    todayKey: todayKey,
    locale: locale,
    meals: meals,
    dailyLogs: logs,
    calorieTarget: target,
    waterTargetMl: waterTarget,
  );

  test('says honestly when nothing is logged today', () {
    final answer = engine.answer('النهاردة كام سعرة؟', data());
    expect(answer.text, contains('لسه مسجلتش أي وجبة النهاردة'));
  });

  test('today answer counts only logged meals', () {
    final answer = engine.answer(
      'النهاردة كام سعرة؟',
      data(meals: [meal('m1', todayKey, 400)]),
    );
    expect(answer.text, contains('النهاردة سجلت 1 وجبة'));
  });

  test('week analysis marks missing days as missing data, not zero', () {
    final answer = engine.answer(
      'حلل أسبوعي',
      data(
        logs: [log('2026-11-21'), log(todayKey)],
        meals: [meal('m1', todayKey, 400)],
      ),
    );
    expect(answer.text, contains('راجعت سجلات آخر ٧ أيام'));
    expect(answer.text, contains('بدون تسجيل'));
    expect(answer.text, contains('بيانات ناقصة'));
  });

  test('week analysis refuses to invent numbers from an empty log', () {
    final answer = engine.answer('حلل أسبوعي', data());
    expect(answer.text, contains('مفيش وجبات مسجلة في آخر ٧ أيام'));
  });

  test('water answer never invents a goal the user did not set', () {
    final answer = engine.answer(
      'شربت كام مية؟',
      data(logs: [log(todayKey, water: 500)]),
    );
    expect(answer.text, contains('500'));
    expect(answer.text, contains('مش هفترض رقم'));
  });

  test('water answer uses a real configured goal', () {
    final answer = engine.answer(
      'شربت كام مية؟',
      data(logs: [log(todayKey, water: 500)], waterTarget: 2000),
    );
    expect(answer.text, contains('قيمة المية في سجل النهاردة 500 مل'));
    expect(answer.stats[1].value, '2000');
    expect(answer.stats[2].value, '1500');
    expect(answer.advice, isNot(contains('ساعتين')));
  });

  for (final locale in ['ar', 'en']) {
    test('missing water remains unknown in $locale', () {
      final answer = engine.quick(
        'water',
        data(locale: locale, waterTarget: 2000),
      );
      expect(
        answer.stats.first.value,
        locale == 'ar' ? 'غير معروف' : 'Unknown',
      );
      expect(answer.stats.length, 2);
      expect(
        answer.advice,
        contains(locale == 'ar' ? 'مش وصفة' : 'not a personal prescription'),
      );
    });
    test('zero water is only a record value in $locale', () {
      final answer = engine.quick(
        'water',
        data(locale: locale, logs: [log(todayKey)]),
      );
      expect(answer.stats.single.value, '0');
      expect(
        answer.text,
        contains(locale == 'ar' ? 'مش قياس' : 'not a measurement'),
      );
    });
    test('invalid water values do not crash or become zero in $locale', () {
      for (final value in [double.nan, double.infinity, -1.0]) {
        final answer = engine.quick(
          'water',
          data(
            locale: locale,
            logs: [log(todayKey, water: value)],
            waterTarget: double.nan,
          ),
        );
        expect(
          answer.stats.single.value,
          locale == 'ar' ? 'غير معروف' : 'Unknown',
        );
      }
    });
    test('past water and invalid goals are not current facts in $locale', () {
      final answer = engine.quick(
        'water',
        data(
          locale: locale,
          logs: [log('2026-11-21', water: 900)],
          waterTarget: -100,
        ),
      );
      expect(
        answer.stats.single.value,
        locale == 'ar' ? 'غير معروف' : 'Unknown',
      );
    });
  }

  test('fallback states record grounding and clinical limits in English', () {
    final answer = engine.answer('write me a sonnet', data(locale: 'en'));
    expect(answer.text, contains('using your logs and chosen target'));
    expect(answer.text, contains('I do not diagnose or provide treatment'));
    expect(answer.text, isNot(contains('AI-powered')));
    expect(RuleBasedCoach.quickPrompts, isNotEmpty);
  });
  test('future-dated meals never inflate last seven recorded days', () {
    final answer = engine.quick(
      'analyze_week',
      data(
        meals: [meal('now', todayKey, 400), meal('future', '2026-11-23', 999)],
      ),
    );
    expect(answer.stats.first.value, '1');
  });
  test('weekly review describes no ingredient details as unknown variety', () {
    final answer = engine.quick(
      'analyze_week',
      data(meals: [meal('m', todayKey, 400)]),
    );
    expect(
      answer.stats.firstWhere((s) => s.label == 'مكونات مختلفة مسجلة').value,
      'غير معروف',
    );
    expect(answer.advice, contains('من غير تفاصيل مكونات'));
  });
  test('chosen variety goal changes next step without claiming completion', () {
    final answer = engine.quick(
      'analyze_week',
      CoachData(
        todayKey: todayKey,
        locale: 'ar',
        meals: [meal('m', todayKey, 400)],
        goals: const ['تنويع الأكل'],
      ),
    );
    expect(answer.advice, contains('لهدف تنويع الأكل'));
    expect(answer.advice, contains('من غير تخمين'));
    expect(answer.advice, isNot(contains('حققت')));
  });
  test('unknown protein is not displayed as a verified zero', () {
    final unknown = MealEntryModel(
      mealId: 'unknown',
      userId: 'u1',
      dateKey: todayKey,
      consumedAt: DateTime(2026, 11, 22),
      mealType: 'lunch',
      inputMethod: 'manual',
      title: 'unknown',
      items: const [],
      totalCalories: 100,
      totalProtein: null,
      totalCarbs: null,
      totalFat: null,
      totalFiber: null,
      totalSugar: null,
      totalSodium: null,
      analysisStatus: 'confirmed',
    );
    final answer = engine.answer(
      'protein',
      data(meals: [unknown], locale: 'en'),
    );
    expect(answer.stats.single.value, 'Unknown');
  });
}
