import 'dart:convert';
import 'dart:typed_data';

/// Recognition proposes names only. No generated nutrition is accepted here.
class FoodRecognitionInput {
  const FoodRecognitionInput({
    required this.jpegBytes,
    required this.mealType,
    this.notes = '',
  });
  final Uint8List jpegBytes;
  final String mealType;
  final String notes;
}

class RecognitionCandidate {
  const RecognitionCandidate({
    required this.name,
    this.matchedFoodId,
    this.foodState,
    this.confidence,
    this.suggestedPortionGrams,
    this.uncertaintyNotes = const [],
  });
  final String name;
  final String? matchedFoodId;
  final String? foodState;
  final double? confidence;

  /// A suggestion, never a measurement or an accepted portion.
  final double? suggestedPortionGrams;
  final List<String> uncertaintyNotes;
}

class FoodRecognitionResult {
  const FoodRecognitionResult({
    required this.items,
    this.generalNotes = const [],
  });
  final List<RecognitionCandidate> items;
  final List<String> generalNotes;
  bool get requiresUserReview => true;

  factory FoodRecognitionResult.parse(
    String text, {
    required Set<String> catalogIds,
  }) {
    if (text.length > 65536) throw const FormatException('Response too large');
    final value = jsonDecode(text);
    if (value is! Map<String, dynamic> ||
        value['requiresUserReview'] != true ||
        value['items'] is! List) {
      throw const FormatException('Invalid recognition response');
    }
    final rawItems = value['items'] as List;
    if (rawItems.length > 20) {
      throw const FormatException('Too many candidates');
    }
    List<String> notes(dynamic raw) {
      if (raw == null) return const [];
      if (raw is! List ||
          raw.length > 20 ||
          raw.any((v) => v is! String || v.length > 500)) {
        throw const FormatException('Invalid uncertainty notes');
      }
      return List<String>.unmodifiable(raw.cast<String>());
    }

    double? number(dynamic value, double limit) {
      if (value == null) return null;
      if (value is! num || !value.isFinite || value < 0 || value > limit) {
        throw const FormatException('Invalid candidate number');
      }
      return value.toDouble();
    }

    return FoodRecognitionResult(
      items: List.unmodifiable(
        rawItems.map((raw) {
          if (raw is! Map<String, dynamic> ||
              raw['name'] is! String ||
              (raw['name'] as String).trim().isEmpty ||
              (raw['name'] as String).length > 160) {
            throw const FormatException('Invalid candidate name');
          }
          final id = raw['matchedFoodId'];
          if (id != null && id is! String) {
            throw const FormatException('Invalid food reference');
          }
          final state = raw['foodState'];
          if (state != null &&
              !const {
                'raw',
                'cooked',
                'dried',
                'prepared',
                'fluid',
                'canned',
                'unknown',
              }.contains(state)) {
            throw const FormatException('Invalid preparation state');
          }
          final grams = number(raw['suggestedPortionGrams'], 10000);
          if (grams == 0) {
            throw const FormatException('Invalid suggested portion');
          }
          return RecognitionCandidate(
            name: (raw['name'] as String).trim(),
            foodState: state as String?,
            matchedFoodId: id is String && catalogIds.contains(id) ? id : null,
            confidence: number(raw['confidence'], 1),
            suggestedPortionGrams: grams,
            uncertaintyNotes: notes(raw['uncertaintyNotes']),
          );
        }),
      ),
      generalNotes: notes(value['generalNotes']),
    );
  }
}

enum RecognitionFailure { unavailable, network, invalidResponse, emptyResult }

class FoodRecognitionException implements Exception {
  const FoodRecognitionException(this.failure);
  final RecognitionFailure failure;
}

abstract interface class FoodRecognitionProvider {
  bool get isAvailable;
  Future<FoodRecognitionResult> recognize(FoodRecognitionInput input);
}

/// Honest fallback. It never invents a result or sends a photograph anywhere.
class ManualFoodRecognitionProvider implements FoodRecognitionProvider {
  const ManualFoodRecognitionProvider();
  @override
  bool get isAvailable => false;
  @override
  Future<FoodRecognitionResult> recognize(FoodRecognitionInput input) async =>
      throw const FoodRecognitionException(RecognitionFailure.unavailable);
}

/// Only a separately reviewed provider with a lawful personal-input policy may
/// implement this contract. Availability alone is never upload authorization.
abstract interface class ConsentGatedFoodRecognitionProvider
    implements FoodRecognitionProvider {
  String get providerName;
  Uri get privacyPolicy;
  String get processingDisclosure;
  bool get acceptsPersonalImages;
}

/// Qualification accepts only independently hash-approved nonpersonal test input.
/// It does not assert that personal uploads are permitted.
abstract interface class NonpersonalQualificationProvider
    implements FoodRecognitionProvider {
  bool permitsImage(List<int> jpegBytes);
  String get providerName;
  Uri get privacyPolicy;
  String get processingDisclosure;
}

abstract interface class LocalizedRecognitionDisclosure {
  String disclosureFor(String languageCode);
}
