import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/food_catalog_model.dart';
import '../../../../data/repositories/food_repository.dart';

enum FoodSearchStatus { idle, loading, ready, failure }

class FoodSearchState {
  const FoodSearchState(this.status, {this.query = '', this.foods = const []});
  final FoodSearchStatus status;
  final String query;
  final List<FoodCatalogModel> foods;
}

/// Debounces typing and drops stale responses. Never caches a failed request
/// as an empty catalog and never performs a Firestore write from a search.
class FoodSearchCubit extends Cubit<FoodSearchState> {
  FoodSearchCubit(
    this.repository, {
    this.debounce = const Duration(milliseconds: 280),
  }) : super(const FoodSearchState(FoodSearchStatus.idle));

  final FoodRepository repository;
  final Duration debounce;
  Timer? _timer;
  String? _category;
  bool _egyptian = false;
  int _generation = 0;

  void search(String raw) {
    if (isClosed) return;
    _timer?.cancel();
    final generation = ++_generation;
    final query = raw.trim();
    if (query.isEmpty) {
      emit(const FoodSearchState(FoodSearchStatus.idle));
      return;
    }
    if (query.length > 120) {
      emit(FoodSearchState(FoodSearchStatus.failure, query: query));
      return;
    }
    emit(FoodSearchState(FoodSearchStatus.loading, query: query));
    _timer = Timer(debounce, () => _fetch(query, generation));
  }

  Future<void> _fetch(String query, int generation) async {
    try {
      final results = await repository.searchFood(query);
      final repo = repository;
      final allowed = _egyptian && repo is FoodCategoryBrowser
          ? (await (repo as FoodCategoryBrowser).browseFoods(
              egyptianStaples: true,
            )).map((f) => f.foodId).toSet()
          : null;
      final foods = results
          .where(
            (f) =>
                (_category == null || f.category == _category) &&
                (allowed == null || allowed.contains(f.foodId)),
          )
          .toList();
      if (isClosed || generation != _generation) return;
      emit(
        FoodSearchState(
          FoodSearchStatus.ready,
          query: query,
          foods: List.unmodifiable(foods),
        ),
      );
    } catch (_) {
      if (isClosed || generation != _generation) return;
      emit(FoodSearchState(FoodSearchStatus.failure, query: query));
    }
  }

  void filter({String? category, bool egyptian = false}) {
    _category = category;
    _egyptian = egyptian;
    final query = state.query;
    if (query.isEmpty) {
      browse(category: category, egyptian: egyptian);
    } else {
      search(query);
    }
  }

  Future<void> browse({String? category, bool egyptian = false}) async {
    _timer?.cancel();
    final generation = ++_generation;
    _category = category;
    _egyptian = egyptian;
    emit(const FoodSearchState(FoodSearchStatus.loading));
    try {
      final repo = repository;
      final foods = repo is FoodCategoryBrowser
          ? await (repo as FoodCategoryBrowser).browseFoods(
              category: category,
              egyptianStaples: egyptian,
            )
          : <FoodCatalogModel>[];
      if (isClosed || generation != _generation) return;
      emit(
        FoodSearchState(
          FoodSearchStatus.ready,
          foods: List.unmodifiable(foods),
        ),
      );
    } catch (_) {
      if (!isClosed && generation == _generation) {
        emit(const FoodSearchState(FoodSearchStatus.failure));
      }
    }
  }

  void retry() {
    if (state.query.isEmpty) {
      browse(category: _category, egyptian: _egyptian);
    } else {
      search(state.query);
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _generation++;
    return super.close();
  }
}
