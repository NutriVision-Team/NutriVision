import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Source provenance for a local food record.
class LocalFoodSource {
  const LocalFoodSource({
    required this.provider,
    required this.dataset,
    required this.fdcId,
    required this.sourceVersion,
    required this.url,
  });

  factory LocalFoodSource.fromJson(Map<String, dynamic> json) =>
      LocalFoodSource(
        provider: json['provider'] as String? ?? '',
        dataset: json['dataset'] as String? ?? '',
        fdcId: json['fdcId'] as int? ?? 0,
        sourceVersion: json['sourceVersion'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );

  final String provider;
  final String dataset;
  final int fdcId;
  final String sourceVersion;
  final String url;
}

/// Nutrients per 100 g. Every value is nullable: null means the source does
/// not report the nutrient. Unknowns are never coerced to zero.
class LocalFoodNutrients {
  const LocalFoodNutrients({
    this.energyKcal,
    this.proteinG,
    this.fatG,
    this.carbohydrateG,
    this.fiberG,
    this.sugarsG,
    this.sodiumMg,
  });

  factory LocalFoodNutrients.fromJson(Map<String, dynamic> json) =>
      LocalFoodNutrients(
        energyKcal: (json['energyKcal'] as num?)?.toDouble(),
        proteinG: (json['proteinG'] as num?)?.toDouble(),
        fatG: (json['fatG'] as num?)?.toDouble(),
        carbohydrateG: (json['carbohydrateG'] as num?)?.toDouble(),
        fiberG: (json['fiberG'] as num?)?.toDouble(),
        sugarsG: (json['sugarsG'] as num?)?.toDouble(),
        sodiumMg: (json['sodiumMg'] as num?)?.toDouble(),
      );

  final double? energyKcal;
  final double? proteinG;
  final double? fatG;
  final double? carbohydrateG;
  final double? fiberG;
  final double? sugarsG;
  final double? sodiumMg;

  bool get isEmpty =>
      energyKcal == null &&
      proteinG == null &&
      fatG == null &&
      carbohydrateG == null &&
      fiberG == null &&
      sugarsG == null &&
      sodiumMg == null;
}

/// Immutable local food catalog record parsed from assets/data/foods.json.
class LocalFoodRecord {
  const LocalFoodRecord({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.aliases,
    required this.category,
    required this.foodState,
    required this.referenceAmountGrams,
    required this.nutrientsPer100g,
    required this.dataQuality,
    required this.source,
  });

  factory LocalFoodRecord.fromJson(Map<String, dynamic> json) {
    final names =
        (json['names'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return LocalFoodRecord(
      id: json['id'] as String? ?? '',
      nameAr: names['ar'] as String? ?? '',
      nameEn: names['en'] as String? ?? '',
      aliases: List<String>.from(json['aliases'] as List? ?? const []),
      category: json['category'] as String? ?? '',
      foodState: json['foodState'] as String? ?? '',
      referenceAmountGrams:
          (json['referenceAmountGrams'] as num?)?.toDouble() ?? 100,
      nutrientsPer100g: LocalFoodNutrients.fromJson(
        (json['nutrientsPer100g'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      dataQuality: json['dataQuality'] as String? ?? '',
      source: LocalFoodSource.fromJson(
        (json['source'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }

  final String id;
  final String nameAr;
  final String nameEn;
  final List<String> aliases;
  final String category;
  final String foodState;
  final double referenceAmountGrams;
  final LocalFoodNutrients nutrientsPer100g;
  final String dataQuality;
  final LocalFoodSource source;

  bool matches(String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      return false;
    }
    if (nameAr.contains(normalizedQuery)) {
      return true;
    }
    if (nameEn.toLowerCase().contains(normalizedQuery)) {
      return true;
    }
    return aliases.any(
      (alias) => alias.toLowerCase().contains(normalizedQuery),
    );
  }
}

/// Loads and caches the bundled food catalog. The JSON is read from the asset
/// bundle once and kept in memory; widgets must not re-read it per build.
class LocalFoodDataSource {
  LocalFoodDataSource({this.assetPath = 'assets/data/foods.json'});

  final String assetPath;

  List<LocalFoodRecord>? _cache;

  bool get isLoaded => _cache != null;

  List<LocalFoodRecord> get cachedRecords =>
      List.unmodifiable(_cache ?? const <LocalFoodRecord>[]);

  Future<List<LocalFoodRecord>> _ensureLoaded() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }
    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    if (decoded['schemaVersion'] != '1.0.0' || decoded['foods'] is! List) {
      throw const FormatException('Unsupported local catalog schema');
    }
    final foods = (decoded['foods'] as List? ?? const [])
        .map(
          (entry) =>
              LocalFoodRecord.fromJson((entry as Map).cast<String, dynamic>()),
        )
        .toList(growable: false);
    _cache = List.unmodifiable(foods);
    return _cache!;
  }

  /// Loads (once) and returns every catalog record.
  Future<List<LocalFoodRecord>> getAll() => _ensureLoaded();

  /// Case-insensitive search over Arabic name, English name and aliases.
  Future<List<LocalFoodRecord>> search(String query) async {
    final foods = await _ensureLoaded();
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const <LocalFoodRecord>[];
    }
    return foods.where((food) => food.matches(normalized)).toList();
  }

  Future<List<LocalFoodRecord>> byCategory(String category) async {
    final foods = await _ensureLoaded();
    return foods.where((food) => food.category == category).toList();
  }

  Future<LocalFoodRecord?> getById(String id) async {
    final foods = await _ensureLoaded();
    for (final food in foods) {
      if (food.id == id) {
        return food;
      }
    }
    return null;
  }

  void clearCache() {
    _cache = null;
  }
}
