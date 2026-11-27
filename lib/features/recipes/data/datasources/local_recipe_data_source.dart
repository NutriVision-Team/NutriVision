import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One ingredient line of a local recipe. [measure] preserves the provider's
/// original quantity text (for example "1 cup"); [normalizedQuantityGrams]
/// stays null because the source offers no reliable gram conversion.
class LocalRecipeIngredient {
  const LocalRecipeIngredient({
    required this.name,
    this.measure,
    this.normalizedQuantityGrams,
  });

  factory LocalRecipeIngredient.fromJson(Map<String, dynamic> json) =>
      LocalRecipeIngredient(
        name: json['name'] as String? ?? '',
        measure: json['measure'] as String?,
        normalizedQuantityGrams: (json['normalizedQuantityGrams'] as num?)
            ?.toDouble(),
      );

  final String name;
  final String? measure;
  final double? normalizedQuantityGrams;
}

/// Source provenance for a local recipe record.
class LocalRecipeSource {
  const LocalRecipeSource({
    required this.provider,
    required this.mealId,
    required this.licenseNote,
    required this.url,
  });

  factory LocalRecipeSource.fromJson(Map<String, dynamic> json) =>
      LocalRecipeSource(
        provider: json['provider'] as String? ?? '',
        mealId: json['mealId'] as String? ?? '',
        licenseNote: json['licenseNote'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );

  final String provider;
  final String mealId;
  final String licenseNote;
  final String url;
}

/// Immutable local recipe record parsed from assets/data/recipes.json.
///
/// Recipes carry original measures and instructions as published by the
/// provider. [nutritionStatus] is always `not_calculable_from_source` for the
/// current catalog: exact recipe calories are never invented.
class LocalRecipeRecord {
  const LocalRecipeRecord({
    required this.id,
    required this.sourceMealId,
    required this.nameAr,
    required this.nameEn,
    this.description,
    this.category,
    this.area,
    required this.tags,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
    this.sourceUrl,
    this.youtubeUrl,
    required this.nutritionStatus,
    required this.source,
    this.mealTypes = const [],
    this.caloriesPerServing,
    this.cookingMinutes,
    this.cookingTimeBasis,
    this.timingSourceUrl,
  });

  factory LocalRecipeRecord.fromJson(Map<String, dynamic> json) {
    final names =
        (json['names'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return LocalRecipeRecord(
      id: json['id'] as String? ?? '',
      sourceMealId: json['sourceMealId'] as String? ?? '',
      nameAr: names['ar'] as String?,
      nameEn: names['en'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
      area: json['area'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? const []),
      ingredients: (json['ingredients'] as List? ?? const [])
          .map(
            (entry) => LocalRecipeIngredient.fromJson(
              (entry as Map).cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
      instructions: List<String>.from(
        json['instructions'] as List? ?? const [],
      ),
      imageUrl: json['imageUrl'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      youtubeUrl: json['youtubeUrl'] as String?,
      nutritionStatus: json['nutritionStatus'] as String? ?? '',
      mealTypes: List<String>.from(json['mealTypes'] as List? ?? const []),
      caloriesPerServing: (json['caloriesPerServing'] as num?)?.toDouble(),
      cookingMinutes: (json['cookingMinutes'] as num?)?.toDouble(),
      cookingTimeBasis: json['cookingTimeBasis'] as String?,
      timingSourceUrl: json['timingSourceUrl'] as String?,
      source: LocalRecipeSource.fromJson(
        (json['source'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }

  final String id;

  /// Optional verified source values, never inferred from a recipe name.
  final List<String> mealTypes;
  final double? caloriesPerServing, cookingMinutes;
  final String? cookingTimeBasis, timingSourceUrl;

  /// The provider's original meal ID.
  final String sourceMealId;

  /// Arabic name, or null when no reliable translation exists.
  final String? nameAr;
  final String nameEn;
  final String? description;
  final String? category;
  final String? area;
  final List<String> tags;
  final List<LocalRecipeIngredient> ingredients;
  final List<String> instructions;
  final String? imageUrl;
  final String? sourceUrl;
  final String? youtubeUrl;
  final String nutritionStatus;
  final LocalRecipeSource source;

  bool matches(String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      return false;
    }
    if (nameEn.toLowerCase().contains(normalizedQuery)) {
      return true;
    }
    final arabic = nameAr;
    if (arabic != null && arabic.contains(normalizedQuery)) {
      return true;
    }
    return false;
  }
}

/// Loads and caches the bundled recipe catalog. The JSON is read from the
/// asset bundle once and kept in memory; widgets must not re-read it per
/// build.
class LocalRecipeDataSource {
  LocalRecipeDataSource({this.assetPath = 'assets/data/recipes.json'});

  final String assetPath;

  List<LocalRecipeRecord>? _cache;

  bool get isLoaded => _cache != null;

  List<LocalRecipeRecord> get cachedRecords =>
      List.unmodifiable(_cache ?? const <LocalRecipeRecord>[]);

  Future<List<LocalRecipeRecord>> _ensureLoaded() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }
    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    if (decoded['schemaVersion'] != '1.0.0' || decoded['recipes'] is! List) {
      throw const FormatException('Unsupported local catalog schema');
    }
    final recipes = (decoded['recipes'] as List? ?? const [])
        .map(
          (entry) => LocalRecipeRecord.fromJson(
            (entry as Map).cast<String, dynamic>(),
          ),
        )
        .toList(growable: false);
    _cache = List.unmodifiable(recipes);
    return _cache!;
  }

  /// Loads (once) and returns every recipe.
  Future<List<LocalRecipeRecord>> getAll() => _ensureLoaded();

  /// Case-insensitive search over English and (when present) Arabic names.
  Future<List<LocalRecipeRecord>> search(String query) async {
    final recipes = await _ensureLoaded();
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const <LocalRecipeRecord>[];
    }
    return recipes.where((recipe) => recipe.matches(normalized)).toList();
  }

  /// Filters by cuisine/area label as returned by the provider
  /// (for example "Egyptian").
  Future<List<LocalRecipeRecord>> byArea(String area) async {
    final recipes = await _ensureLoaded();
    return recipes.where((recipe) => recipe.area == area).toList();
  }

  /// Filters by the provider's meal category (for example "Lamb").
  Future<List<LocalRecipeRecord>> byCategory(String category) async {
    final recipes = await _ensureLoaded();
    return recipes.where((recipe) => recipe.category == category).toList();
  }

  Future<LocalRecipeRecord?> getById(String id) async {
    final recipes = await _ensureLoaded();
    for (final recipe in recipes) {
      if (recipe.id == id) {
        return recipe;
      }
    }
    return null;
  }

  void clearCache() {
    _cache = null;
  }
}
