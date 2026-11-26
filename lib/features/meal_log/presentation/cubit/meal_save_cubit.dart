import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/meal_entry_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../domain/food_portion.dart';
import '../../domain/catalog_meal_draft.dart';

enum MealSaveStatus { ready, saving, saved, failure, expired }

class MealSaveCubit extends Cubit<MealSaveStatus> {
  MealSaveCubit({
    FoodPortion? portion,
    CatalogMealDraft? draft,
    this.title,
    this.notes,
    this.inputMethod = 'catalog',
    required this.repository,
    required this.uid,
    required this.currentUid,
    required this.mealType,
    DateTime Function()? clock,
  }) : assert((portion == null) != (draft == null)),
       _draft = draft ?? CatalogMealDraft([portion!]),
       _clock = clock ?? DateTime.now,
       super(MealSaveStatus.ready);
  final CatalogMealDraft _draft;
  final String? title, notes;
  final String inputMethod;
  final NutritionRepository repository;
  final String uid;
  final String? Function() currentUid;
  final String mealType;
  final DateTime Function() _clock;
  MealEntryModel? _pending;

  Future<void> save() async {
    if (isClosed ||
        state == MealSaveStatus.saving ||
        state == MealSaveStatus.saved) {
      return;
    }
    if (uid.isEmpty || currentUid() != uid) {
      emit(MealSaveStatus.expired);
      return;
    }
    if (!_draft.canSave) {
      emit(MealSaveStatus.failure);
      return;
    }
    final now = _clock();
    emit(MealSaveStatus.saving);
    try {
      _pending ??= _draft.toMeal(
        uid: uid,
        id: 'catalog-${now.microsecondsSinceEpoch}',
        at: now,
        mealType: mealType,
        title: title,
        notes: notes,
        inputMethod: inputMethod,
      );
      await repository.saveMealEntry(uid, _pending!);
      if (isClosed) return;
      emit(currentUid() == uid ? MealSaveStatus.saved : MealSaveStatus.expired);
    } catch (_) {
      if (!isClosed) {
        emit(
          currentUid() == uid ? MealSaveStatus.failure : MealSaveStatus.expired,
        );
      }
    }
  }
}
