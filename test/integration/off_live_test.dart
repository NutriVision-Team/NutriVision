import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/barcode/data/off_client.dart';
import 'package:sufradepi/features/barcode/domain/barcode_code.dart';
import 'package:sufradepi/features/barcode/domain/off_product.dart';

// Run explicitly with flutter test --dart-define=RUN_OFF_LIVE=true
// test/integration/off_live_test.dart. Ordinary regression runs never call OFF.
class _RealNetwork extends HttpOverrides {}

void main() {
  test(
    'real OFF v3 lookup through application transport and parser',
    () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final result = await OffClient().fetch(
          BarcodeCode.tryParse('3017620422003')!,
        );
        expect(result, isA<OffFetched>());
        final product = (result as OffFetched).product;
        expect(product.barcode, '3017620422003');
        expect(product.name, isNotEmpty);
        expect(product.basis, NutrientBasis.per100g);
        expect(product.energyKcal, greaterThan(0));
        expect(product.sourceUrl, startsWith('https://'));
        expect(product.canLog, isTrue);
        // No generated nutrition or guessed product URL enters this report.
        // ignore: avoid_print
        print(
          'OFF verified: code=${product.barcode}, name=${product.name}, '
          'basis=${product.basis.name}, kcal=${product.energyKcal}, '
          'source=${product.sourceUrl}',
        );
      }, _RealNetwork());
    },
    skip: !const bool.fromEnvironment('RUN_OFF_LIVE'),
  );
}
