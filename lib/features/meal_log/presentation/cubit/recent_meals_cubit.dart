import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../data/models/meal_entry_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';

enum RecentMealsStatus { loading, ready, saving, saved, failure }

class RecentMealsState {
  const RecentMealsState(this.status, {this.meal});
  final RecentMealsStatus status;
  final MealEntryModel? meal;
}

/// Owns recent-meal reads and re-log writes. Bound to one authenticated UID.
/// Retry uses the same document ID, so a lost acknowledgement cannot create
/// a second meal. A successful save requires a new explicit user action.
class RecentMealsCubit extends Cubit<RecentMealsState> {
  RecentMealsCubit({
    required this.repository,
    required this.uid,
    required this.currentUid,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const RecentMealsState(RecentMealsStatus.loading));

  final NutritionRepository repository;
  final String uid;
  final String? Function() currentUid;
  final DateTime Function() _clock;
  MealEntryModel? _pending;
  bool _busy = false;
  int _readVersion = 0;

  bool get _active => !isClosed && uid.isNotEmpty && currentUid() == uid;

  Future<void> load() async {
    if (!_active || _busy) return;
    final version = ++_readVersion;
    emit(const RecentMealsState(RecentMealsStatus.loading));
    try {
      final meals = await repository.getMealEntries(uid);
      if (!_active || version != _readVersion) return;
      final owned = meals.where((m) => m.userId == uid).toList()
        ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
      emit(
        RecentMealsState(
          RecentMealsStatus.ready,
          meal: owned.isEmpty ? null : owned.first,
        ),
      );
    } catch (_) {
      if (_active && version == _readVersion) {
        emit(const RecentMealsState(RecentMealsStatus.failure));
      }
    }
  }

  Future<void> relog() async {
    final meal = state.meal;
    if (!_active || _busy || meal == null || meal.userId != uid) return;
    _busy = true;
    final now = _clock();
    _pending ??= MealEntryModel(
      mealId: 'relog-${now.microsecondsSinceEpoch}',
      userId: uid,
      dateKey: SufraDateUtils.toDateKey(now),
      consumedAt: now,
      mealType: meal.mealType,
      inputMethod: 'relog',
      title: meal.title,
      imageUrl: meal.imageUrl,
      items: List.unmodifiable(meal.items),
      totalCalories: meal.totalCalories,
      totalProtein: meal.totalProtein,
      totalCarbs: meal.totalCarbs,
      totalFat: meal.totalFat,
      totalFiber: meal.totalFiber,
      totalSugar: meal.totalSugar,
      totalSodium: meal.totalSodium,
      analysisStatus: meal.analysisStatus,
      confidence: meal.confidence,
      estimatedRange: meal.estimatedRange,
      nutritionSource: meal.nutritionSource,
    );
    emit(RecentMealsState(RecentMealsStatus.saving, meal: meal));
    try {
      if (!_active) return;
      await repository.saveMealEntry(uid, _pending!);
      if (!_active) return;
      _pending = null;
      emit(RecentMealsState(RecentMealsStatus.saved, meal: meal));
    } catch (_) {
      if (_active) {
        emit(RecentMealsState(RecentMealsStatus.failure, meal: meal));
      }
    } finally {
      _busy = false;
    }
  }
}
