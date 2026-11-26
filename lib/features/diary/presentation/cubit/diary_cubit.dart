import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../data/models/daily_log_model.dart';
import '../../../../data/models/meal_entry_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';

class DiaryState {
  const DiaryState({
    required this.date,
    this.loading = false,
    this.failed = false,
    this.meals = const [],
    this.calorieTarget,
  });
  final DateTime date;
  final bool loading;
  final bool failed;
  final List<MealEntryModel> meals;
  final double? calorieTarget;
  double get calories => meals.fold(0, (sum, meal) => sum + meal.totalCalories);
}

class DiaryCubit extends Cubit<DiaryState> {
  DiaryCubit({
    required this.repository,
    required this.uid,
    required this.currentUid,
    DateTime? date,
  }) : super(DiaryState(date: date ?? DateTime.now()));
  final NutritionRepository repository;
  final String uid;
  final String? Function() currentUid;
  int _version = 0;
  StreamSubscription<List<MealEntryModel>>? _meals;
  StreamSubscription<DailyLogModel?>? _log;
  @override
  Future<void> close() async {
    _version++;
    await _meals?.cancel();
    await _log?.cancel();
    return super.close();
  }

  Future<void> load([DateTime? date]) async {
    if (isClosed || uid.isEmpty || currentUid() != uid) return;
    final version = ++_version;
    final oldMeals = _meals;
    final oldLog = _log;
    _meals = null;
    _log = null;
    if (oldMeals != null) await oldMeals.cancel();
    if (oldLog != null) await oldLog.cancel();
    if (isClosed || version != _version || currentUid() != uid) return;
    final day = date ?? state.date;
    emit(DiaryState(date: day, loading: true));
    try {
      final key = SufraDateUtils.toDateKey(day);
      final results = await Future.wait<Object?>([
        repository.getMealEntries(uid, dateKey: key),
        repository.getDailyLog(uid, key),
      ]);
      final meals = results[0] as List<MealEntryModel>;
      final log = results[1] as DailyLogModel?;
      if (isClosed || version != _version || currentUid() != uid) return;
      final owned =
          meals.where((m) => m.userId == uid && m.dateKey == key).toList()
            ..sort((a, b) => a.consumedAt.compareTo(b.consumedAt));
      final target = log?.dateKey == key ? log?.calorieTarget : null;
      emit(
        DiaryState(
          date: day,
          meals: List.unmodifiable(owned),
          calorieTarget: target != null && target.isFinite && target > 0
              ? target
              : null,
        ),
      );
      if (repository is LiveDiaryRepository) {
        final live = repository as LiveDiaryRepository;
        bool active() =>
            !isClosed && version == _version && currentUid() == uid;
        var mealsFailed = false;
        var logFailed = false;
        void failed(Object _, {required bool meals}) {
          if (!active()) return;
          if (meals) {
            mealsFailed = true;
          } else {
            logFailed = true;
          }
          emit(
            DiaryState(
              date: day,
              failed: true,
              meals: state.meals,
              calorieTarget: state.calorieTarget,
            ),
          );
        }

        _meals = live.watchMealEntries(uid, key).listen((items) {
          if (!active()) return;
          mealsFailed = false;
          final owned =
              items.where((m) => m.userId == uid && m.dateKey == key).toList()
                ..sort((a, b) => a.consumedAt.compareTo(b.consumedAt));
          emit(
            DiaryState(
              date: day,
              failed: logFailed,
              meals: List.unmodifiable(owned),
              calorieTarget: state.calorieTarget,
            ),
          );
        }, onError: (Object error) => failed(error, meals: true));
        _log = live.watchDailyLog(uid, key).listen((log) {
          if (!active()) return;
          logFailed = false;
          final target = log?.dateKey == key ? log?.calorieTarget : null;
          emit(
            DiaryState(
              date: day,
              failed: mealsFailed,
              meals: state.meals,
              calorieTarget: target != null && target.isFinite && target > 0
                  ? target
                  : null,
            ),
          );
        }, onError: (Object error) => failed(error, meals: false));
      }
    } catch (_) {
      if (!isClosed && version == _version && currentUid() == uid) {
        emit(DiaryState(date: day, failed: true));
      }
    }
  }
}
