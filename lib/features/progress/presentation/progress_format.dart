import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';

/// Arabic-Indic number formatting (١٬٧٨٠ / ٧٨٫٦) matching the design's
/// typography. Pure formatting helpers; all user-visible copy lives in
/// the generated AppLocalizations (see l10n manifests in the patch).
abstract final class ProgressFormat {
  static final NumberFormat _int = NumberFormat('#,##0', 'en');
  static final NumberFormat _one = NumberFormat('#,##0.#', 'en');

  static final RegExp _digit = RegExp('[0-9]');

  /// Convert ASCII digits to Arabic-Indic (٠-٩). Deterministic, unlike
  /// NumberFormat('ar'), which silently falls back to Latin digits when
  /// the locale data is not initialized (e.g. in widget tests).
  static String _arDigits(String s) => s.replaceAllMapped(
    _digit,
    (m) => String.fromCharCode(0x0660 + int.parse(m[0]!)),
  );

  static String intDigits(num v, {String locale = 'ar'}) =>
      locale.startsWith('ar') ? _arDigits(_int.format(v)) : _int.format(v);
  static String oneDecimal(num v, {String locale = 'ar'}) =>
      locale.startsWith('ar') ? _arDigits(_one.format(v)) : _one.format(v);
}

/// Egyptian week order (Saturday first), keyed off DateTime.weekday.
String weekdayLetter(AppLocalizations l10n, DateTime date) =>
    weekdayLetterIndex(l10n, (date.weekday + 1) % 7);

String weekdayName(AppLocalizations l10n, DateTime date) =>
    weekdayNameIndex(l10n, (date.weekday + 1) % 7);

String weekdayLetterIndex(AppLocalizations l10n, int index) => switch (index) {
  0 => l10n.weekdayLetter1,
  1 => l10n.weekdayLetter2,
  2 => l10n.weekdayLetter3,
  3 => l10n.weekdayLetter4,
  4 => l10n.weekdayLetter5,
  5 => l10n.weekdayLetter6,
  _ => l10n.weekdayLetter7,
};

String weekdayNameIndex(AppLocalizations l10n, int index) => switch (index) {
  0 => l10n.weekdayName1,
  1 => l10n.weekdayName2,
  2 => l10n.weekdayName3,
  3 => l10n.weekdayName4,
  4 => l10n.weekdayName5,
  5 => l10n.weekdayName6,
  _ => l10n.weekdayName7,
};
