import '../../food_catalog/data/datasources/local_food_data_source.dart';

/// Conservative catalog-name/category exclusions only. Not allergen certification.
/// The source catalog has no cross-contamination or packaged-ingredient labels.
abstract final class FoodPreferenceFilter {
  static String normalize(String v) => v
      .trim()
      .toLowerCase()
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي');
  static const _animal = {'meat', 'poultry', 'fish', 'seafood'};
  static const _veganExtra = {'dairy', 'eggs'};
  static const _allergyGroups = <List<String>>[
    [
      'milk',
      'dairy',
      'lactose',
      'لبن',
      'حليب',
      'البان',
      'جبن',
      'زبادي',
      'yogurt',
      'cheese',
      'butter',
    ],
    ['egg', 'eggs', 'بيض'],
    ['peanut', 'فول سوداني', 'فول سوداني', 'arachis'],
    [
      'nut',
      'nuts',
      'مكسرات',
      'almond',
      'walnut',
      'hazelnut',
      'cashew',
      'لوز',
      'جوز',
      'بندق',
      'كاجو',
    ],
    [
      'fish',
      'seafood',
      'سمك',
      'اسماك',
      'salmon',
      'tuna',
      'tilapia',
      'shrimp',
      'shellfish',
      'جمبري',
      'سلمون',
      'تونة',
      'بلطي',
    ],
    [
      'wheat',
      'gluten',
      'قمح',
      'جلوتين',
      'bread',
      'pasta',
      'خبز',
      'عيش',
      'مكرونة',
      'شعير',
      'barley',
    ],
    ['sesame', 'سمسم', 'tahini', 'طحينة'],
    ['soy', 'صويا', 'tofu'],
  ];
  static bool supportsDiet(String value) => {
    '',
    'none',
    'any',
    'balanced',
    'متوازن',
    'بدون قيود',
    'لا يوجد',
    'vegan',
    'نباتي صرف',
    'نباتي بالكامل',
    'vegetarian',
    'نباتي',
    'pescatarian',
    'نباتي مع سمك',
  }.contains(normalize(value));
  static bool allows(
    LocalFoodRecord f, {
    List<String> allergies = const [],
    List<String> dietaryPreferences = const [],
  }) {
    final name = normalize([f.id, f.nameAr, f.nameEn, ...f.aliases].join(' '));
    for (final raw in allergies) {
      final term = normalize(raw);
      if (term.isEmpty) continue;
      final group = _allergyGroups
          .where((g) => g.any((x) => normalize(x) == term))
          .firstOrNull;
      final terms = group ?? [term];
      if (terms.any((x) => name.contains(normalize(x)))) return false;
      if (group == _allergyGroups[0] && f.category == 'dairy') return false;
      if (group == _allergyGroups[1] && f.category == 'eggs') return false;
      if (group == _allergyGroups[4] &&
          {'fish', 'seafood'}.contains(f.category)) {
        return false;
      }
    }
    for (final raw in dietaryPreferences) {
      final p = normalize(raw);
      if (p.isEmpty ||
          {
            'none',
            'any',
            'balanced',
            'متوازن',
            'بدون قيود',
            'لا يوجد',
          }.contains(p)) {
        continue;
      }
      if ({'vegan', 'نباتي صرف', 'نباتي بالكامل'}.contains(p)) {
        if (_animal.contains(f.category) ||
            _veganExtra.contains(f.category) ||
            name.contains('honey') ||
            name.contains('عسل')) {
          return false;
        }
      } else if ({'vegetarian', 'نباتي'}.contains(p)) {
        if (_animal.contains(f.category)) return false;
      } else if ({'pescatarian', 'نباتي مع سمك'}.contains(p)) {
        if ({'meat', 'poultry'}.contains(f.category)) return false;
      } else {
        // Unknown dietary constraint cannot be silently treated as satisfied.
        return false;
      }
    }
    return true;
  }
}
