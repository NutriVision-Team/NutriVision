import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/l10n/app_localizations_ar.dart';
import 'package:sufradepi/l10n/app_localizations_en.dart';

void main() {
  test('Favorites count uses natural singular and plural forms', () {
    final en = AppLocalizationsEn();
    final ar = AppLocalizationsAr();
    expect(en.favoritesHeroCount(1), 'Logged once in the last 30 days');
    for (final n in [2, 3, 11]) {
      expect(en.favoritesHeroCount(n), 'Logged $n times in the last 30 days');
    }
    expect(ar.favoritesHeroCount(1), 'سجّلتها مرة في آخر ٣٠ يوم');
    expect(ar.favoritesHeroCount(2), 'سجّلتها مرتين في آخر ٣٠ يوم');
    expect(ar.favoritesHeroCount(3), 'سجّلتها 3 مرات في آخر ٣٠ يوم');
    expect(ar.favoritesHeroCount(11), 'عدد مرات تسجيلها في آخر ٣٠ يوم: 11');
  });
}
