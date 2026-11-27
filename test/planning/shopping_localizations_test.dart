import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/l10n/app_localizations_ar.dart';
import 'package:sufradepi/l10n/app_localizations_en.dart';

void main() {
  test('English shopping counts use singular only for one', () {
    final l10n = AppLocalizationsEn();
    expect(l10n.shoppingItemCount(0), '0 items');
    expect(l10n.shoppingItemCount(1), '1 item');
    expect(l10n.shoppingItemCount(2), '2 items');
    expect(l10n.shoppingItemCount(12), '12 items');
  });

  test('Arabic shopping counts use the proper count form', () {
    final l10n = AppLocalizationsAr();
    expect(l10n.shoppingItemCount(0), '٠ أصناف');
    expect(l10n.shoppingItemCount(1), 'صنف واحد');
    expect(l10n.shoppingItemCount(2), 'صنفين');
    expect(l10n.shoppingItemCount(3), contains('أصناف'));
    expect(l10n.shoppingItemCount(11), endsWith('صنف'));
    expect(l10n.shoppingItemCount(100), endsWith('صنف'));
  });
}
