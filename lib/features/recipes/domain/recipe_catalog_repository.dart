import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/local_recipe_data_source.dart';

/// AI is an explicit optional capability. No local algorithm impersonates it.
abstract interface class RecipeSuggestionService {
  Future<List<String>> suggest(RecipeRequest request);
}

class RecipeRequest {
  const RecipeRequest({
    required this.mealType,
    required this.ingredients,
    this.requireMealType = false,
    this.maxCalories,
    this.maxCookingMinutes,
  });
  final String mealType;
  final bool requireMealType;
  final double? maxCalories, maxCookingMinutes;
  final List<String> ingredients;
}

class RecipeCatalogRepository {
  RecipeCatalogRepository({LocalRecipeDataSource? source})
    : _source = source ?? LocalRecipeDataSource();
  final LocalRecipeDataSource _source;

  /// Test-key records must never become production recipe content.
  bool get developmentRecipesAllowed => !kReleaseMode;
  Future<List<LocalRecipeRecord>> getAll() async {
    if (!developmentRecipesAllowed) throw const RecipeLicenseException();
    return _source.getAll();
  }

  Future<LocalRecipeRecord?> getById(String id) async {
    final records = await getAll();
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  /// Search is literal source text, not generated recipes or an AI response.
  static List<LocalRecipeRecord> filter(
    List<LocalRecipeRecord> records,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return records;
    return records
        .where(
          (r) => [
            r.nameAr ?? '',
            r.nameEn,
            ...r.ingredients.map((i) => i.name),
          ].any((text) => text.toLowerCase().contains(q)),
        )
        .toList(growable: false);
  }
}

class RecipeLicenseException implements Exception {
  const RecipeLicenseException();
}

/// Per-account favorite contract. Production integration uses CloudRecipeFavorites.
abstract class RecipeFavorites {
  factory RecipeFavorites({
    required SharedPreferences preferences,
    required String userId,
  }) = LocalRecipeFavorites;
  bool get isCloudBacked;
  Set<String> read();
  Future<void> load();
  Future<void> refresh();
  Future<void> setSaved(String recipeId, bool saved);
}

/// Optional local-only adapter for tests or explicitly offline-only use.
/// Production account integration must use CloudRecipeFavorites.
class LocalRecipeFavorites implements RecipeFavorites {
  LocalRecipeFavorites({
    required SharedPreferences preferences,
    required String userId,
  }) : _preferences = preferences,
       _key = 'sufra.recipeFavorites.v1.${Uri.encodeComponent(userId)}' {
    if (userId.trim().isEmpty) throw ArgumentError.value(userId, 'userId');
  }
  final SharedPreferences _preferences;
  final String _key;

  @override
  bool get isCloudBacked => false;
  @override
  Future<void> load() async {}
  @override
  Future<void> refresh() async {}
  @override
  Set<String> read() =>
      Set.unmodifiable(_preferences.getStringList(_key) ?? []);
  @override
  Future<void> setSaved(String recipeId, bool saved) async {
    final values = read().toSet();
    if (saved) {
      values.add(recipeId);
    } else {
      values.remove(recipeId);
    }
    final accepted = await _preferences.setStringList(
      _key,
      values.toList()..sort(),
    );
    if (!accepted) throw StateError('Could not save recipe favorite');
  }
}
