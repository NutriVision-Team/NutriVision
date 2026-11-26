/// Pure, deterministic progression rules. This is a device-side projection,
/// never proof that a trusted service granted an award.
library;

class ProgressionEvent {
  const ProgressionEvent({
    required this.uid,
    required this.sourceId,
    required this.kind,
    required this.dayKey,
  });
  final String uid, sourceId, kind, dayKey;
  String get identity => '$kind:$sourceId';
}

class LevelRule {
  const LevelRule(this.id, this.xp, this.ar, this.en);
  final String id, ar, en;
  final int xp;
}

class BadgeRule {
  const BadgeRule(this.id, this.kind, this.target, this.ar, this.en);
  final String id, kind, ar, en;
  final int target;
}

class ProgressionConfig {
  ProgressionConfig({
    required this.version,
    required List<LevelRule> levels,
    required List<BadgeRule> badges,
    required Map<String, int> dailyXp,
  }) : levels = List.unmodifiable(levels),
       badges = List.unmodifiable(badges),
       dailyXp = Map.unmodifiable(dailyXp) {
    if (version.isEmpty ||
        levels.isEmpty ||
        levels.first.xp != 0 ||
        levels.map((l) => l.id).toSet().length != levels.length ||
        badges.map((b) => b.id).toSet().length != badges.length ||
        dailyXp.values.any((v) => v < 0 || v > 100) ||
        dailyXp.keys.any((k) => !supportedKinds.contains(k)) ||
        badges.any((b) => !supportedKinds.contains(b.kind) || b.target < 1)) {
      throw const FormatException('Invalid progression config');
    }
    for (var i = 1; i < levels.length; i++) {
      if (levels[i].xp <= levels[i - 1].xp) {
        throw const FormatException('Levels must increase');
      }
    }
  }
  static const supportedKinds = {
    'profile',
    'meal',
    'plan',
    'recipe',
    'lesson',
    'activeDay',
  };
  final String version;
  final List<LevelRule> levels;
  final List<BadgeRule> badges;
  final Map<String, int> dailyXp;
  factory ProgressionConfig.fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] != 1) throw const FormatException('Unknown rules');
    return ProgressionConfig(
      version: j['version'] as String,
      levels: (j['levels'] as List)
          .map(
            (e) => LevelRule(
              e['id'] as String,
              e['xp'] as int,
              e['ar'] as String,
              e['en'] as String,
            ),
          )
          .toList(),
      badges: (j['badges'] as List)
          .map(
            (e) => BadgeRule(
              e['id'] as String,
              e['kind'] as String,
              e['target'] as int,
              e['ar'] as String,
              e['en'] as String,
            ),
          )
          .toList(),
      dailyXp: Map<String, int>.from(j['dailyXp'] as Map),
    );
  }
}

class ProgressionProfile {
  ProgressionProfile({
    required this.uid,
    required this.configVersion,
    required this.xp,
    required this.level,
    required this.nextLevel,
    required Map<String, int> counts,
    required Set<String> badges,
    required Set<String> activeDays,
    required this.currentStreak,
    required this.bestStreak,
    required this.todayKey,
  }) : counts = Map.unmodifiable(counts),
       badges = Set.unmodifiable(badges),
       activeDays = Set.unmodifiable(activeDays);
  final String uid, configVersion, todayKey;
  final int xp, currentStreak, bestStreak;
  final LevelRule level;
  final LevelRule? nextLevel;
  final Map<String, int> counts;
  final Set<String> badges, activeDays;
  double get levelProgress => nextLevel == null
      ? 1
      : ((xp - level.xp) / (nextLevel!.xp - level.xp)).clamp(0, 1).toDouble();
  int get remainingXp => nextLevel == null ? 0 : nextLevel!.xp - xp;
}

class ProgressionEngine {
  const ProgressionEngine(this.config);
  final ProgressionConfig config;
  static DateTime date(String key) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
      throw const FormatException('Invalid day');
    }
    final d = DateTime.parse('${key}T00:00:00Z');
    if (keyOf(d) != key) throw const FormatException('Invalid calendar date');
    return d;
  }

  static String keyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  ProgressionProfile project(
    String uid,
    String todayKey,
    Iterable<ProgressionEvent> input,
  ) {
    if (uid.isEmpty || uid.contains('/')) {
      throw ArgumentError('Invalid owner');
    }
    final today = date(todayKey);
    final events = <String, ProgressionEvent>{};
    for (final e in input) {
      if (e.uid != uid) throw StateError('Progression owner mismatch');
      if (e.sourceId.isEmpty ||
          e.sourceId.contains('/') ||
          !ProgressionConfig.supportedKinds.contains(e.kind) ||
          e.kind == 'activeDay') {
        throw const FormatException('Unsupported activity');
      }
      if (e.kind != 'profile' && date(e.dayKey).isAfter(today)) continue;
      final old = events[e.identity];
      if (old != null && old.dayKey != e.dayKey) {
        throw StateError('Conflicting event identity');
      }
      events[e.identity] = e;
    }
    final counts = <String, int>{}, buckets = <String>{}, days = <String>{};
    var xp = 0;
    for (final e in events.values) {
      counts.update(e.kind, (v) => v + 1, ifAbsent: () => 1);
      if (e.kind != 'profile') days.add(e.dayKey);
      // Rewards favor returning, not logging extra food. Profile is once ever;
      // each other activity kind has one XP allowance per calendar day.
      final bucket = e.kind == 'profile' ? 'profile' : '${e.kind}:${e.dayKey}';
      if (buckets.add(bucket)) xp += config.dailyXp[e.kind] ?? 0;
    }
    counts['profile'] = (counts['profile'] ?? 0) > 0 ? 1 : 0;
    counts['activeDay'] = days.length;
    final sorted = days.toList()..sort();
    var best = 0, run = 0;
    DateTime? last;
    for (final key in sorted) {
      final d = date(key);
      run = last != null && d.difference(last).inDays == 1 ? run + 1 : 1;
      if (run > best) best = run;
      last = d;
    }
    var cursor = today, current = 0;
    if (!days.contains(keyOf(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (days.contains(keyOf(cursor))) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var index = 0;
    while (index + 1 < config.levels.length &&
        xp >= config.levels[index + 1].xp) {
      index++;
    }
    return ProgressionProfile(
      uid: uid,
      configVersion: config.version,
      xp: xp,
      level: config.levels[index],
      nextLevel: index + 1 < config.levels.length
          ? config.levels[index + 1]
          : null,
      counts: counts,
      badges: {
        for (final b in config.badges)
          if ((counts[b.kind] ?? 0) >= b.target) b.id,
      },
      activeDays: days,
      currentStreak: current,
      bestStreak: best,
      todayKey: todayKey,
    );
  }
}
