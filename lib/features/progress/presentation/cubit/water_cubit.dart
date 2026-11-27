import 'package:clock/clock.dart' as time;
import '../../data/hydration_goal_store.dart';
import '../../../../core/utils/operation_id.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../data/models/daily_log_model.dart';
import '../../../../data/models/water_log_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../data/water_weight_repository.dart';

class WaterState {
  const WaterState({
    this.loading = false,
    this.failed = false,
    this.saving = false,
    this.totalMl = 0,
    this.entries = const [],
    this.weekMl = const [],
    this.weekDates = const [],
    this.goalMl = WaterCubit.defaultGoalMl,
    this.goalChosen = false,
  });

  final bool loading;
  final bool failed;
  final bool saving;
  final double totalMl;
  final List<WaterLogModel> entries;

  /// Last 7 days of water intake in ml, oldest first (today last).
  final List<double> weekMl;
  final List<String> weekDates;

  /// Device-local explicit choice, or the disclosed unpersonalized default.
  final double goalMl;
  final bool goalChosen;

  double get cups => totalMl / WaterCubit.cupMl;
  double get goalCups => goalMl / WaterCubit.cupMl;
  double get fraction => goalMl > 0 ? (totalMl / goalMl).clamp(0, 1) : 0;
}

/// Today's hydration plus the trailing 7-day totals, with writes that go
/// through the transactional water-log append contract.
class WaterCubit extends Cubit<WaterState> {
  WaterCubit({
    required WaterWeightRepository waterWeightRepository,
    required NutritionRepository nutritionRepository,
    required this.uid,
    required this.currentUid,
    DateTime Function()? clock,
  }) : _waterWeightRepository = waterWeightRepository,
       _nutritionRepository = nutritionRepository,
       _clock = clock ?? time.clock.now,
       super(const WaterState());

  static const double defaultGoalMl = 2000;
  static const double cupMl = 250;

  final WaterWeightRepository _waterWeightRepository;
  final NutritionRepository _nutritionRepository;
  final String uid;
  final String? Function() currentUid;
  final DateTime Function() _clock;
  int _version = 0;
  bool _choosingGoal = false;
  ({String id, double amount, DateTime at})? _pending;
  double? get pendingAmount => _pending?.amount;
  Future<void> retryOrLoad() async {
    final pending = _pending;
    if (pending == null) {
      await load();
    } else {
      await addWater(pending.amount);
    }
  }

  bool _stale() => isClosed || uid.isEmpty || currentUid() != uid;

  Future<void> load() async {
    if (_stale()) return;
    final version = ++_version;
    emit(
      WaterState(
        loading: true,
        totalMl: state.totalMl,
        entries: state.entries,
        weekMl: state.weekMl,
        weekDates: state.weekDates,
        goalMl: state.goalMl,
        goalChosen: state.goalChosen,
      ),
    );
    try {
      final todayKey = SufraDateUtils.toDateKey(_clock());
      final results = await Future.wait([
        _waterWeightRepository.getWaterLogs(uid, todayKey),
        _nutritionRepository.getDailyLogs(uid, limit: 7),
        HydrationGoalStore.read(uid),
      ]);
      if (isClosed || version != _version || _stale()) return;
      final entries = (results[0] as List<WaterLogModel>)
          .where(
            (e) =>
                e.dateKey == todayKey && e.amountMl.isFinite && e.amountMl > 0,
          )
          .toList();
      final logs = results[1] as List<DailyLogModel>;
      if (_pending != null && entries.any((e) => e.waterId == _pending!.id)) {
        _pending = null;
      }
      final byKey = {for (final log in logs) log.dateKey: log};
      final today = SufraDateUtils.startOfDay(_clock());
      final weekDates = List.generate(
        7,
        (i) => SufraDateUtils.toDateKey(today.subtract(Duration(days: 6 - i))),
      );
      final week = [
        for (final key in weekDates) byKey[key]?.waterIntakeMl ?? 0.0,
      ];
      final total = entries.fold<double>(
        0,
        (sum, e) => sum + (e.amountMl > 0 ? e.amountMl : 0),
      );
      emit(
        WaterState(
          totalMl: total,
          goalMl: results[2] as double? ?? HydrationGoalStore.defaultMl,
          goalChosen: results[2] != null,
          entries: List.unmodifiable(entries),
          weekMl: List.unmodifiable(week),
          weekDates: List.unmodifiable(weekDates),
        ),
      );
    } catch (_) {
      if (!isClosed && version == _version && !_stale()) {
        emit(const WaterState(failed: true));
      }
    }
  }

  Future<void> chooseGoal(double ml) async {
    if (_stale() || state.saving || _choosingGoal) return;
    _choosingGoal = true;
    try {
      await HydrationGoalStore.save(uid, ml);
      if (_stale()) return;
      await load();
    } finally {
      _choosingGoal = false;
    }
  }

  Future<void> addWater(double amountMl) async {
    if (_stale() || state.saving || !amountMl.isFinite || amountMl <= 0) return;
    if (_pending != null && _pending!.amount != amountMl) {
      emit(
        WaterState(
          failed: true,
          totalMl: state.totalMl,
          entries: state.entries,
          weekMl: state.weekMl,
          weekDates: state.weekDates,
          goalMl: state.goalMl,
          goalChosen: state.goalChosen,
        ),
      );
      return;
    }
    final pending = _pending ??= (
      id: newOperationId('water'),
      amount: amountMl,
      at: _clock(),
    );
    final version = ++_version;
    emit(
      WaterState(
        saving: true,
        totalMl: state.totalMl,
        entries: state.entries,
        weekMl: state.weekMl,
        weekDates: state.weekDates,
        goalMl: state.goalMl,
        goalChosen: state.goalChosen,
      ),
    );
    try {
      await _waterWeightRepository.addWaterLog(
        uid,
        pending.amount,
        pending.at,
        operationId: pending.id,
      );
      if (isClosed || version != _version || _stale()) return;
      _pending = null;
      await load();
    } catch (_) {
      if (!isClosed && version == _version && !_stale()) {
        emit(
          WaterState(
            failed: true,
            totalMl: state.totalMl,
            entries: state.entries,
            weekMl: state.weekMl,
            weekDates: state.weekDates,
            goalMl: state.goalMl,
            goalChosen: state.goalChosen,
          ),
        );
      }
    }
  }
}
