/// Independent fail-closed output filter. This is a conservative policy layer,
/// not a clinical safety classifier or a replacement for specialist review.
class CoachOutputSafety {
  const CoachOutputSafety();
  bool accepts(String text) {
    final t = text
        .toLowerCase()
        .replaceAll(RegExp('[أإآ]'), 'ا')
        .replaceAll(RegExp('[ً-ْ]'), '');
    if (t.trim().isEmpty || t.length > 6000) return false;
    if (RegExp(
      r'[\u3400-\u9fff\u3040-\u30ff\u0400-\u04ff\u00c0-\u024f\u1e00-\u1eff]',
    ).hasMatch(t)) {
      return false;
    }
    // All numeric advice remains in deterministic application cards. This also
    // blocks Arabic/Persian digits instead of checking English unit names only.
    if (RegExp(r'[0-9٠-٩۰-۹]|https?://|www\.|<[^>]+>|```').hasMatch(t)) {
      return false;
    }
    const unsafe = [
      'stop your medication',
      'increase your dose',
      'double your dose',
      'you have diabetes',
      'you have cancer',
      'guaranteed safe',
      'allergy free',
      'allergen-free',
      'cures diabetes',
      'purge',
      'اوقف الدواء',
      'وقف الدوا',
      'زود الجرعة',
      'زود الجرعه',
      'ضاعف الجرعة',
      'انت عندك سكر',
      'امن تماما',
      'خالي من الحساسية',
      'يعالج السكر',
      'تجويع',
      'تقيؤ',
    ];
    return !unsafe.any(t.contains);
  }
}
