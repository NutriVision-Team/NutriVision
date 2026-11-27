import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/favorite_model.dart';
import '../../../../data/models/meal_entry_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../data/favorites_repository.dart';
import '../../domain/favorites_logic.dart';

enum FavoritesStatus { loading, ready, failure, expired }

/// One-shot outcome of the last user action, consumed by the screen.
enum FavoritesNotice {
  none,
  removed,
  removeFailed,
  added,
  addFailed,
  favoriteSaved,
  favoriteSaveFailed,
}

class FavoritesState {
  const FavoritesState({
    this.status = FavoritesStatus.loading,
    this.tab = FavoritesTab.meals,
    this.sort = FavoritesSort.recent,
    this.meals = const [],
    this.recipes = const [],
    this.frequent = const [],
    this.foods = const [],
    this.hero,
    this.busyIds = const {},
    this.notice = FavoritesNotice.none,
    this.noticeSeq = 0,
  });
  final FavoritesStatus status;
  final FavoritesTab tab;
  final FavoritesSort sort;
  final List<FavoriteMealView> meals;
  final List<FavoriteModel> recipes;
  final List<FrequentFood> frequent;
  final List<FavoriteModel> foods;
  final ({String title, int count})? hero;
  final Set<String> busyIds;
  final FavoritesNotice notice;
  final int noticeSeq;

  FavoritesState copyWith({
    FavoritesStatus? status,
    FavoritesTab? tab,
    FavoritesSort? sort,
    List<FavoriteMealView>? meals,
    List<FavoriteModel>? recipes,
    List<FrequentFood>? frequent,
    List<FavoriteModel>? foods,
    ({String title, int count})? hero,
    bool clearHero = false,
    Set<String>? busyIds,
    FavoritesNotice? notice,
  }) => FavoritesState(
    status: status ?? this.status,
    tab: tab ?? this.tab,
    sort: sort ?? this.sort,
    meals: meals ?? this.meals,
    recipes: recipes ?? this.recipes,
    frequent: frequent ?? this.frequent,
    foods: foods ?? this.foods,
    hero: clearHero ? null : (hero ?? this.hero),
    busyIds: busyIds ?? this.busyIds,
    notice: notice ?? FavoritesNotice.none,
    noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
  );
}

/// Bound to one signed-in uid. Every await re-checks the active account so a
/// result for a previous account can never reach this account's screen.
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({
    required this.uid,
    required this.currentUid,
    required this.backend,
    required this.nutrition,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const FavoritesState());

  final String uid;
  final String? Function() currentUid;
  final FavoritesBackend backend;
  final NutritionRepository nutrition;
  final DateTime Function() _clock;
  final Map<String, MealEntryModel> _pendingCopies = {};
  int _version = 0;

  bool get _active => !isClosed && uid.isNotEmpty && currentUid() == uid;

  void setTab(FavoritesTab tab) => emit(state.copyWith(tab: tab));
  void setSort(FavoritesSort sort) =>
      emit(state.copyWith(sort: sort, meals: sortMeals(state.meals, sort)));

  Future<void> load() async {
    if (!_active) return;
    final v = ++_version;
    emit(state.copyWith(status: FavoritesStatus.loading));
    try {
      final results = await Future.wait([
        backend.loadAll(uid),
        nutrition.getMealEntries(uid),
      ]);
      if (!_active || v != _version) {
        if (!isClosed && currentUid() != uid) {
          emit(state.copyWith(status: FavoritesStatus.expired));
        }
        return;
      }
      final favorites = (results[0] as List<FavoriteModel>);
      final meals = (results[1] as List<MealEntryModel>)
          .where((m) => m.userId == uid)
          .toList(growable: false);
      final byId = {for (final m in meals) m.mealId: m};
      final now = _clock();
      emit(
        state.copyWith(
          status: FavoritesStatus.ready,
          meals: sortMeals([
            for (final f in favorites.where(
              (f) => f.targetType == favoriteTypeMeal,
            ))
              FavoriteMealView(f, byId[f.targetId]),
          ], state.sort),
          recipes: [
            for (final f in favorites.where(
              (f) => f.targetType == favoriteTypeRecipe,
            ))
              f,
          ]..sort((a, b) => a.title.compareTo(b.title)),
          foods: favorites.where((f) => f.targetType == 'food').toList(),
          frequent: frequentFoods(meals, uid: uid, now: now),
          hero: mostLoggedMeal(meals, uid: uid, now: now),
          clearHero: mostLoggedMeal(meals, uid: uid, now: now) == null,
          busyIds: const {},
        ),
      );
    } catch (_) {
      if (_active && v == _version) {
        emit(state.copyWith(status: FavoritesStatus.failure));
      }
    }
  }

  Future<void> remove(FavoriteModel favorite) async {
    if (!_active || state.busyIds.contains(favorite.favoriteId)) return;
    final type = favorite.targetType;
    if (type != favoriteTypeMeal &&
        type != favoriteTypeRecipe &&
        type != 'food') {
      return;
    }
    emit(state.copyWith(busyIds: {...state.busyIds, favorite.favoriteId}));
    try {
      await backend.remove(uid, favorite.favoriteId, expectedType: type);
      if (!_active) return;
      emit(
        state.copyWith(
          meals: [
            for (final m in state.meals)
              if (m.favorite.favoriteId != favorite.favoriteId) m,
          ],
          recipes: [
            for (final r in state.recipes)
              if (r.favoriteId != favorite.favoriteId) r,
          ],
          foods: state.foods
              .where((f) => f.favoriteId != favorite.favoriteId)
              .toList(),
          busyIds: {...state.busyIds}..remove(favorite.favoriteId),
          notice: FavoritesNotice.removed,
        ),
      );
    } catch (_) {
      if (_active) {
        emit(
          state.copyWith(
            busyIds: {...state.busyIds}..remove(favorite.favoriteId),
            notice: FavoritesNotice.removeFailed,
          ),
        );
      }
    }
  }

  /// Add the saved meal to today's diary. Retry after a failure reuses the
  /// same document id, so a lost acknowledgement cannot double-log.
  Future<void> addToDiary(FavoriteMealView view, String mealType) async {
    final meal = view.meal;
    final key = view.favorite.favoriteId;
    if (!_active ||
        meal == null ||
        meal.userId != uid ||
        state.busyIds.contains(key)) {
      return;
    }
    emit(state.copyWith(busyIds: {...state.busyIds, key}));
    final now = _clock();
    try {
      final copy = _pendingCopies.putIfAbsent(
        key,
        () => mealCopyForDiary(
          meal,
          uid: uid,
          id: 'fav-${now.microsecondsSinceEpoch}',
          at: now,
          mealType: mealType,
        ),
      );
      await nutrition.saveMealEntry(uid, copy);
      if (!_active) return;
      _pendingCopies.remove(key);
      emit(
        state.copyWith(
          busyIds: {...state.busyIds}..remove(key),
          notice: FavoritesNotice.added,
        ),
      );
    } catch (_) {
      if (_active) {
        emit(
          state.copyWith(
            busyIds: {...state.busyIds}..remove(key),
            notice: FavoritesNotice.addFailed,
          ),
        );
      }
    }
  }

  /// Save a logged meal as a favorite meal (called from diary/meal detail).
  Future<void> favoriteMeal(MealEntryModel meal) async {
    if (!_active || meal.userId != uid || meal.title.trim().isEmpty) return;
    try {
      await backend.saveIfAbsent(
        uid,
        FavoriteModel(
          favoriteId: mealFavoriteId(meal.mealId),
          targetId: meal.mealId,
          targetType: favoriteTypeMeal,
          title: meal.title.trim(),
          imageUrl: meal.imageUrl,
        ),
      );
      if (_active) {
        emit(state.copyWith(notice: FavoritesNotice.favoriteSaved));
        await load();
      }
    } catch (_) {
      if (_active) {
        emit(state.copyWith(notice: FavoritesNotice.favoriteSaveFailed));
      }
    }
  }
}
