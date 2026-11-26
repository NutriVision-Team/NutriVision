import 'coach_trusted_snapshot.dart';

/// Prepared context boundary. Not wired to the external provider or live UI.
/// Product-wide access is implemented through bounded read tools, not raw dumps.
enum CoachDataCategory { catalog, profile, records, conversation }

class CoachContextGrant {
  CoachContextGrant({
    required this.accountId,
    required this.version,
    required this.acceptedAt,
    required Set<CoachDataCategory> categories,
  }) : categories = Set.unmodifiable(categories);

  static const currentVersion = 'coach-context-v2-draft';
  final String accountId, version;
  final DateTime acceptedAt;
  final Set<CoachDataCategory> categories;
  bool _revoked = false;
  bool allows(String activeAccount, CoachDataCategory category) =>
      !_revoked &&
      accountId.isNotEmpty &&
      accountId == activeAccount &&
      version == currentVersion &&
      categories.contains(category);
  void withdraw() => _revoked = true;
}

class CoachToolFact {
  CoachToolFact({
    required this.key,
    required this.category,
    required this.value,
    required this.unit,
    required this.dateKey,
    required this.sourceLabel,
    this.estimated = false,
  }) {
    if (!keys.contains(key) ||
        category !=
            (key.startsWith('target_')
                ? CoachDataCategory.profile
                : CoachDataCategory.records) ||
        expectedUnit[key] != unit ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateKey) ||
        !units.contains(unit) ||
        !sources.contains(sourceLabel) ||
        (value != null && !value!.isFinite)) {
      throw ArgumentError('Unapproved fact');
    }
  }
  static const keys = {
    'logged_energy',
    'logged_protein',
    'logged_carbohydrate',
    'logged_fat',
    'logged_fiber',
    'logged_water',
    'logged_weight',
    'logged_steps',
    'target_energy',
    'target_water',
  };
  static const expectedUnit = {
    'logged_energy': 'kcal',
    'target_energy': 'kcal',
    'logged_protein': 'g',
    'logged_carbohydrate': 'g',
    'logged_fat': 'g',
    'logged_fiber': 'g',
    'logged_water': 'ml',
    'target_water': 'ml',
    'logged_weight': 'kg',
    'logged_steps': 'steps',
  };
  static const units = {'kcal', 'g', 'ml', 'kg', 'steps'};
  static const sources = {
    'diary',
    'water_log',
    'weight_log',
    'activity_log',
    'user_goal',
  };
  final String key, unit, dateKey, sourceLabel;
  final CoachDataCategory category;
  final double? value;
  final bool estimated;
  Map<String, Object?> toContext() => {
    'key': key,
    'value': value,
    'unit': unit,
    'date': dateKey,
    'source': sourceLabel,
    'estimated': estimated,
    'status': value == null ? 'unknown' : 'recorded',
  };
}

/// Explicit requested keys/dates come from a validated tool request. The model
/// cannot choose an account, database query, field name, recipient or write.
class CoachRelevantContext {
  final List<Map<String, Object?>> _ephemeral = [];
  List<Map<String, Object?>> select({
    required CoachContextGrant grant,
    required String activeAccount,
    required Set<String> requestedKeys,
    required Set<String> requestedDates,
    required Iterable<CoachToolFact> available,
  }) {
    _ephemeral.clear();
    for (final fact in available) {
      if (!grant.allows(activeAccount, fact.category) ||
          !requestedKeys.contains(fact.key) ||
          !requestedDates.contains(fact.dateKey)) {
        continue;
      }
      if (_ephemeral.length == 20) break;
      _ephemeral.add(Map.unmodifiable(fact.toContext()));
    }
    return List.unmodifiable(_ephemeral);
  }

  void withdraw(CoachContextGrant grant) {
    grant.withdraw();
    _ephemeral.clear();
  }

  bool get hasEphemeralContext => _ephemeral.isNotEmpty;
}

/// Uses existing deterministic diary aggregation. Stable private record IDs
/// stay local; the external boundary receives only a category source label.
extension CoachSnapshotContext on CoachTrustedSnapshot {
  List<CoachToolFact> contextFactsForDate(String dateKey) => metrics
      .map(
        (metric) => CoachToolFact(
          key: metric.key,
          category: CoachDataCategory.records,
          value: metric.value,
          unit: metric.unit,
          dateKey: dateKey,
          sourceLabel: metric.key == 'logged_water' ? 'water_log' : 'diary',
        ),
      )
      .toList(growable: false);
}
