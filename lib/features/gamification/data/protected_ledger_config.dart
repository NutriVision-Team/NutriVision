import '../domain/progression_engine.dart';

/// Version 1 bounded local ledger config contract. No history migration implied.
class ProtectedLedgerConfig {
  ProtectedLedgerConfig._(this.raw);
  final Map<String, dynamic> raw;
  static const badgeIds = {
    'journey',
    'first_meal',
    'aware',
    'planner',
    'planner3',
    'active7',
    'active30',
    'returning',
  };
  static const levelIds = [
    'beginner',
    'explorer',
    'organizer',
    'balanced',
    'ambassador',
  ];
  factory ProtectedLedgerConfig.parse(Map<String, dynamic> value) {
    bool integer(Object? n, int min, int max) =>
        n is int && n >= min && n <= max;
    final levels = value['levelXp'],
        ids = value['levelIds'],
        targets = value['badgeTargets'];
    if (value['version'] is! String ||
        !RegExp(
          r'^[A-Za-z0-9_-]{1,64}$',
        ).hasMatch(value['version'] as String) ||
        !integer(value['mealXp'], 0, 100) ||
        !integer(value['planXp'], 0, 100) ||
        !integer(value['profileXp'], 0, 100) ||
        levels is! List ||
        levels.length != 5 ||
        levels.first != 0 ||
        levels.any((n) => !integer(n, 0, 1000000)) ||
        ids is! List ||
        ids.length != 5 ||
        ids.asMap().entries.any((e) => e.value != levelIds[e.key]) ||
        targets is! Map ||
        targets.length != 8 ||
        targets.keys.toSet().difference(badgeIds).isNotEmpty ||
        targets.values.any((n) => !integer(n, 1, 100000))) {
      throw const FormatException('Invalid protected config');
    }
    for (var i = 1; i < 5; i++) {
      if ((levels[i] as int) <= (levels[i - 1] as int)) {
        throw const FormatException('Unordered levels');
      }
    }
    return ProtectedLedgerConfig._(Map.unmodifiable(value));
  }
  void requireCompatible(Map<String, dynamic>? profile) {
    if (profile != null && profile['configVersion'] != raw['version']) {
      throw const FormatException('Config migration required');
    }
  }

  ProgressionConfig display(ProgressionConfig labels) {
    final levels = List.generate(5, (i) {
      final label = labels.levels.singleWhere((l) => l.id == levelIds[i]);
      return LevelRule(
        label.id,
        (raw['levelXp'] as List)[i] as int,
        label.ar,
        label.en,
      );
    });
    final targets = raw['badgeTargets'] as Map;
    return ProgressionConfig(
      version: raw['version'] as String,
      levels: levels,
      badges: labels.badges
          .where((b) => badgeIds.contains(b.id))
          .map((b) => BadgeRule(b.id, b.kind, targets[b.id] as int, b.ar, b.en))
          .toList(),
      dailyXp: {
        'meal': raw['mealXp'] as int,
        'plan': raw['planXp'] as int,
        'profile': raw['profileXp'] as int,
      },
    );
  }
}
