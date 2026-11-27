import '../../../nutrition_plan/domain/nutrition_plan_service.dart';
import 'package:clock/clock.dart' as time;
import '../../../../core/utils/operation_id.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../data/models/nutrition_profile_model.dart';
import '../../../../data/models/weight_log_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../data/water_weight_repository.dart';

class WeightState {
  const WeightState({
    this.loading = false,
    this.failed = false,
    this.saving = false,
    this.logs = const [],
    this.weekLogged = const [],
    this.weekDates = const [],
    this.activeProfile,
  });

  final bool loading;
  final bool failed;
  final bool saving;

  /// Newest first.
  final List<WeightLogModel> logs;

  /// Whether each of the last 7 days (oldest first) owns a weight log.
  final List<bool> weekLogged;
  final List<DateTime> weekDates;
  final NutritionProfileModel? activeProfile;

  double? get currentWeight =>
      logs.isNotEmpty ? logs.first.weightKg : activeProfile?.currentWeightKg;
  double? get targetWeight => activeProfile?.targetWeightKg;

  /// Start of the journey: oldest log in the loaded window, falling back
  /// to the profile's recorded weight. Null when nothing is known.
  double? get startWeight {
    if (logs.isNotEmpty) return logs.last.weightKg;
    return activeProfile?.currentWeightKg;
  }

  /// Delta of current vs start; null when there is no earlier reference
  /// point (a single log cannot prove a trend).
  double? get deltaKg {
    final current = currentWeight;
    final start = startWeight;
    if (current == null || start == null || logs.length < 2) return null;
    return start - current;
  }

  /// Progress toward the target (0..1). Weight-loss direction assumed
  /// from target < start; null when a goal direction cannot be derived.
  double? get goalFraction {
    final current = currentWeight;
    final start = startWeight;
    final target = targetWeight;
    if (current == null || start == null || target == null) return null;
    final span = (start - target).abs();
    if (span <= 0) return null;
    return ((start - current) / (start - target)).clamp(0.0, 1.0);
  }
}

class WeightCubit extends Cubit<WeightState> {
  WeightCubit({
    required WaterWeightRepository waterWeightRepository,
    required NutritionRepository nutritionRepository,
    required this.uid,
    required this.currentUid,
    DateTime Function()? clock,
  }) : _waterWeightRepository = waterWeightRepository,
       _nutritionRepository = nutritionRepository,
       _clock = clock ?? time.clock.now,
       super(const WeightState());

  final WaterWeightRepository _waterWeightRepository;
  final NutritionRepository _nutritionRepository;
  final String uid;
  final String? Function() currentUid;
  final DateTime Function() _clock;
  int _version = 0;
  ({String id, double amount, DateTime at})? _pending;
  double? get pendingAmount => _pending?.amount;
  Future<void> retryOrLoad() async {
    final pending = _pending;
    if (pending == null) {
      await load();
    } else {
      await addWeight(pending.amount);
    }
  }

  bool _stale() => isClosed || uid.isEmpty || currentUid() != uid;

  Future<void> load({DateTime? rangeStart, DateTime? rangeEnd}) async {
    if (_stale()) return;
    final version = ++_version;
    emit(
      WeightState(
        loading: true,
        logs: state.logs,
        weekLogged: state.weekLogged,
        weekDates: state.weekDates,
        activeProfile: state.activeProfile,
      ),
    );
    try {
      final results = await Future.wait([
        if (rangeStart != null &&
            rangeEnd != null &&
            _waterWeightRepository is WeightHistoryRangeReader)
          (_waterWeightRepository as WeightHistoryRangeReader)
              .getWeightHistoryRange(uid, rangeStart, rangeEnd)
        else
          _waterWeightRepository.getWeightLogs(uid, limit: 60),
        _nutritionRepository.getNutritionProfiles(uid),
      ]);
      if (isClosed || version != _version || _stale()) return;
      final logs = List<WeightLogModel>.from(results[0] as List<WeightLogModel>)
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      final profiles = results[1] as List<NutritionProfileModel>;
      if (_pending != null && logs.any((e) => e.weightId == _pending!.id)) {
        _pending = null;
      }

      NutritionProfileModel? active;
      for (final p in profiles) {
        if (p.isActive) {
          active = p;
          break;
        }
      }
      active ??= profiles.isNotEmpty ? profiles.first : null;

      final keys = {for (final l in logs) l.dateKey};
      final today = SufraDateUtils.startOfDay(_clock());
      final dates = List.generate(
        7,
        (i) => today.subtract(Duration(days: 6 - i)),
      );
      final week = [
        for (final date in dates) keys.contains(SufraDateUtils.toDateKey(date)),
      ];

      emit(
        WeightState(
          logs: List.unmodifiable(logs),
          weekLogged: List.unmodifiable(week),
          weekDates: List.unmodifiable(dates),
          activeProfile: active,
        ),
      );
    } catch (_) {
      if (!isClosed && version == _version && !_stale()) {
        emit(const WeightState(failed: true));
      }
    }
  }

  Future<void> addWeight(double weightKg, {DateTime? recordedAt}) async {
    if (_stale() || state.saving || !weightKg.isFinite || weightKg <= 0) return;
    if (_pending != null && _pending!.amount != weightKg) {
      emit(
        WeightState(
          failed: true,
          logs: state.logs,
          weekLogged: state.weekLogged,
          weekDates: state.weekDates,
          activeProfile: state.activeProfile,
        ),
      );
      return;
    }
    final pending = _pending ??= (
      id: newOperationId('weight'),
      amount: weightKg,
      at: recordedAt ?? _clock(),
    );
    final version = ++_version;
    emit(
      WeightState(
        saving: true,
        logs: state.logs,
        weekLogged: state.weekLogged,
        weekDates: state.weekDates,
        activeProfile: state.activeProfile,
      ),
    );
    try {
      await _waterWeightRepository.addWeightLog(
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
          WeightState(
            failed: true,
            logs: state.logs,
            weekLogged: state.weekLogged,
            weekDates: state.weekDates,
            activeProfile: state.activeProfile,
          ),
        );
      }
    }
  }

  NutritionProfileModel previewGoal(double targetKg, String goal) {
    final p = state.activeProfile;
    final weight = state.currentWeight;
    if (p == null ||
        weight == null ||
        !targetKg.isFinite ||
        !['lose', 'maintain', 'gain'].contains(goal)) {
      throw StateError('Missing or invalid goal');
    }
    final service = const NutritionPlanService();
    if (service.ageAt(p.dateOfBirth, _clock()) < 18 ||
        p.healthRestrictions.isNotEmpty) {
      throw StateError('A qualified professional should review this plan');
    }
    if ((goal == 'lose' && targetKg >= weight) ||
        (goal == 'gain' && targetKg <= weight) ||
        (goal == 'maintain' && (targetKg - weight).abs() > .1)) {
      throw StateError('Goal direction does not match target');
    }
    final result = service.compute(
      NutritionPlanInput(
        gender: p.gender,
        dateOfBirth: p.dateOfBirth,
        heightCm: p.heightCm,
        currentWeightKg: weight,
        targetWeightKg: targetKg,
        activityLevel: p.activityLevel,
        nutritionGoal: goal,
        referenceDate: _clock(),
      ),
    );
    return NutritionProfileModel(
      profileId: p.profileId,
      gender: p.gender,
      dateOfBirth: p.dateOfBirth,
      heightCm: p.heightCm,
      currentWeightKg: weight,
      targetWeightKg: targetKg,
      activityLevel: p.activityLevel,
      nutritionGoal: goal,
      dailyCalorieTarget: result.dailyCalories,
      proteinTarget: result.proteinGrams,
      carbsTarget: result.carbsGrams,
      fatTarget: result.fatGrams,
      dietaryPreferences: p.dietaryPreferences,
      allergies: p.allergies,
      healthRestrictions: p.healthRestrictions,
      isActive: p.isActive,
      createdAt: p.createdAt,
    );
  }

  /// Explicit goal save. Never rewrites historical weight or daily logs.
  Future<bool> saveGoal(NutritionProfileModel preview) async {
    if (_stale() || state.saving || _pending != null) return false;
    final old = state.activeProfile;
    if (old == null) return false;
    final version = ++_version;
    emit(
      WeightState(
        saving: true,
        logs: state.logs,
        weekLogged: state.weekLogged,
        weekDates: state.weekDates,
        activeProfile: old,
      ),
    );
    try {
      final current = await _nutritionRepository.getNutritionProfiles(uid);
      if (_stale() || version != _version) return false;
      final matches = current.where((p) => p.profileId == old.profileId);
      if (matches.length != 1 ||
          matches.single.updatedAt != old.updatedAt ||
          matches.single.currentWeightKg != old.currentWeightKg ||
          matches.single.targetWeightKg != old.targetWeightKg ||
          matches.single.nutritionGoal != old.nutritionGoal) {
        throw StateError('Profile changed');
      }
      final validated = previewGoal(
        preview.targetWeightKg,
        preview.nutritionGoal,
      );
      if (validated.dailyCalorieTarget != preview.dailyCalorieTarget ||
          validated.currentWeightKg != preview.currentWeightKg) {
        throw StateError('Preview changed');
      }
      await _nutritionRepository.saveNutritionProfile(uid, validated);
      if (_stale() || version != _version) return false;
      final saved = await _nutritionRepository.getNutritionProfiles(uid);
      if (_stale() || version != _version) return false;
      if (!saved.any(
        (p) =>
            p.profileId == validated.profileId &&
            p.targetWeightKg == validated.targetWeightKg &&
            p.nutritionGoal == validated.nutritionGoal &&
            p.dailyCalorieTarget == validated.dailyCalorieTarget,
      )) {
        throw StateError('Goal readback failed');
      }
      await load();
      return !_stale() && !state.failed;
    } catch (_) {
      if (!_stale() && version == _version) {
        emit(
          WeightState(
            failed: true,
            logs: state.logs,
            weekLogged: state.weekLogged,
            weekDates: state.weekDates,
            activeProfile: old,
          ),
        );
      }
      return false;
    }
  }

  bool get canEditRecords => _waterWeightRepository is WeightRecordEditor;
  Future<void> changeRecord(WeightLogModel log, {bool delete = false}) async {
    if (_stale() ||
        state.saving ||
        _pending != null ||
        !state.logs.any((w) => w.weightId == log.weightId) ||
        !canEditRecords) {
      return;
    }
    final version = ++_version;
    emit(
      WeightState(
        saving: true,
        logs: state.logs,
        weekLogged: state.weekLogged,
        weekDates: state.weekDates,
        activeProfile: state.activeProfile,
      ),
    );
    try {
      final editor = _waterWeightRepository as WeightRecordEditor;
      if (delete) {
        await editor.deleteWeightRecord(uid, log.weightId);
      } else {
        await editor.updateWeightRecord(uid, log);
      }
      if (_stale() || version != _version) return;
      await load();
    } catch (_) {
      if (!_stale() && version == _version) {
        emit(
          WeightState(
            failed: true,
            logs: state.logs,
            weekLogged: state.weekLogged,
            weekDates: state.weekDates,
            activeProfile: state.activeProfile,
          ),
        );
      }
    }
  }
}
