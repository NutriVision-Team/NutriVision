import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../data/models/meal_entry_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';

enum MealDetailStatus {
  loading,
  ready,
  missing,
  failure,
  saving,
  deleting,
  saved,
  deleted,
  expired,
}

class MealDetailState {
  const MealDetailState(this.status, {this.meal, this.mutationFailed = false});
  final MealDetailStatus status;
  final MealEntryModel? meal;
  final bool mutationFailed;
  bool get busy =>
      status == MealDetailStatus.saving || status == MealDetailStatus.deleting;
}

class MealDetailCubit extends Cubit<MealDetailState> {
  MealDetailCubit({
    required this.repository,
    required this.uid,
    required this.mealId,
    required this.dateKey,
    required this.currentUid,
  }) : super(const MealDetailState(MealDetailStatus.loading));
  final NutritionRepository repository;
  final String uid, mealId, dateKey;
  final String? Function() currentUid;
  int _generation = 0;
  bool get _active => !isClosed && uid.isNotEmpty && currentUid() == uid;
  Future<void> load() async {
    if (!_active) {
      if (!isClosed) emit(const MealDetailState(MealDetailStatus.expired));
      return;
    }
    if (state.busy) return;
    final generation = ++_generation;
    emit(const MealDetailState(MealDetailStatus.loading));
    try {
      final date = DateTime.tryParse(dateKey);
      if (date == null || SufraDateUtils.toDateKey(date) != dateKey) {
        throw const FormatException('Invalid meal date');
      }
      final meals = await repository.getMealEntries(uid, dateKey: dateKey);
      if (isClosed || generation != _generation) return;
      if (!_active) {
        emit(const MealDetailState(MealDetailStatus.expired));
        return;
      }
      final meal = meals
          .where(
            (m) =>
                m.mealId == mealId && m.userId == uid && m.dateKey == dateKey,
          )
          .firstOrNull;
      emit(
        MealDetailState(
          meal == null ? MealDetailStatus.missing : MealDetailStatus.ready,
          meal: meal,
        ),
      );
    } catch (_) {
      if (isClosed || generation != _generation) return;
      emit(
        MealDetailState(
          _active ? MealDetailStatus.failure : MealDetailStatus.expired,
        ),
      );
    }
  }

  Future<void> save(MealEntryModel replacement) async {
    if (!_active) {
      if (!isClosed) emit(const MealDetailState(MealDetailStatus.expired));
      return;
    }
    if (state.busy ||
        state.meal == null ||
        (state.status == MealDetailStatus.deleted ||
            state.status == MealDetailStatus.saved)) {
      return;
    }
    if (replacement.userId != uid || replacement.mealId != mealId) {
      emit(
        MealDetailState(
          MealDetailStatus.ready,
          meal: state.meal,
          mutationFailed: true,
        ),
      );
      return;
    }
    final original = state.meal!;
    ++_generation;
    emit(MealDetailState(MealDetailStatus.saving, meal: original));
    try {
      await repository.saveMealEntry(uid, replacement);
      if (isClosed) return;
      if (!_active) {
        emit(const MealDetailState(MealDetailStatus.expired));
        return;
      }
      emit(MealDetailState(MealDetailStatus.saved, meal: replacement));
    } catch (_) {
      if (isClosed) return;
      if (!_active) {
        emit(const MealDetailState(MealDetailStatus.expired));
        return;
      }
      emit(
        MealDetailState(
          MealDetailStatus.ready,
          meal: original,
          mutationFailed: true,
        ),
      );
    }
  }

  Future<void> delete() async {
    if (!_active) {
      if (!isClosed) emit(const MealDetailState(MealDetailStatus.expired));
      return;
    }
    if (state.busy ||
        state.meal == null ||
        (state.status == MealDetailStatus.deleted ||
            state.status == MealDetailStatus.saved)) {
      return;
    }
    final original = state.meal!;
    ++_generation;
    emit(MealDetailState(MealDetailStatus.deleting, meal: original));
    try {
      await repository.deleteMealEntry(uid, mealId);
      if (isClosed) return;
      if (!_active) {
        emit(const MealDetailState(MealDetailStatus.expired));
        return;
      }
      emit(const MealDetailState(MealDetailStatus.deleted));
    } catch (_) {
      if (isClosed) return;
      if (!_active) {
        emit(const MealDetailState(MealDetailStatus.expired));
        return;
      }
      emit(
        MealDetailState(
          MealDetailStatus.ready,
          meal: original,
          mutationFailed: true,
        ),
      );
    }
  }
}
