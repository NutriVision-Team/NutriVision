import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/features/ramadan/data/ramadan_settings_store.dart';
import 'package:sufradepi/features/ramadan/domain/ramadan_logic.dart';

void main() {
  group('RamadanClock', () {
    const times = RamadanTimes(
      iftarMinutes: 17 * 60 + 30,
      suhoorEndMinutes: 4 * 60,
      taraweehMinutes: 20 * 60,
    );

    test('next event is iftar during the fast', () {
      final (kind, at) = RamadanClock.nextEvent(
        DateTime(2026, 3, 1, 12),
        times,
      );
      expect(kind, RamadanCountdownTarget.iftar);
      expect(at, DateTime(2026, 3, 1, 17, 30));
    });

    test('after taraweeh the countdown crosses midnight to suhoor end', () {
      final (kind, at) = RamadanClock.nextEvent(
        DateTime(2026, 3, 1, 21),
        times,
      );
      expect(kind, RamadanCountdownTarget.suhoor);
      expect(at, DateTime(2026, 3, 2, 4));
    });

    test('between iftar and taraweeh the next event is taraweeh', () {
      final (kind, at) = RamadanClock.nextEvent(
        DateTime(2026, 3, 1, 18),
        times,
      );
      expect(kind, RamadanCountdownTarget.taraweeh);
      expect(at, DateTime(2026, 3, 1, 20));
    });

    test('fasting progress is clamped and honest at the edges', () {
      expect(
        RamadanClock.fastingProgress(DateTime(2026, 3, 1, 4), times),
        closeTo(0, 0.001),
      );
      expect(
        RamadanClock.fastingProgress(DateTime(2026, 3, 1, 17, 30), times),
        closeTo(1, 0.001),
      );
      final midway = RamadanClock.fastingProgress(
        DateTime(2026, 3, 1, 10, 45),
        times,
      );
      expect(midway, greaterThan(0.4));
      expect(midway, lessThan(0.6));
      expect(RamadanClock.fastingProgress(DateTime(2026, 3, 1, 20), times), 1);
    });

    test('times validation flags impossible hours without throwing', () {
      const bad = RamadanTimes(
        iftarMinutes: 25 * 60,
        suhoorEndMinutes: 4 * 60,
        taraweehMinutes: 20 * 60,
      );
      expect(bad.isValid, isFalse);
      expect(times.isValid, isTrue);
    });
  });

  group('RamadanSuggester', () {
    LocalFoodRecord food(String id, String category, double? kcal) =>
        LocalFoodRecord(
          id: id,
          nameAr: 'صنف $id',
          nameEn: id,
          aliases: const [],
          category: category,
          foodState: 'raw',
          referenceAmountGrams: 100,
          nutrientsPer100g: LocalFoodNutrients(energyKcal: kcal),
          dataQuality: 'verified_source',
          source: const LocalFoodSource(
            provider: 'fixture',
            dataset: 'fixture',
            fdcId: 1,
            sourceVersion: '1',
            url: 'fixture',
          ),
        );

    final catalog = [
      food('lentil1', 'legumes', 360),
      food('rice1', 'grains', 359),
      food('chicken1', 'poultry', 165),
      food('spinach1', 'vegetables', 25),
      food('banana1', 'fruits', 90),
      food('milk1', 'dairy', 60),
      food('nuts1', 'nuts_seeds', 588),
      food('egg1', 'eggs', 148),
      food('mystery1', 'grains', null),
    ];

    test('suggests the three slots from measured catalog items only', () {
      final suggestions = RamadanSuggester(
        catalog: catalog,
      ).suggest(dailyCalorieTarget: 2400);
      expect(suggestions.map((s) => s.slot), ['iftar', 'taraweeh', 'suhoor']);
      for (final suggestion in suggestions) {
        expect(suggestion.items, isNotEmpty);
        expect(suggestion.calories, greaterThan(0));
        for (final item in suggestion.items) {
          expect(item.foodId, isNot('mystery1'));
          expect(item.grams, greaterThanOrEqualTo(30));
          expect(item.grams, lessThanOrEqualTo(400));
        }
      }
    });

    test('without a target it uses the measured reference amounts', () {
      final suggestions = RamadanSuggester(catalog: catalog).suggest();
      expect(suggestions, isNotEmpty);
      for (final suggestion in suggestions) {
        for (final item in suggestion.items) {
          expect(item.grams, 100);
        }
      }
    });
  });

  group('PrefsRamadanSettingsStore', () {
    test('stores times and cups per user id, isolated between users', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final u1 = PrefsRamadanSettingsStore(preferences: prefs, userId: 'u1');
      final u2 = PrefsRamadanSettingsStore(preferences: prefs, userId: 'u2');
      const times = RamadanTimes(
        iftarMinutes: 17 * 60,
        suhoorEndMinutes: 4 * 60,
        taraweehMinutes: 20 * 60,
      );
      await u1.saveTimes(times);
      await u1.saveCupsTarget(10);
      final loaded = await u1.readTimes();
      expect(loaded, isNotNull);
      expect(loaded!.iftarMinutes, 17 * 60);
      expect(await u1.readCupsTarget(), 10);
      expect(await u2.readTimes(), isNull);
      expect(await u2.readCupsTarget(), isNull);
    });
  });
}
