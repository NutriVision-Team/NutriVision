import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ramadan_logic.dart';

/// Persists the user's own Ramadan configuration on-device, keyed by the
/// active account so a different signed-in user never sees the previous
/// account's times.
abstract class RamadanSettingsStore {
  Future<RamadanTimes?> readTimes();
  Future<void> saveTimes(RamadanTimes times);

  /// Cups target for the water row; null until the user sets one. The
  /// design's default presentation uses 8 cups, labeled as a design
  /// default, not as a personal health goal.
  Future<int?> readCupsTarget();
  Future<void> saveCupsTarget(int cups);
}

class PrefsRamadanSettingsStore implements RamadanSettingsStore {
  PrefsRamadanSettingsStore({
    required SharedPreferences preferences,
    required String userId,
  }) : _preferences = preferences,
       _suffix = Uri.encodeComponent(userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId');
    }
  }

  final SharedPreferences _preferences;
  final String _suffix;

  String get _timesKey => 'sufra.ramadan.times.v1.$_suffix';
  String get _cupsKey => 'sufra.ramadan.cups.v1.$_suffix';

  @override
  Future<RamadanTimes?> readTimes() async {
    final raw = _preferences.getStringList(_timesKey);
    if (raw == null || raw.length != 3) return null;
    final parsed = raw.map(int.tryParse).toList(growable: false);
    if (parsed.any((v) => v == null)) return null;
    final times = RamadanTimes(
      iftarMinutes: parsed[0]!,
      suhoorEndMinutes: parsed[1]!,
      taraweehMinutes: parsed[2]!,
    );
    return times.isValid ? times : null;
  }

  @override
  Future<void> saveTimes(RamadanTimes times) async {
    if (!times.isValid) {
      throw ArgumentError.value(times, 'times', 'Invalid minutes');
    }
    final accepted = await _preferences.setStringList(_timesKey, [
      '${times.iftarMinutes}',
      '${times.suhoorEndMinutes}',
      '${times.taraweehMinutes}',
    ]);
    if (!accepted) throw StateError('Could not save Ramadan times');
  }

  @override
  Future<int?> readCupsTarget() async => _preferences.getInt(_cupsKey);

  @override
  Future<void> saveCupsTarget(int cups) async {
    if (cups <= 0 || cups > 30) {
      throw ArgumentError.value(cups, 'cups');
    }
    final accepted = await _preferences.setInt(_cupsKey, cups);
    if (!accepted) throw StateError('Could not save cups target');
  }
}
