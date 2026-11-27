import 'package:timezone/timezone.dart' as tz;

import 'reminder_models.dart';

/// Stable notification IDs. They never depend on list order, time or uid:
/// the same slot always has the same ID, so cancel/reschedule hits exactly
/// the notification it created. The range is reserved for this feature.
abstract final class ReminderIds {
  static const waterBase = 710100; // 710100..710111
  static const mealBase =
      710200; // 710200..710203, order of [reminderMealTypes]
  static const weight = 710300;

  static int meal(String type) {
    final i = reminderMealTypes.indexOf(type);
    if (i < 0) throw ArgumentError.value(type, 'type');
    return mealBase + i;
  }

  static int water(int slot) {
    if (slot < 0 || slot >= maxWaterTimes) {
      throw RangeError.index(slot, List.filled(maxWaterTimes, 0));
    }
    return waterBase + slot;
  }

  /// Every ID this feature may own. Used to cancel leftovers.
  static List<int> get all => [
    for (var i = 0; i < maxWaterTimes; i++) waterBase + i,
    for (var i = 0; i < reminderMealTypes.length; i++) mealBase + i,
    weight,
  ];
}

class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.kind,
    required this.minute,
    required this.body,
    required this.payload,
    this.weekday,
  });
  final int id;
  final ReminderKind kind;
  final MinuteOfDay minute;
  final int? weekday;
  final String body;
  final String payload;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.id == id &&
      other.kind == kind &&
      other.minute == minute &&
      other.weekday == weekday &&
      other.body == body &&
      other.payload == payload;

  @override
  int get hashCode => Object.hash(id, kind, minute, weekday, body, payload);
}

/// Payload strings, parseable by the app when a notification is tapped.
abstract final class ReminderPayload {
  static const water = 'sufra:reminder:water';
  static const weight = 'sufra:reminder:weight';
  static String meal(String type) => 'sufra:reminder:meal:$type';

  static ReminderKind? kindOf(String? payload) {
    if (payload == null || !payload.startsWith('sufra:reminder:')) return null;
    final rest = payload.substring('sufra:reminder:'.length);
    if (rest == 'water') return ReminderKind.water;
    if (rest == 'weight') return ReminderKind.weight;
    if (rest.startsWith('meal:')) return ReminderKind.meal;
    return null;
  }
}

/// Pure: what should be scheduled for these settings. Disabled or
/// incomplete entries are simply absent, which makes the scheduler cancel
/// them.
List<PlannedReminder> planReminders(ReminderSettings s, ReminderTexts texts) {
  final out = <PlannedReminder>[];
  if (s.water.enabled) {
    final times = ({
      ...s.water.times,
    }.where(isValidMinute).toList()..sort()).take(maxWaterTimes).toList();
    for (var i = 0; i < times.length; i++) {
      out.add(
        PlannedReminder(
          id: ReminderIds.water(i),
          kind: ReminderKind.water,
          minute: times[i],
          body: texts.water,
          payload: ReminderPayload.water,
        ),
      );
    }
  }
  for (final type in reminderMealTypes) {
    final m = s.meal(type);
    final body = texts.meals[type];
    if (m.enabled &&
        m.minute != null &&
        isValidMinute(m.minute!) &&
        body != null) {
      out.add(
        PlannedReminder(
          id: ReminderIds.meal(type),
          kind: ReminderKind.meal,
          minute: m.minute!,
          body: body,
          payload: ReminderPayload.meal(type),
        ),
      );
    }
  }
  final w = s.weight;
  if (w.enabled &&
      w.minute != null &&
      w.weekday != null &&
      isValidMinute(w.minute!)) {
    out.add(
      PlannedReminder(
        id: ReminderIds.weight,
        kind: ReminderKind.weight,
        minute: w.minute!,
        weekday: w.weekday,
        body: texts.weight,
        payload: ReminderPayload.weight,
      ),
    );
  }
  return out;
}

/// Next wall-clock occurrence strictly after [now] in [location]. With a
/// repeating match (daily time, or weekday + time) the OS keeps the local
/// wall-clock time across DST changes.
tz.TZDateTime nextOccurrence(
  PlannedReminder r,
  tz.Location location,
  tz.TZDateTime now,
) {
  final local = tz.TZDateTime.from(now, location);
  var d = tz.TZDateTime(
    location,
    local.year,
    local.month,
    local.day,
    r.minute ~/ 60,
    r.minute % 60,
  );
  while (!d.isAfter(local) || (r.weekday != null && d.weekday != r.weekday)) {
    d = tz.TZDateTime(
      location,
      d.year,
      d.month,
      d.day + 1,
      r.minute ~/ 60,
      r.minute % 60,
    );
  }
  return d;
}
