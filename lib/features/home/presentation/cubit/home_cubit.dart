import '../../../favorites/data/favorites_repository.dart';
import '../../../../data/models/favorite_model.dart';
import 'dart:async';
import '../../../progress/data/hydration_goal_store.dart';
import '../../../../core/utils/nutrition_values.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../data/models/daily_log_model.dart';
import '../../../../data/models/meal_entry_model.dart';
import '../../../../data/models/nutrition_profile_model.dart';
import '../../../../data/models/user_profile_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/repositories/user_repository.dart';

sealed class HomeState {
  const HomeState();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeFailure extends HomeState {
  const HomeFailure(this.message);

  final String message;
}

class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.profile,
    required this.nutritionProfile,
    required this.todaysMeals,
    required this.dailyLog,
    required this.streakDays,
    this.hydrationGoalMl,
    this.recentLogs = const [],
    this.favorites = const [],
    this.favoritesAvailable = true,
    this.dateKey = '',
    this.liveFailed = false,
  });

  final UserProfileModel? profile;
  final NutritionProfileModel? nutritionProfile;
  final List<MealEntryModel> todaysMeals;
  final DailyLogModel? dailyLog;
  final int streakDays;
  final double? hydrationGoalMl;
  final List<DailyLogModel> recentLogs;
  final List<FavoriteModel> favorites;
  final bool favoritesAvailable;
  final String dateKey;
  final bool liveFailed;

  HomeLoaded updated({
    List<MealEntryModel>? meals,
    DailyLogModel? log,
    bool replaceLog = false,
    int? streak,
    List<DailyLogModel>? logs,
    bool? liveFailed,
  }) => HomeLoaded(
    profile: profile,
    nutritionProfile: nutritionProfile,
    todaysMeals: meals ?? todaysMeals,
    dailyLog: replaceLog ? log : dailyLog,
    streakDays: streak ?? streakDays,
    hydrationGoalMl: hydrationGoalMl,
    favorites: favorites,
    favoritesAvailable: favoritesAvailable,
    recentLogs: logs ?? recentLogs,
    dateKey: dateKey,
    liveFailed: liveFailed ?? this.liveFailed,
  );

  // Today's totals come from the meal entries when any exist; the daily
  // log aggregate is the fallback so meals are never double-counted.
  double get eatenCalories => todaysMeals.isNotEmpty
      ? todaysMeals.fold(0.0, (sum, meal) => sum + meal.totalCalories)
      : (dailyLog?.totalCalories ?? 0);

  double? get eatenProtein => todaysMeals.isNotEmpty
      ? sumKnownNutrients(todaysMeals.map((meal) => meal.totalProtein))
      : dailyLog?.totalProtein;

  double? get eatenCarbs => todaysMeals.isNotEmpty
      ? sumKnownNutrients(todaysMeals.map((meal) => meal.totalCarbs))
      : dailyLog?.totalCarbs;

  double? get eatenFat => todaysMeals.isNotEmpty
      ? sumKnownNutrients(todaysMeals.map((meal) => meal.totalFat))
      : dailyLog?.totalFat;

  double get waterCups =>
      ((dailyLog?.waterIntakeMl ?? 0) / 250).floorToDouble();
}

/// Loads the authenticated user's real data for the Home screen:
/// profile, active nutrition profile, today's meals, daily log and streak.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required UserRepository userRepository,
    required NutritionRepository nutritionRepository,
    DateTime Function()? clock,
    this.favoritesBackend,
  }) : _userRepository = userRepository,
       _nutritionRepository = nutritionRepository,
       _clock = clock ?? DateTime.now,
       super(const HomeLoading());

  final FavoritesBackend? favoritesBackend;
  final DateTime Function() _clock;
  int _loadVersion = 0;
  String? _uid;
  StreamSubscription<List<MealEntryModel>>? _mealsSubscription;
  StreamSubscription<DailyLogModel?>? _logSubscription;
  void stopLive() {
    _mealsSubscription?.cancel();
    _logSubscription?.cancel();
    _mealsSubscription = null;
    _logSubscription = null;
  }

  Future<void> clear() async {
    _uid = null;
    _loadVersion++;
    await _mealsSubscription?.cancel();
    await _logSubscription?.cancel();
    if (!isClosed) emit(const HomeLoading());
  }

  @override
  Future<void> close() async {
    _uid = null;
    _loadVersion++;
    await _mealsSubscription?.cancel();
    await _logSubscription?.cancel();
    return super.close();
  }

  final UserRepository _userRepository;
  final NutritionRepository _nutritionRepository;

  Future<void> load(String uid) async {
    if (isClosed) return;
    if (uid.isEmpty || uid.contains('/')) return;
    _uid = uid;
    final version = ++_loadVersion;
    await _mealsSubscription?.cancel();
    await _logSubscription?.cancel();
    if (isClosed || version != _loadVersion) return;
    emit(const HomeLoading());
    try {
      final todayKey = SufraDateUtils.toDateKey(_clock());
      final results = await Future.wait([
        _userRepository.getCurrentUser(),
        _nutritionRepository.getNutritionProfiles(uid),
        _nutritionRepository.getMealEntries(uid, dateKey: todayKey),
        _nutritionRepository.getDailyLog(uid, todayKey),
        _nutritionRepository.getDailyLogs(uid, limit: 60),
        HydrationGoalStore.read(uid),
        _loadFavorites(uid),
      ]);

      if (isClosed || version != _loadVersion) return;
      final profile = results[0] as UserProfileModel?;
      if (profile != null && profile.uid != uid) {
        throw StateError('Profile account mismatch');
      }
      final profiles = results[1] as List<NutritionProfileModel>;
      final rawMeals = results[2] as List<MealEntryModel>;
      if (rawMeals.any((m) => m.userId != uid || m.dateKey != todayKey)) {
        throw StateError('Meal account/date mismatch');
      }
      final meals = rawMeals
          .where((m) => m.analysisStatus == 'confirmed')
          .toList();
      final dailyLog = results[3] as DailyLogModel?;
      final logs = results[4] as List<DailyLogModel>;

      NutritionProfileModel? active;
      for (final p in profiles) {
        if (p.isActive) {
          active = p;
          break;
        }
      }
      if (dailyLog != null && dailyLog.dateKey != todayKey) {
        throw StateError('Daily date mismatch');
      }

      emit(
        HomeLoaded(
          profile: profile,
          nutritionProfile: active,
          todaysMeals: meals,
          dailyLog: dailyLog,
          streakDays: _computeStreak(logs),
          hydrationGoalMl: results[5] as double?,
          favorites: results[6] as List<FavoriteModel>? ?? [],
          favoritesAvailable: results[6] != null,
          recentLogs: List.unmodifiable(logs),
          dateKey: todayKey,
        ),
      );
      final repository = _nutritionRepository;
      if (repository is LiveDiaryRepository && version == _loadVersion) {
        final live = repository as LiveDiaryRepository;
        void failure(Object e, StackTrace stack) {
          final current = state;
          if (!isClosed &&
              _uid == uid &&
              version == _loadVersion &&
              current is HomeLoaded) {
            emit(current.updated(liveFailed: true));
          }
        }

        _mealsSubscription = live.watchMealEntries(uid, todayKey).listen((
          meals,
        ) {
          final current = state;
          if (isClosed ||
              _uid != uid ||
              version != _loadVersion ||
              current is! HomeLoaded) {
            return;
          }
          if (meals.any((m) => m.userId != uid || m.dateKey != todayKey)) {
            failure(StateError('Mismatched meals'), StackTrace.current);
            return;
          }
          emit(
            current.updated(
              meals: List.unmodifiable(
                meals.where((m) => m.analysisStatus == 'confirmed'),
              ),
              liveFailed: false,
            ),
          );
        }, onError: failure);
        _logSubscription = live.watchDailyLog(uid, todayKey).listen((log) {
          final current = state;
          if (isClosed ||
              _uid != uid ||
              version != _loadVersion ||
              current is! HomeLoaded) {
            return;
          }
          if (log != null && log.dateKey != todayKey) {
            failure(StateError('Mismatched log'), StackTrace.current);
            return;
          }
          final logs = [
            if (log != null) log,
            ...current.recentLogs.where((l) => l.dateKey != todayKey),
          ];
          emit(
            current.updated(
              log: log,
              replaceLog: true,
              logs: List.unmodifiable(logs),
              streak: _computeStreak(logs),
              liveFailed: false,
            ),
          );
        }, onError: failure);
      }
    } catch (error) {
      if (!isClosed && version == _loadVersion) {
        emit(HomeFailure(error.toString()));
      }
    }
  }

  Future<List<FavoriteModel>?> _loadFavorites(String uid) async {
    try {
      return await favoritesBackend?.loadAll(uid) ?? [];
    } catch (_) {
      return null;
    }
  }

  /// Consecutive days ending today (or yesterday) that have a daily log
  /// with at least one recorded meal.
  int _computeStreak(List<DailyLogModel> logs) {
    final byDate = {for (final log in logs) log.dateKey: log};
    var cursor = SufraDateUtils.startOfDay(_clock());
    // Allow the streak to start yesterday when today has no logs yet.
    final todayKey = SufraDateUtils.toDateKey(cursor);
    final todayLog = byDate[todayKey];
    if (todayLog == null || todayLog.mealCount == 0) {
      cursor = SufraDateUtils.shiftDays(cursor, -1);
    }
    var streak = 0;
    while (true) {
      final key = SufraDateUtils.toDateKey(cursor);
      final log = byDate[key];
      if (log == null || log.mealCount == 0) break;
      streak++;
      cursor = SufraDateUtils.shiftDays(cursor, -1);
    }
    return streak;
  }
}
