import '../../../l10n/app_localizations.dart';

/// Only the backend's fixed safety notices are translated. Candidate names
/// and unknown provider notes remain data, never guessed translations.
String localizedRecognitionNote(
  String note,
  AppLocalizations l10n,
) => switch (note) {
  'Visual candidate only. Confirm ingredients and weighed portion.' =>
    l10n.cameraCandidateSafetyNote,
  'Image recognition cannot measure grams or provide verified nutrition.' =>
    l10n.cameraNutritionSafetyNote,
  'Hidden oil, sugar and ingredients may be missing. Nutrition must come from a matched sourced food record, not the model.' =>
    l10n.localeName.startsWith('ar')
        ? 'ممكن زيت أو سكر أو مكونات مخفية تكون ناقصة. الحساب من صنف مطابق بمصدر موثوق، مش من النموذج.'
        : note,
  'Visual estimate, not a measured amount. Review food, preparation and grams.' =>
    l10n.localeName.startsWith('ar')
        ? 'تقدير بصري مش وزن مقاس. راجع الصنف والتحضير والجرامات.'
        : note,
  _ => note,
};
