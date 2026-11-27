import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/camera_analysis/presentation/recognition_note_localization.dart';
import 'package:sufradepi/l10n/app_localizations_ar.dart';
import 'package:sufradepi/l10n/app_localizations_en.dart';

void main() {
  const candidate =
      'Visual candidate only. Confirm ingredients and weighed portion.';
  const nutrition =
      'Image recognition cannot measure grams or provide verified nutrition.';
  test('fixed recognition safety notes follow Arabic and English locale', () {
    final ar = AppLocalizationsAr();
    final en = AppLocalizationsEn();
    expect(
      localizedRecognitionNote(candidate, ar),
      ar.cameraCandidateSafetyNote,
    );
    expect(
      localizedRecognitionNote(nutrition, ar),
      ar.cameraNutritionSafetyNote,
    );
    expect(localizedRecognitionNote(candidate, ar), isNot(candidate));
    expect(localizedRecognitionNote(nutrition, ar), isNot(nutrition));
    expect(localizedRecognitionNote(candidate, en), candidate);
    expect(localizedRecognitionNote(nutrition, en), nutrition);
  });
  test('unknown notes and food names remain untouched data', () {
    final ar = AppLocalizationsAr();
    for (final text in [
      'chicken',
      'Unknown source caution',
      '$candidate extra',
      '',
    ]) {
      expect(localizedRecognitionNote(text, ar), text);
    }
  });
}
