import 'dart:convert';
import 'package:flutter/services.dart';
import '../../food_catalog/data/datasources/local_food_data_source.dart';

class FoodAlternative {
  const FoodAlternative({
    required this.id,
    required this.original,
    required this.alternative,
    required this.reasonAr,
    required this.reasonEn,
    required this.comparisons,
  });
  final String id;
  final LocalFoodRecord original;
  final LocalFoodRecord alternative;
  final String reasonAr;
  final String reasonEn;

  /// Source and alternative values are per 100 g, never per serving.
  final Map<String, ({double? source, double? alternative})> comparisons;
}

class AlternativesRepository {
  AlternativesRepository({LocalFoodDataSource? foods, AssetBundle? bundle})
    : _foods = foods ?? LocalFoodDataSource(),
      _bundle = bundle ?? rootBundle;
  final LocalFoodDataSource _foods;
  final AssetBundle _bundle;
  Future<List<FoodAlternative>>? _pending;
  Future<List<FoodAlternative>> getAll() =>
      _pending ??= _load().catchError((Object e) {
        _pending = null;
        throw e;
      });
  Future<List<FoodAlternative>> _load() async {
    final data =
        jsonDecode(await _bundle.loadString('assets/data/alternatives.json'))
            as Map<String, dynamic>;
    if (data['schemaVersion'] != '1.0.0') {
      throw const FormatException('Unknown alternatives schema');
    }
    final result = <FoodAlternative>[];
    for (final row in data['alternatives'] as List) {
      final r = row as Map<String, dynamic>;
      final original = await _foods.getById(r['sourceFoodId'] as String);
      final alternative = await _foods.getById(
        r['alternativeFoodId'] as String,
      );
      if (original == null || alternative == null) {
        throw const FormatException('Unresolved alternative source');
      }
      final comparisons = <String, ({double? source, double? alternative})>{};
      for (final entry
          in (r['nutrientComparisonPer100g'] as Map<String, dynamic>).entries) {
        final values = entry.value as Map<String, dynamic>;
        comparisons[entry.key] = (
          source: (values['source'] as num?)?.toDouble(),
          alternative: (values['alternative'] as num?)?.toDouble(),
        );
      }
      final reason = r['reason'] as Map<String, dynamic>;
      result.add(
        FoodAlternative(
          id: r['id'] as String,
          original: original,
          alternative: alternative,
          reasonAr: reason['ar'] as String,
          reasonEn: reason['en'] as String,
          comparisons: Map.unmodifiable(comparisons),
        ),
      );
    }
    return List.unmodifiable(result);
  }

  static List<FoodAlternative> filter(
    List<FoodAlternative> records,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return records;
    return records
        .where(
          (r) => [
            r.original.nameAr,
            r.original.nameEn,
          ].any((s) => s.toLowerCase().contains(q)),
        )
        .toList(growable: false);
  }
}
