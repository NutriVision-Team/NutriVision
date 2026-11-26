import 'dart:convert';

/// The three reminder kinds required by the brief (section 12): water,
/// meal and weight. Nothing else is scheduled by this feature.
enum ReminderKind { water, meal, weight }

/// Meal slots follow the app's existing meal types.
const reminderMealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

const maxWaterTimes = 12;

/// Minutes after local midnight, 0..1439.
typedef MinuteOfDay = int;

bool isValidMinute(int m) => m >= 0 && m < 1440;

class WaterReminders {
  const WaterReminders({this.enabled = false, this.times = const []});
  final bool enabled;

  /// Sorted, unique, at most [maxWaterTimes].
  final List<MinuteOfDay> times;

  WaterReminders copyWith({bool? enabled, List<MinuteOfDay>? times}) =>
      WaterReminders(
        enabled: enabled ?? this.enabled,
        times: times ?? this.times,
      );
}

class MealReminder {
  const MealReminder({this.enabled = false, this.minute});
  final bool enabled;

  /// Null until the user has picked a time. Never scheduled without one.
  final MinuteOfDay? minute;
}

class WeightReminder {
  const WeightReminder({this.enabled = false, this.minute, this.weekday});
  final bool enabled;
  final MinuteOfDay? minute;

  /// DateTime.monday..DateTime.sunday (1..7). Weekly reminder.
  final int? weekday;
}

/// Per-account, on-device reminder settings. Everything is off until the
/// user switches it on and chooses a time.
class ReminderSettings {
  const ReminderSettings({
    this.water = const WaterReminders(),
    this.meals = const {},
    this.weight = const WeightReminder(),
  });

  final WaterReminders water;
  final Map<String, MealReminder> meals;
  final WeightReminder weight;

  static const empty = ReminderSettings();

  MealReminder meal(String type) => meals[type] ?? const MealReminder();

  bool get anyEnabled =>
      water.enabled || meals.values.any((m) => m.enabled) || weight.enabled;

  ReminderSettings copyWith({
    WaterReminders? water,
    Map<String, MealReminder>? meals,
    WeightReminder? weight,
  }) => ReminderSettings(
    water: water ?? this.water,
    meals: meals ?? this.meals,
    weight: weight ?? this.weight,
  );

  ReminderSettings withMeal(String type, MealReminder r) =>
      copyWith(meals: {...meals, type: r});

  String toJson() => jsonEncode({
    'v': 1,
    'water': {'enabled': water.enabled, 'times': water.times},
    'meals': {
      for (final e in meals.entries)
        e.key: {'enabled': e.value.enabled, 'minute': e.value.minute},
    },
    'weight': {
      'enabled': weight.enabled,
      'minute': weight.minute,
      'weekday': weight.weekday,
    },
  });

  /// Tolerant parse: malformed or out-of-range data becomes "off", never a
  /// guessed schedule. Returns [empty] for unreadable input.
  static ReminderSettings fromJson(String? source) {
    if (source == null) return empty;
    try {
      final map = jsonDecode(source);
      if (map is! Map) return empty;
      int? minute(Object? v) => v is int && isValidMinute(v) ? v : null;

      final w = map['water'];
      var water = const WaterReminders();
      if (w is Map) {
        final times = <int>{
          for (final t in (w['times'] is List ? w['times'] as List : const []))
            if (minute(t) != null) t as int,
        }.toList()..sort();
        water = WaterReminders(
          enabled: w['enabled'] == true && times.isNotEmpty,
          times: times.take(maxWaterTimes).toList(growable: false),
        );
      }
      final meals = <String, MealReminder>{};
      final m = map['meals'];
      if (m is Map) {
        for (final type in reminderMealTypes) {
          final e = m[type];
          if (e is Map) {
            final min = minute(e['minute']);
            meals[type] = MealReminder(
              enabled: e['enabled'] == true && min != null,
              minute: min,
            );
          }
        }
      }
      var weight = const WeightReminder();
      final wt = map['weight'];
      if (wt is Map) {
        final min = minute(wt['minute']);
        final day = wt['weekday'];
        final okDay = day is int && day >= 1 && day <= 7 ? day : null;
        weight = WeightReminder(
          enabled: wt['enabled'] == true && min != null && okDay != null,
          minute: min,
          weekday: okDay,
        );
      }
      return ReminderSettings(water: water, meals: meals, weight: weight);
    } catch (_) {
      return empty;
    }
  }
}

/// Texts in the app language, resolved by the UI at sync time. Content is
/// deliberately generic: it never contains weights, calories or any logged
/// value, because notifications show on the lock screen.
class ReminderTexts {
  const ReminderTexts({
    required this.title,
    required this.water,
    required this.weight,
    required this.meals,
    this.waterChannel = 'Water reminders',
    this.mealChannel = 'Meal reminders',
    this.weightChannel = 'Weight reminders',
  });
  final String waterChannel;
  final String mealChannel;
  final String weightChannel;
  final String title;
  final String water;
  final String weight;

  /// Body per meal type.
  final Map<String, String> meals;
}
