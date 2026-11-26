import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../food_catalog/data/datasources/local_food_data_source.dart';
import '../../data/ramadan_settings_store.dart';
import '../../domain/ramadan_logic.dart';

@immutable
class RamadanState {
  const RamadanState({
    required this.status,
    this.times,
    this.suggestions = const [],
    this.waterMl = 0,
    this.cupsTarget = defaultCupsTarget,
    this.cupsFromUser = false,
    this.saving = false,
  });

  final RamadanStatus status;

  /// Null until the user configures their own times; the screen then shows
  /// the honest setup state instead of invented prayer times.
  final RamadanTimes? times;
  final List<RamadanSuggestion> suggestions;

  /// Today's logged water from the daily log.
  final double waterMl;

  /// Cups target: the user-set value when [cupsFromUser], otherwise the
  /// design's presentation default, which the UI labels as such.
  final int cupsTarget;
  final bool cupsFromUser;
  final bool saving;

  static const defaultCupsTarget = 8;
  static const cupSizeMl = 250;

  int get filledCups => (waterMl / cupSizeMl).floor().clamp(0, cupsTarget);

  RamadanState copyWith({
    RamadanStatus? status,
    RamadanTimes? times,
    List<RamadanSuggestion>? suggestions,
    double? waterMl,
    int? cupsTarget,
    bool? cupsFromUser,
    bool? saving,
  }) => RamadanState(
    status: status ?? this.status,
    times: times ?? this.times,
    suggestions: suggestions ?? this.suggestions,
    waterMl: waterMl ?? this.waterMl,
    cupsTarget: cupsTarget ?? this.cupsTarget,
    cupsFromUser: cupsFromUser ?? this.cupsFromUser,
    saving: saving ?? this.saving,
  );
}

enum RamadanStatus { loading, ready, error }

class RamadanCubit extends Cubit<RamadanState> {
  RamadanCubit({
    required this.userId,
    this.currentUid,
    required this.settings,
    required this.nutrition,
    required this.foods,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const RamadanState(status: RamadanStatus.loading));

  final String userId;
  final String? Function()? currentUid;
  bool get inactive =>
      isClosed ||
      userId.isEmpty ||
      (currentUid != null && currentUid!() != userId);
  void assertActive() {
    if (inactive) throw StateError('Account no longer active');
  }

  @override
  void emit(RamadanState state) {
    if (!inactive) super.emit(state);
  }

  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }

  final RamadanSettingsStore settings;
  final NutritionRepository nutrition;
  final LocalFoodDataSource foods;
  final DateTime Function() _clock;

  DateTime get now => _clock();

  int _generation = 0;

  Future<void> load() async {
    assertActive();
    final myGeneration = ++_generation;
    emit(state.copyWith(status: RamadanStatus.loading));
    try {
      if (userId.trim().isEmpty) throw ArgumentError.value(userId, 'userId');
      final times = await settings.readTimes();
      final cups = await settings.readCupsTarget();
      final records = await foods.getAll();
      double? target;
      assertActive();
      final profiles = await nutrition.getNutritionProfiles(userId);
      for (final profile in profiles) {
        if (profile.isActive && profile.dailyCalorieTarget > 0) {
          target = profile.dailyCalorieTarget;
        }
      }
      assertActive();
      final todayLog = await nutrition.getDailyLog(
        userId,
        SufraDateUtils.toDateKey(_clock()),
      );
      if (inactive || myGeneration != _generation) return;
      emit(
        RamadanState(
          status: RamadanStatus.ready,
          times: times,
          suggestions: RamadanSuggester(
            catalog: records,
          ).suggest(dailyCalorieTarget: target),
          waterMl: todayLog?.waterIntakeMl ?? 0,
          cupsTarget: cups ?? RamadanState.defaultCupsTarget,
          cupsFromUser: cups != null,
        ),
      );
    } catch (_) {
      if (inactive || myGeneration != _generation) return;
      emit(const RamadanState(status: RamadanStatus.error));
    }
  }

  Future<bool> saveTimes(RamadanTimes times) async {
    if (inactive || state.saving) return false;
    final myGeneration = _generation;
    emit(state.copyWith(saving: true));
    try {
      await settings.saveTimes(times);
      if (inactive || myGeneration != _generation) return false;
      emit(state.copyWith(times: times, saving: false));
      return true;
    } catch (_) {
      if (inactive || myGeneration != _generation) return false;
      emit(state.copyWith(saving: false));
      return false;
    }
  }

  Future<bool> saveCupsTarget(int cups) async {
    assertActive();
    final myGeneration = _generation;
    try {
      await settings.saveCupsTarget(cups);
      if (inactive || myGeneration != _generation) return false;
      emit(state.copyWith(cupsTarget: cups, cupsFromUser: true));
      return true;
    } catch (_) {
      return false;
    }
  }
}
