/// Barcode text handling. Pure Dart, no platform access.
///
/// Only GTIN-8/12/13/14 with a valid check digit are looked up. Anything
/// else (including non-numeric Code 128 payloads) is reported as unsupported
/// instead of being sent to a remote service.
class BarcodeCode {
  const BarcodeCode._(this.value);

  /// Digits only, as typed or scanned (never padded).
  final String value;

  /// Normalizes Arabic-Indic and Persian digits and strips separators.
  static String normalize(String input) {
    final out = StringBuffer();
    for (final unit in input.runes) {
      if (unit >= 0x0660 && unit <= 0x0669) {
        out.writeCharCode(0x30 + unit - 0x0660);
      } else if (unit >= 0x06F0 && unit <= 0x06F9) {
        out.writeCharCode(0x30 + unit - 0x06F0);
      } else if (unit >= 0x30 && unit <= 0x39) {
        out.writeCharCode(unit);
      }
    }
    return out.toString();
  }

  static bool hasValidLengthAndCheckDigit(String digits) {
    if (!RegExp(r'^(\d{8}|\d{12}|\d{13}|\d{14})$').hasMatch(digits)) {
      return false;
    }
    final d = digits.codeUnits.map((c) => c - 0x30).toList();
    final check = d.removeLast();
    var sum = 0;
    for (var i = 0; i < d.length; i++) {
      final fromRight = d.length - 1 - i;
      sum += d[i] * (fromRight.isEven ? 3 : 1);
    }
    return (10 - sum % 10) % 10 == check;
  }

  /// Returns null when [input] is not a valid GTIN.
  static BarcodeCode? tryParse(String input) {
    // Never turn arbitrary scanner text/URLs into a different valid GTIN.
    // Manual entry may contain whitespace or hyphen separators only.
    if (RegExp(r'[^0-9٠-٩۰-۹\s-]').hasMatch(input)) return null;
    final digits = normalize(input);
    return hasValidLengthAndCheckDigit(digits) ? BarcodeCode._(digits) : null;
  }

  /// Key shared by UPC-A (12), EAN-13 and GTIN-14 spellings of one product so
  /// the cache and in-flight de-duplication do not double-request. EAN-8 is
  /// left alone because it is a different number space.
  String get canonical {
    if (value.length == 8) return value;
    return value.replaceFirst(RegExp(r'^0+'), '').padLeft(13, '0');
  }

  @override
  bool operator ==(Object other) =>
      other is BarcodeCode && other.canonical == canonical;
  @override
  int get hashCode => canonical.hashCode;
  @override
  String toString() => value;
}
