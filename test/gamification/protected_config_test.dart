import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/gamification/data/protected_ledger_config.dart';

Map<String, dynamic> valid() => {
  'version': 'proof1',
  'mealXp': 10,
  'planXp': 20,
  'profileXp': 20,
  'levelXp': [0, 100, 300, 700, 1500],
  'levelIds': ProtectedLedgerConfig.levelIds,
  'badgeTargets': {for (final id in ProtectedLedgerConfig.badgeIds) id: 1},
};
void main() {
  test('bounded protected config validates known families', () {
    expect(ProtectedLedgerConfig.parse(valid()).raw['mealXp'], 10);
  });
  test('invalid thresholds ids targets xp versions fail closed', () {
    for (final patch in [
      {'version': ''},
      {'mealXp': -1},
      {'planXp': 101},
      {
        'levelXp': [0, 100, 50, 700, 1500],
      },
      {
        'levelIds': ['beginner', 'evil', 'organizer', 'balanced', 'ambassador'],
      },
      {
        'badgeTargets': {'fake': 1},
      },
      {
        'levelXp': [0, 100],
      },
    ]) {
      expect(
        () => ProtectedLedgerConfig.parse({...valid(), ...patch}),
        throwsFormatException,
      );
    }
  });
  test('version mismatch freezes without mutating earned history', () {
    final p = {
      'configVersion': 'old',
      'xp': 777,
      'badges': {'aware': true},
    };
    expect(
      () => ProtectedLedgerConfig.parse(valid()).requireCompatible(p),
      throwsFormatException,
    );
    expect(p['xp'], 777);
    expect((p['badges'] as Map)['aware'], true);
  });
}
