import '../../food_catalog/data/datasources/local_food_data_source.dart';

/// User-configured Ramadan meal times, in minutes after local midnight.
///
/// No Fajr/Maghrib/prayer time is hardcoded anywhere in the app: these
/// values only ever come from what the user entered (or a future verified
/// time-source integration the user approves).
class RamadanTimes {
  const RamadanTimes({
    required this.iftarMinutes,
    required this.suhoorEndMinutes,
    required this.taraweehMinutes,
  });

  final int iftarMinutes;
  final int suhoorEndMinutes;
  final int taraweehMinutes;

  RamadanTimes copyWith({
    int? iftarMinutes,
    int? suhoorEndMinutes,
    int? taraweehMinutes,
  }) => RamadanTimes(
    iftarMinutes: iftarMinutes ?? this.iftarMinutes,
    suhoorEndMinutes: suhoorEndMinutes ?? this.suhoorEndMinutes,
    taraweehMinutes: taraweehMinutes ?? this.taraweehMinutes,
  );

  static bool _valid(int minutes) => minutes >= 0 && minutes < 24 * 60;

  bool get isValid =>
      _valid(iftarMinutes) &&
      _valid(suhoorEndMinutes) &&
      _valid(taraweehMinutes);
}

/// Which Ramadan moment the countdown currently targets.
enum RamadanCountdownTarget { iftar, taraweeh, suhoor }

/// Pure countdown/schedule math, fully testable.
class RamadanClock {
  const RamadanClock._();

  static DateTime _at(DateTime day, int minutes) =>
      DateTime(day.year, day.month, day.day).add(Duration(minutes: minutes));

  /// The next upcoming event after [now], walking today's schedule then
  /// tomorrow's suhoor end.
  static (RamadanCountdownTarget, DateTime) nextEvent(
    DateTime now,
    RamadanTimes times,
  ) {
    final candidates = <(RamadanCountdownTarget, DateTime)>[
      (RamadanCountdownTarget.iftar, _at(now, times.iftarMinutes)),
      (RamadanCountdownTarget.taraweeh, _at(now, times.taraweehMinutes)),
      (RamadanCountdownTarget.suhoor, _at(now, times.suhoorEndMinutes)),
      (
        RamadanCountdownTarget.iftar,
        _at(now.add(const Duration(days: 1)), times.iftarMinutes),
      ),
      (
        RamadanCountdownTarget.taraweeh,
        _at(now.add(const Duration(days: 1)), times.taraweehMinutes),
      ),
      (
        RamadanCountdownTarget.suhoor,
        _at(now.add(const Duration(days: 1)), times.suhoorEndMinutes),
      ),
    ];
    candidates.sort((a, b) => a.$2.compareTo(b.$2));
    return candidates.firstWhere((c) => c.$2.isAfter(now));
  }

  /// Fraction of today's fasting window (suhoor end → iftar) that has
  /// elapsed at [now]: 0 before the window, 1 after it. Drives the design's
  /// glowing arc.
  static double fastingProgress(DateTime now, RamadanTimes times) {
    final start = _at(now, times.suhoorEndMinutes);
    final end = _at(now, times.iftarMinutes);
    if (!end.isAfter(start)) return 0;
    if (now.isBefore(start)) return 0;
    if (now.isAfter(end)) return 1;
    return now.difference(start).inSeconds / end.difference(start).inSeconds;
  }
}

/// One suggested food inside a Ramadan slot, with its measured quantity.
class RamadanSuggestionItem {
  const RamadanSuggestionItem({
    required this.foodId,
    required this.grams,
    required this.nameAr,
    required this.nameEn,
    required this.category,
  });

  final String foodId;
  final double grams;
  final String nameAr;
  final String nameEn;
  final String category;
}

class RamadanSuggestion {
  const RamadanSuggestion({
    required this.slot,
    required this.items,
    required this.calories,
    required this.titleAr,
    required this.titleEn,
  });

  /// 'iftar', 'taraweeh' or 'suhoor'.
  final String slot;
  final List<RamadanSuggestionItem> items;

  /// Computed from measured per-100g energy and the suggested grams; never
  /// an invented dish calorie.
  final double calories;
  final String titleAr;
  final String titleEn;
}

/// Deterministic educational meal suggestions built only from verified
/// catalog records with measured energy. Traditional dishes that are not in
/// the verified catalog are never faked; the UI labels these as educational
/// catalog suggestions.
class RamadanSuggester {
  RamadanSuggester({required List<LocalFoodRecord> catalog})
    : _eligible = List.unmodifiable(
        catalog.where((food) {
          final energy = food.nutrientsPer100g.energyKcal;
          return food.nameAr.isNotEmpty && energy != null && energy > 0;
        }),
      );

  final List<LocalFoodRecord> _eligible;

  static const slotFractions = {
    'iftar': 0.40,
    'taraweeh': 0.15,
    'suhoor': 0.25,
  };

  static const slotCategories = {
    'iftar': ['legumes', 'grains', 'poultry', 'vegetables'],
    'taraweeh': ['fruits', 'dairy', 'nuts_seeds'],
    'suhoor': ['legumes', 'eggs', 'dairy', 'grains'],
  };

  /// Builds suggestions for all three slots. [dailyCalorieTarget] scales
  /// quantities; without it, reference (100 g) amounts are used and the
  /// calories shown are the measured calories of those amounts.
  List<RamadanSuggestion> suggest({double? dailyCalorieTarget}) {
    const titles = {
      'iftar': ('إفطار', 'Iftar'),
      'taraweeh': ('بعد التراويح', 'After Taraweeh'),
      'suhoor': ('سحور', 'Suhoor'),
    };
    final out = <RamadanSuggestion>[];
    for (final slot in ['iftar', 'taraweeh', 'suhoor']) {
      final categories = slotCategories[slot]!;
      final fraction = slotFractions[slot]!;
      final pool = _eligible
          .where((food) => categories.contains(food.category))
          .toList(growable: false);
      if (pool.isEmpty) continue;
      // Deterministic rotation: first two records of the first two
      // categories present, so suggestions are stable across sessions.
      final picked = <LocalFoodRecord>[];
      for (final category in categories) {
        for (final food in pool) {
          if (food.category == category &&
              !picked.any((p) => p.id == food.id)) {
            picked.add(food);
            break;
          }
        }
        if (picked.length >= 3) break;
      }
      final slotKcal = (dailyCalorieTarget ?? 0) * fraction;
      final items = <RamadanSuggestionItem>[];
      var calories = 0.0;
      for (final food in picked) {
        final per100 = food.nutrientsPer100g.energyKcal!;
        final grams = dailyCalorieTarget != null && dailyCalorieTarget > 0
            ? ((slotKcal / picked.length) / per100 * 100)
                  .clamp(30.0, 400.0)
                  .roundToDouble()
            : food.referenceAmountGrams;
        calories += grams / 100 * per100;
        items.add(
          RamadanSuggestionItem(
            foodId: food.id,
            grams: grams,
            nameAr: food.nameAr,
            nameEn: food.nameEn,
            category: food.category,
          ),
        );
      }
      out.add(
        RamadanSuggestion(
          slot: slot,
          items: items,
          calories: calories,
          titleAr: titles[slot]!.$1,
          titleEn: titles[slot]!.$2,
        ),
      );
    }
    return out;
  }
}
