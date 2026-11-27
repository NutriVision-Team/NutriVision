/// Parses user-entered Arabic-Indic/Persian or ASCII decimals. Rejects
/// ambiguous comma-grouped numbers rather than silently changing the amount.
double? parseDecimalInput(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  var value = input
      .trim()
      .split('')
      .map((c) {
        final a = arabic.indexOf(c);
        if (a >= 0) return '$a';
        final p = persian.indexOf(c);
        return p >= 0 ? '$p' : c;
      })
      .join()
      .replaceAll('٫', '.')
      .replaceAll('٬', '');
  if (value.contains(',')) {
    if (!RegExp(r'^\d+,\d{1,2}$').hasMatch(value)) return null;
    value = value.replaceAll(',', '.');
  }
  if (!RegExp(r'^\d+(?:\.\d+)?$').hasMatch(value)) return null;
  final number = double.tryParse(value);
  return number != null && number.isFinite ? number : null;
}
