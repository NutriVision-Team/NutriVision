import 'package:clock/clock.dart' as time;
import '../../data/hydration_goal_store.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../data/models/daily_log_model.dart';
import '../../../../data/models/meal_entry_model.dart';
import '../../../../data/models/nutrition_profile_model.dart';
import '../../../../data/models/user_profile_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../domain/day_nutrition.dart';

/// Week or month window for the statistics screen.
enum ProgressPeriod { week, month }

class ProgressState {
  const ProgressState({
    required this.period,
    this.loading = false,
    this.failed = false,
    this.days = const [],
    this.streakDays = 0,
    this.activeProfile,
    this.userProfile,
    this.mealTypeCounts = const {},
    this.hydrationGoalMl,
  });

  final ProgressPeriod period;
  final double? hydrationGoalMl;
  final bool loading;
  final bool failed;

  /// Chronological window (oldest first) covering the current period.
  final List<DayNutrition> days;
  final int streakDays;
  final NutritionProfileModel? activeProfile;
  final UserProfileModel? userProfile;

  /// Counts of owned meal entries per meal type inside the current period
  /// window, aggregated locally from MealEntryModel.mealType reads.
  final Map<String, int> mealTypeCounts;

  NutritionAverages get averages => NutritionAverages.of(days);
}

/// Loads daily-log aggregates and the active nutrition profile for the
/// statistics and weekly-report screens. Reads only the existing
/// NutritionRepository contracts (meal aggregation stays lead-owned).
class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit({
    required NutritionRepository nutritionRepository,
    UserRepository? userRepository,
    required this.uid,
    required this.currentUid,
    DateTime Function()? clock,
  }) : _nutritionRepository = nutritionRepository,
       _userRepository = userRepository,
       _clock = clock ?? time.clock.now,
       super(const ProgressState(period: ProgressPeriod.week));

  final NutritionRepository _nutritionRepository;
  final UserRepository? _userRepository;
  final String uid;
  final String? Function() currentUid;
  final DateTime Function() _clock;
  int _version = 0;

  static const int _windowDays = 35;

  bool _stale() => isClosed || uid.isEmpty || currentUid() != uid;

  /// Historical reports read the existing per-date documents, in bounded batches.
  Future<void> loadRange(DateTime start, DateTime end) async {
    if (_stale()) return;
    final first = DateTime(start.year, start.month, start.day),
        last = DateTime(end.year, end.month, end.day);
    final count =
        DateTime.utc(
          last.year,
          last.month,
          last.day,
        ).difference(DateTime.utc(first.year, first.month, first.day)).inDays +
        1;
    if (count < 1 || count > 366) {
      throw ArgumentError('A report range must contain1to366days');
    }
    final version = ++_version;
    emit(
      ProgressState(
        period: state.period,
        loading: true,
        days: state.days,
        activeProfile: state.activeProfile,
        userProfile: state.userProfile,
        hydrationGoalMl: state.hydrationGoalMl,
      ),
    );
    try {
      final days = <DayNutrition>[];
      for (var offset = 0; offset < count; offset += 12) {
        if (_stale() || version != _version) return;
        final length = count - offset < 12 ? count - offset : 12;
        final batch = await Future.wait(
          List.generate(length, (i) async {
            final date = DateTime(
                  first.year,
                  first.month,
                  first.day + offset + i,
                ),
                key = SufraDateUtils.toDateKey(
                  DateTime(first.year, first.month, first.day + offset + i),
                );
            final log = await _nutritionRepository.getDailyLog(uid, key);
            if (log != null && log.dateKey != key) {
              throw StateError('Report date mismatch');
            }
            return log == null
                ? DayNutrition.empty(SufraDateUtils.toDateKey(date))
                : DayNutrition.fromLog(log);
          }),
        );
        days.addAll(batch);
      }
      if (_stale() || version != _version) return;
      emit(
        ProgressState(
          period: state.period,
          days: List.unmodifiable(days),
          activeProfile: state.activeProfile,
          userProfile: state.userProfile,
          hydrationGoalMl: state.hydrationGoalMl,
        ),
      );
    } catch (_) {
      if (!_stale() && version == _version) {
        emit(ProgressState(period: state.period, failed: true));
      }
    }
  }

  Future<void> load([ProgressPeriod? period]) async {
    if (_stale()) return;
    final version = ++_version;
    final next = period ?? state.period;
    emit(
      ProgressState(
        period: next,
        loading: true,
        days: state.days,
        streakDays: state.streakDays,
        activeProfile: state.activeProfile,
        userProfile: state.userProfile,
        hydrationGoalMl: state.hydrationGoalMl,
      ),
    );
    try {
      final userRepository = _userRepository;
      final results = await Future.wait([
        _nutritionRepository.getDailyLogs(uid, limit: _windowDays),
        _nutritionRepository.getNutritionProfiles(uid),
        _nutritionRepository.getMealEntries(uid),
        if (userRepository != null)
          userRepository.getCurrentUser()
        else
          Future<UserProfileModel?>.value(),
        HydrationGoalStore.read(uid),
      ]);
      if (isClosed || version != _version || _stale()) return;
      final logs = results[0] as List<DailyLogModel>;
      final profiles = results[1] as List<NutritionProfileModel>;
      final meals = results[2] as List<MealEntryModel>;
      final userProfile = results[3] as UserProfileModel?;
      if (userProfile != null &&
          userProfile.uid.isNotEmpty &&
          userProfile.uid != uid) {
        throw StateError('Profile account mismatch');
      }

      NutritionProfileModel? active;
      for (final p in profiles) {
        if (p.isActive) {
          active = p;
          break;
        }
      }
      active ??= profiles.isNotEmpty ? profiles.first : null;

      final byKey = {for (final log in logs) log.dateKey: log};
      final length = next == ProgressPeriod.week ? 7 : 30;
      final today = SufraDateUtils.startOfDay(_clock());
      final days = List.generate(length, (i) {
        final date = SufraDateUtils.shiftDays(today, -(length - 1 - i));
        final key = SufraDateUtils.toDateKey(date);
        final log = byKey[key];
        return log == null
            ? DayNutrition.empty(key)
            : DayNutrition.fromLog(log);
      });

      final counts = <String, int>{};
      final windowKeys = {for (final d in days) d.dateKey};
      for (final meal in meals) {
        if (meal.userId != uid || !windowKeys.contains(meal.dateKey)) {
          continue;
        }
        counts.update(meal.mealType, (v) => v + 1, ifAbsent: () => 1);
      }

      emit(
        ProgressState(
          period: next,
          days: List.unmodifiable(days),
          streakDays: computeTrackedStreak(days, _clock()),
          activeProfile: active,
          userProfile: userProfile,
          hydrationGoalMl: results[4] as double?,
          mealTypeCounts: Map.unmodifiable(counts),
        ),
      );
    } catch (_) {
      if (!isClosed && version == _version && !_stale()) {
        emit(ProgressState(period: next, failed: true));
      }
    }
  }
}
