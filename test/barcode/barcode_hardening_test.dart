import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/features/barcode/data/off_cache.dart';
import 'package:sufradepi/features/barcode/data/off_client.dart';
import 'package:sufradepi/features/barcode/domain/off_product.dart';
import 'package:sufradepi/features/barcode/domain/product_lookup_service.dart';
import 'barcode_domain_test.dart' as fixture;

void main() {
  test('response must identify the requested valid GTIN', () {
    expect(OffProduct.fromV3('1', fixture.nutella()), isNull);
    expect(OffProduct.fromV3('5449000000996', fixture.nutella()), isNull);
    final missing = fixture.nutella();
    (missing['product'] as Map).remove('code');
    expect(OffProduct.fromV3('3017620422003', missing), isNull);
  });
  test('missing or contradictory measurement basis never implies grams', () {
    final data = fixture.nutella();
    final p = data['product'] as Map;
    for (final key in [
      'quantity',
      'product_quantity_unit',
      'serving_size',
      'serving_quantity_unit',
    ]) {
      p.remove(key);
    }
    p['nutrition_data_per'] = '100g';
    expect(
      OffProduct.fromV3('3017620422003', data)!.basis,
      NutrientBasis.unknown,
    );
    p['quantity'] = '400 g';
    p['serving_size'] = '250 ml';
    expect(OffProduct.fromV3('3017620422003', data)!.canLog, isFalse);
    p.remove('serving_size');
    p['nutrition_data_per'] = '100ml';
    expect(
      OffProduct.fromV3('3017620422003', data)!.basis,
      NutrientBasis.per100ml,
    );
    p['nutrition_data_per'] = 'unrecognized';
    expect(
      OffProduct.fromV3('3017620422003', data)!.basis,
      NutrientBasis.unknown,
    );
  });
  test('observed URLs are constrained to HTTPS OFF origins', () {
    final data = fixture.nutella();
    (data['product'] as Map)['url'] = 'https://untrusted.invalid/product';
    (data['product'] as Map)['image_front_small_url'] =
        'http://images.openfoodfacts.org/x.jpg';
    final p = OffProduct.fromV3(
      '3017620422003',
      data,
      responseUrl:
          'https://world.openfoodfacts.org/api/v3/product/3017620422003.json',
    )!;
    expect(p.imageUrl, isNull);
    expect(p.sourceUrl, startsWith('https://world.openfoodfacts.org/'));
  });
  test(
    'account cache isolates prefix-related UIDs and rejects late writes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      String? uid = 'a';
      final a = OffCache(prefs, ownerUid: 'a', activeUserId: () => uid);
      final ab = OffCache(prefs, ownerUid: 'a_b', activeUserId: () => uid);
      final p = OffProduct.fromV3('3017620422003', fixture.nutella())!;
      await a.writeProduct(p.barcode, p);
      expect(a.read(p.barcode), isA<CachedProduct>());
      uid = 'a_b';
      expect(a.read(p.barcode), isNull);
      expect(ab.read(p.barcode), isNull);
      await ab.writeProduct(p.barcode, p);
      await a.clear();
      expect(ab.read(p.barcode), isA<CachedProduct>());
      await a.writeProduct(p.barcode, p);
      uid = 'a';
      expect(a.read(p.barcode), isNull);
    },
  );
  test(
    'account switch drops an in-flight response without caching it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      String? uid = 'a';
      final cache = OffCache(prefs, ownerUid: 'a', activeUserId: () => uid);
      final done = Completer<OffHttpResponse>();
      final service = ProductLookupService(
        cache: cache,
        client: OffClient(
          config: fixture.cfg,
          transport: fixture.FakeTransport((_, _) => done.future),
        ),
      );
      final pending = service.lookup('3017620422003');
      uid = 'b';
      done.complete(fixture.ok(fixture.nutella()));
      expect(await pending, isA<LookupFailed>());
      uid = 'a';
      expect(cache.read('3017620422003'), isNull);
    },
  );
}
