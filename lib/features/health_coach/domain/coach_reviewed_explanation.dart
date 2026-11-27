import '../../meal_log/domain/catalog_meal_draft.dart';

/// An explicit review button may request explanation, never a save or new
/// arithmetic. Nutrition remains in the deterministic calculator panel.
String reviewedCalculationQuestion(CatalogMealDraft draft, String locale) {
  final totals = draft.totals;
  if (!draft.canSave || totals == null || draft.portions.length > 8) {
    throw StateError('Review up to 8 complete catalog portions first');
  }
  final question = locale == 'ar'
      ? 'اشرح نتيجة حساب الأصناف والأوزان اللي راجعتها والمرفقة كبيانات حساب منفصلة. الحساب من كتالوج التطبيق، مش هدف حمية. من غير إعادة حساب أو أرقام في الشرح، ومفيش إذن بحفظ وجبة.'
      : 'Explain the reviewed catalog calculation supplied as separate structured data. It is a source-based food calculation, not a diet goal. Do not recalculate or repeat numbers in prose. No meal-save permission is granted.';
  if (question.length > 1000) {
    throw StateError('Review fewer foods for a bounded explanation');
  }
  return question;
}
