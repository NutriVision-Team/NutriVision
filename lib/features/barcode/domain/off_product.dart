import '../../../core/utils/nutrition_values.dart';
import 'barcode_code.dart';
import '../../../data/models/food_catalog_model.dart';
import '../../meal_log/domain/food_portion.dart';

/// What the nutrient numbers are "per".
enum NutrientBasis {
  /// Open Food Facts `_100g` values for a solid/semi-solid product.
  per100g,

  /// A liquid signal (ml/cl/l) was found. The same numbers are per 100 ml and
  /// must never be multiplied by grams.
  per100ml,

  /// The source does not establish a safe mass or volume basis.
  unknown,
}

const offSourceName = 'Open Food Facts';

/// Minimal, parsed view of one Open Food Facts product. Every nutrient is
/// nullable: absent means unknown, never zero.
class OffProduct {
  const OffProduct({
    required this.barcode,
    required this.name,
    this.sourceUrl,
    this.brand,
    this.imageUrl,
    this.quantityText,
    this.servingText,
    this.servingGrams,
    this.basis = NutrientBasis.per100g,
    this.energyKcal,
    this.proteinG,
    this.carbohydrateG,
    this.fatG,
    this.fiberG,
    this.sugarsG,
    this.sodiumMg,
    this.ingredientsText,
    this.allergenTags,
    this.nutriScore,
  });

  final String barcode;
  final String? sourceUrl;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? quantityText;
  final String? servingText;

  /// Only set when the serving is declared in grams.
  final double? servingGrams;
  final NutrientBasis basis;
  final double? energyKcal;
  final double? proteinG;
  final double? carbohydrateG;
  final double? fatG;
  final double? fiberG;
  final double? sugarsG;
  final double? sodiumMg;
  final String? ingredientsText;

  /// Raw taxonomy tags such as `en:milk`. null = field absent; [] = empty.
  final List<String>? allergenTags;

  /// 'a'..'e' only when the source supplied a valid grade.
  final String? nutriScore;

  /// Fields requested from the API. Keep minimal (brief: required fields only).
  static const requestedFields =
      'code,url,product_name,product_name_ar,product_name_en,brands,'
      'image_front_small_url,quantity,product_quantity_unit,serving_size,'
      'serving_quantity,serving_quantity_unit,nutriments,ingredients_text,'
      'allergens_tags,nutriscore_grade,nutrition_data_per';

  bool get hasAnyNutrient => [
    energyKcal,
    proteinG,
    carbohydrateG,
    fatG,
    fiberG,
    sugarsG,
    sodiumMg,
  ].any((v) => v != null);

  /// Logging needs a gram basis and a measured energy value.
  bool get canLog =>
      basis == NutrientBasis.per100g &&
      knownNutrient(energyKcal) != null &&
      name.trim().isNotEmpty;

  static final _liquidWithNumber = RegExp(
    r'\d\s*(ml|cl|dl|l|fl\.?\s*oz)(\b|$)',
    caseSensitive: false,
  );
  static final _bareLiquidUnit = RegExp(
    r'^(ml|cl|dl|l|litre|liter|litres|liters)$',
    caseSensitive: false,
  );

  /// True for text such as "ml", "33 cl", "1.5 L". Mass units are never liquid.
  static bool _looksLiquid(String? text) {
    final t = text?.trim();
    if (t == null || t.isEmpty) return false;
    return _bareLiquidUnit.hasMatch(t) || _liquidWithNumber.hasMatch(t);
  }

  /// Returns null when [json] holds no usable product.
  static OffProduct? fromV3(
    String requestedCode,
    Map<String, dynamic> json, {
    String? responseUrl,
  }) {
    final raw = json['product'];
    if (json['status'] != 'success' || raw is! Map) return null;
    final p = Map<String, dynamic>.from(raw);
    final requested = BarcodeCode.tryParse(requestedCode);
    final returned = p['code'] is String
        ? BarcodeCode.tryParse(p['code'] as String)
        : null;
    if (requested == null ||
        returned == null ||
        requested.canonical != returned.canonical) {
      return null;
    }
    String? text(Object? v) {
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    final name =
        text(p['product_name_ar']) ??
        text(p['product_name']) ??
        text(p['product_name_en']);
    if (name == null) return null;

    final n = p['nutriments'] is Map
        ? Map<String, dynamic>.from(p['nutriments'] as Map)
        : <String, dynamic>{};
    double? per100(String key) => knownNutrient(n['${key}_100g']);

    final quantity = text(p['quantity']);
    final servingText = text(p['serving_size']);
    final liquid =
        _looksLiquid(text(p['product_quantity_unit'])) ||
        _looksLiquid(quantity) ||
        _looksLiquid(servingText) ||
        _looksLiquid(text(p['serving_quantity_unit']));

    bool massUnit(String? value) {
      if (value == null) return false;
      final t = value.toLowerCase().trim();
      return const {'g', 'kg', 'gram', 'grams', 'جم', 'كجم'}.contains(t) ||
          RegExp(
            r'[0-9٠-٩۰-۹]\s*(g|kg|grams?|جم|كجم)(\s|$)',
            caseSensitive: false,
          ).hasMatch(t);
    }

    final mass =
        massUnit(text(p['product_quantity_unit'])) ||
        massUnit(quantity) ||
        massUnit(servingText) ||
        massUnit(text(p['serving_quantity_unit']));
    final declared = text(
      p['nutrition_data_per'],
    )?.toLowerCase().replaceAll(' ', '');
    final explicitVolume = declared == '100ml';
    final invalidDeclaration =
        declared != null &&
        !const {'100g', '100ml', 'serving'}.contains(declared);
    final basis = invalidDeclaration
        ? NutrientBasis.unknown
        : explicitVolume
        ? NutrientBasis.per100ml
        : liquid && mass
        ? NutrientBasis.unknown
        : liquid
        ? NutrientBasis.per100ml
        : mass
        ? NutrientBasis.per100g
        : NutrientBasis.unknown;
    String? safeUrl(String? value) {
      final uri = value == null ? null : Uri.tryParse(value);
      if (uri == null ||
          uri.scheme != 'https' ||
          !(uri.host == 'openfoodfacts.org' ||
              uri.host.endsWith('.openfoodfacts.org'))) {
        return null;
      }
      return value;
    }

    double? servingGrams;
    final sq = p['serving_quantity'];
    final sqNum = sq is num ? sq.toDouble() : double.tryParse('${sq ?? ''}');
    final servingUnit = text(p['serving_quantity_unit'])?.toLowerCase();
    final servingTextLooksGrams =
        servingText != null &&
        RegExp(
          r'^\s*\d+([.,]\d+)?\s*g\b',
          caseSensitive: false,
        ).hasMatch(servingText);
    if (basis == NutrientBasis.per100g &&
        sqNum != null &&
        sqNum.isFinite &&
        sqNum > 0 &&
        sqNum <= 10000 &&
        (servingUnit == 'g' ||
            (servingUnit == null && servingTextLooksGrams))) {
      servingGrams = sqNum;
    }

    final sodiumG = per100('sodium');
    final grade = text(p['nutriscore_grade'])?.toLowerCase();
    final tags = p['allergens_tags'];
    final img = text(p['image_front_small_url']);
    return OffProduct(
      barcode: returned.value,
      sourceUrl: safeUrl(text(p['url'])) ?? safeUrl(responseUrl),
      name: name,
      brand: text(p['brands']),
      imageUrl: safeUrl(img),
      quantityText: quantity,
      servingText: servingText,
      servingGrams: servingGrams,
      basis: basis,
      energyKcal: per100('energy-kcal'),
      proteinG: per100('proteins'),
      carbohydrateG: per100('carbohydrates'),
      fatG: per100('fat'),
      fiberG: per100('fiber'),
      sugarsG: per100('sugars'),
      sodiumMg: sodiumG == null ? null : knownNutrient(sodiumG * 1000),
      ingredientsText: text(p['ingredients_text']),
      allergenTags: tags is List
          ? [
              for (final t in tags)
                if (t is String && t.isNotEmpty) t,
            ]
          : null,
      nutriScore: grade != null && RegExp(r'^[a-e]$').hasMatch(grade)
          ? grade
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'sourceUrl': sourceUrl,
    'name': name,
    'brand': brand,
    'imageUrl': imageUrl,
    'quantityText': quantityText,
    'servingText': servingText,
    'servingGrams': servingGrams,
    'basis': basis.name,
    'energyKcal': energyKcal,
    'proteinG': proteinG,
    'carbohydrateG': carbohydrateG,
    'fatG': fatG,
    'fiberG': fiberG,
    'sugarsG': sugarsG,
    'sodiumMg': sodiumMg,
    'ingredientsText': ingredientsText,
    'allergenTags': allergenTags,
    'nutriScore': nutriScore,
  };

  static OffProduct? fromJson(Map<String, dynamic> j) {
    final code = j['barcode'];
    final name = j['name'];
    if (code is! String || name is! String || name.isEmpty) return null;
    double? d(String k) => knownNutrient(j[k]);
    return OffProduct(
      barcode: code,
      sourceUrl: j['sourceUrl'] as String?,
      name: name,
      brand: j['brand'] as String?,
      imageUrl: j['imageUrl'] as String?,
      quantityText: j['quantityText'] as String?,
      servingText: j['servingText'] as String?,
      servingGrams: d('servingGrams'),
      basis: switch (j['basis']) {
        'per100g' => NutrientBasis.per100g,
        'per100ml' => NutrientBasis.per100ml,
        _ => NutrientBasis.unknown,
      },
      energyKcal: d('energyKcal'),
      proteinG: d('proteinG'),
      carbohydrateG: d('carbohydrateG'),
      fatG: d('fatG'),
      fiberG: d('fiberG'),
      sugarsG: d('sugarsG'),
      sodiumMg: d('sodiumMg'),
      ingredientsText: j['ingredientsText'] as String?,
      allergenTags: (j['allergenTags'] as List?)?.whereType<String>().toList(),
      nutriScore: j['nutriScore'] as String?,
    );
  }

  /// Catalog record for the shared review screen. Null unless the nutrients
  /// are per 100 g. Provenance is preserved: source, source id, URL and an
  /// explicit unverified status (Open Food Facts is crowd-sourced).
  FoodCatalogModel? toCatalogFood() {
    if (basis != NutrientBasis.per100g) return null;
    return FoodCatalogModel(
      foodId: 'off_$barcode',
      name: brand == null ? name : '$name ($brand)',
      category: 'packaged_product',
      foodState: 'packaged',
      source: offSourceName,
      sourceId: barcode,
      sourceUrl: sourceUrl,
      verificationStatus: 'crowdsourced_unverified',
      nutritionPer100g: {
        'calories': energyKcal,
        'protein': proteinG,
        'carbohydrates': carbohydrateG,
        'fat': fatG,
        'fiber': fiberG,
        'sugar': sugarsG,
        'sodium': sodiumMg,
      },
      servingSizes: servingGrams == null ? null : {'serving': servingGrams},
    );
  }

  /// A portion in grams, or null when logging is not allowed.
  FoodPortion? portion(double grams) {
    final food = toCatalogFood();
    if (food == null || !canLog) return null;
    if (!grams.isFinite || grams <= 0 || grams > 10000) return null;
    return FoodPortion(food, grams);
  }
}
