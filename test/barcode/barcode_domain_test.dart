import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/features/barcode/data/off_cache.dart';
import 'package:sufradepi/features/barcode/data/off_client.dart';
import 'package:sufradepi/features/barcode/domain/barcode_code.dart';
import 'package:sufradepi/features/barcode/domain/off_product.dart';
import 'package:sufradepi/features/barcode/domain/product_lookup_service.dart';

/// Real v3 response captured from world.openfoodfacts.org on 2026-11-22
/// (fields limited as the client requests).
Map<String, dynamic> nutella() =>
    jsonDecode(
          File('test/barcode/fixtures/off_nutella_v3.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

class FakeTransport implements OffTransport {
  FakeTransport(this.handler);
  final FutureOr<OffHttpResponse> Function(Uri, Map<String, String>) handler;
  final calls = <Uri>[];
  final headersSeen = <Map<String, String>>[];
  @override
  Future<OffHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    calls.add(uri);
    headersSeen.add(headers);
    return handler(uri, headers);
  }
}

const cfg = OffConfig(contact: 'team@sufra-app.test');

OffHttpResponse ok(Map<String, dynamic> j) =>
    OffHttpResponse(200, jsonEncode(j));

Map<String, dynamic> drink({String? qtyUnit, String? quantity}) => {
  'status': 'success',
  'product': {
    'code': '5449000000996',
    'product_name': 'Cola',
    'quantity': quantity ?? '330 ml',
    'product_quantity_unit': qtyUnit,
    'nutriments': {'energy-kcal_100g': 42, 'sugars_100g': 10.6},
  },
};

void main() {
  group('BarcodeCode', () {
    test('validates GTIN check digits and lengths', () {
      expect(BarcodeCode.tryParse('3017620422003'), isNotNull);
      expect(BarcodeCode.tryParse('3017620422004'), isNull);
      expect(BarcodeCode.tryParse('12345'), isNull);
      expect(BarcodeCode.tryParse('96385074'), isNotNull); // EAN-8
      expect(BarcodeCode.tryParse('036000291452'), isNotNull); // UPC-A
    });
    test('normalizes Arabic-Indic digits and separators', () {
      expect(BarcodeCode.normalize('٣٠١٧ ٦٢٠-٤٢٢٠٠٣'), '3017620422003');
      expect(BarcodeCode.tryParse('٣٠١٧٦٢٠٤٢٢٠٠٣')?.value, '3017620422003');
    });
    test(
      'UPC-A and EAN-13 spelling share one cache key; EAN-8 does not collide',
      () {
        expect(
          BarcodeCode.tryParse('036000291452')!.canonical,
          BarcodeCode.tryParse('0036000291452')!.canonical,
        );
        expect(BarcodeCode.tryParse('96385074')!.canonical, '96385074');
      },
    );
    test('non numeric Code 128 payload is rejected', () {
      expect(BarcodeCode.tryParse('ABC-123'), isNull);
      for (final text in [
        'ABC3017620422003',
        'https://x.invalid/3017620422003',
        '3017620422003.',
        '+3017620422003',
      ]) {
        expect(BarcodeCode.tryParse(text), isNull);
      }
    });
  });

  group('OffProduct.fromV3', () {
    test(
      'parses real response; sodium g to mg; grade kept; no zero invented',
      () {
        final p = OffProduct.fromV3('3017620422003', nutella())!;
        expect(
          p.name,
          'نوتيلا',
        ); // Arabic name preferred when the source has one
        expect(p.brand, 'Ferrero, Nutella');
        expect(p.energyKcal, 539);
        expect(p.proteinG, 6.3);
        expect(p.fiberG, 0); // source says 0: a measured zero stays 0
        expect(p.sodiumMg, closeTo(42.8, .5)); // 0.0428 g -> mg
        expect(p.nutriScore, 'e');
        expect(p.allergenTags, containsAll(['en:milk', 'en:nuts']));
        expect(p.basis, NutrientBasis.per100g);
        expect(p.imageUrl, startsWith('https://'));
      },
    );
    test('missing nutrients are null, not zero', () {
      final p = OffProduct.fromV3('3017620422003', {
        'status': 'success',
        'product': {
          'code': '3017620422003',
          'product_name': 'X',
          'nutriments': {'energy-kcal_100g': 10},
        },
      })!;
      expect(p.proteinG, isNull);
      expect(p.sodiumMg, isNull);
      expect(p.allergenTags, isNull);
      expect(p.nutriScore, isNull);
    });
    test('invalid or absent nutri-score is dropped', () {
      for (final g in ['unknown', 'not-applicable', 'f', '', null]) {
        final p = OffProduct.fromV3('3017620422003', {
          'status': 'success',
          'product': {
            'code': '3017620422003',
            'product_name': 'X',
            'nutriscore_grade': g,
          },
        })!;
        expect(p.nutriScore, isNull, reason: '$g');
      }
    });
    test('negative / non-finite / string nutrient values are unknown', () {
      final p = OffProduct.fromV3('3017620422003', {
        'status': 'success',
        'product': {
          'code': '3017620422003',
          'product_name': 'X',
          'nutriments': {
            'energy-kcal_100g': -5,
            'proteins_100g': 'abc',
            'fat_100g': double.nan,
          },
        },
      })!;
      expect(p.energyKcal, isNull);
      expect(p.proteinG, isNull);
      expect(p.fatG, isNull);
    });
    test('liquid signal => per100ml, logging blocked, no catalog food', () {
      for (final d in [
        drink(),
        drink(quantity: '1.5 L'),
        drink(qtyUnit: 'ml', quantity: ''),
        drink(quantity: '33cl'),
      ]) {
        final p = OffProduct.fromV3('5449000000996', d)!;
        expect(p.basis, NutrientBasis.per100ml, reason: '${d['product']}');
        expect(p.canLog, isFalse);
        expect(p.toCatalogFood(), isNull);
        expect(p.portion(100), isNull);
      }
    });
    test('mass quantity stays per100g', () {
      final p = OffProduct.fromV3('3017620422003', {
        'status': 'success',
        'product': {
          'code': '3017620422003',
          'product_name': 'X',
          'quantity': '400 g',
          'product_quantity_unit': 'g',
          'nutriments': {'energy-kcal_100g': 100},
        },
      })!;
      expect(p.basis, NutrientBasis.per100g);
      expect(p.canLog, isTrue);
    });
    test('serving grams only when declared in grams', () {
      Map<String, dynamic> j(Map<String, dynamic> extra) => {
        'status': 'success',
        'product': {
          'code': '3017620422003',
          'product_name': 'X',
          'nutriments': {'energy-kcal_100g': 100},
          ...extra,
        },
      };
      expect(
        OffProduct.fromV3(
          '3017620422003',
          j({'serving_size': '30 g', 'serving_quantity': 30}),
        )!.servingGrams,
        30,
      );
      expect(
        OffProduct.fromV3(
          '3017620422003',
          j({'serving_size': '1 biscuit', 'serving_quantity': 12}),
        )!.servingGrams,
        isNull,
      );
      expect(
        OffProduct.fromV3(
          '3017620422003',
          j({'serving_size': '250 ml', 'serving_quantity': 250}),
        )!.servingGrams,
        isNull,
      );
    });
    test('no energy => cannot log; nameless or failed => no product', () {
      final p = OffProduct.fromV3('3017620422003', {
        'status': 'success',
        'product': {'code': '3017620422003', 'product_name': 'X'},
      })!;
      expect(p.canLog, isFalse);
      expect(
        OffProduct.fromV3('3017620422003', {
          'status': 'success',
          'product': {'code': '3017620422003'},
        }),
        isNull,
      );
      expect(OffProduct.fromV3('3017620422003', {'status': 'failure'}), isNull);
    });
    test(
      'catalog food keeps provenance and unknowns; portion math is per100g',
      () {
        final p = OffProduct.fromV3('3017620422003', nutella())!;
        final food = p.toCatalogFood()!;
        expect(food.source, 'Open Food Facts');
        expect(food.sourceId, '3017620422003');
        expect(
          food.sourceUrl,
          isNull,
        ); // No URL was observed in this captured fixture.
        expect(food.verificationStatus, 'crowdsourced_unverified');
        final portion = p.portion(15)!;
        expect(portion.amount('calories'), closeTo(80.85, .01));
        expect(portion.canSave, isTrue);
        expect(p.portion(0), isNull);
        expect(p.portion(10001), isNull);
        // unknown stays unknown after scaling
        final q = OffProduct.fromV3('3017620422003', {
          'status': 'success',
          'product': {
            'code': '3017620422003',
            'product_name': 'X',
            'quantity': '100 g',
            'nutriments': {'energy-kcal_100g': 100},
          },
        })!;
        expect(q.portion(50)!.amount('protein'), isNull);
      },
    );
    test('json round trip', () {
      final p = OffProduct.fromV3('3017620422003', nutella())!;
      final r = OffProduct.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      )!;
      expect(r.toJson(), p.toJson());
    });
  });

  group('OffClient', () {
    final code = BarcodeCode.tryParse('3017620422003')!;
    test('sends identifiable User-Agent, minimal fields, v3 URL', () async {
      final t = FakeTransport((_, _) => ok(nutella()));
      final r = await OffClient(config: cfg, transport: t).fetch(code);
      expect(r, isA<OffFetched>());
      expect(t.calls.single.path, '/api/v3/product/3017620422003.json');
      expect(t.calls.single.host, 'world.openfoodfacts.org');
      expect(
        t.calls.single.queryParameters['fields'],
        OffProduct.requestedFields,
      );
      expect(
        t.headersSeen.single['User-Agent'],
        'Sufra/1.0.0 (team@sufra-app.test)',
      );
    });
    test('refuses network without a real contact', () async {
      final t = FakeTransport((_, _) => ok(nutella()));
      for (final c in ['', 'not-an-email', 'a@example.com']) {
        final r = await OffClient(
          config: OffConfig(contact: c),
          transport: t,
        ).fetch(code);
        expect((r as OffFailed).reason, OffFailure.notConfigured);
      }
      expect(t.calls, isEmpty);
    });
    test('product_not_found', () async {
      final t = FakeTransport(
        (_, _) => ok({
          'status': 'failure',
          'result': {'id': 'product_not_found'},
        }),
      );
      expect(
        await OffClient(config: cfg, transport: t).fetch(code),
        isA<OffNotFound>(),
      );
    });
    test('429/503 back off with Retry-After and block further calls', () async {
      var n = 0;
      final t = FakeTransport((_, _) {
        n++;
        return const OffHttpResponse(
          429,
          '',
          retryAfter: Duration(seconds: 30),
        );
      });
      final c = OffClient(config: cfg, transport: t);
      final r = await c.fetch(code) as OffFailed;
      expect(r.reason, OffFailure.rateLimited);
      expect(r.retryAfter, const Duration(seconds: 30));
      final r2 = await c.fetch(code) as OffFailed;
      expect(r2.reason, OffFailure.rateLimited);
      expect(n, 1);
    });
    test('local throttle caps requests below the documented 15/min', () async {
      var now = DateTime(2026, 11, 22, 12);
      final t = FakeTransport((_, _) => ok(nutella()));
      final c = OffClient(
        config: cfg,
        transport: t,
        throttle: RequestThrottle(now: () => now),
      );
      for (var i = 0; i < 10; i++) {
        expect(await c.fetch(code), isA<OffFetched>());
      }
      final blocked = await c.fetch(code) as OffFailed;
      expect(blocked.reason, OffFailure.rateLimited);
      expect(t.calls.length, 10);
      now = now.add(const Duration(seconds: 61));
      expect(await c.fetch(code), isA<OffFetched>());
    });
    test('offline, timeout, 500, garbage body', () async {
      Future<OffFailure> reason(
        FutureOr<OffHttpResponse> Function(Uri, Map<String, String>) h, {
        Duration timeout = const Duration(seconds: 8),
      }) async {
        final c = OffClient(
          config: OffConfig(contact: 'team@sufra-app.test', timeout: timeout),
          transport: FakeTransport(h),
        );
        return ((await c.fetch(code)) as OffFailed).reason;
      }

      expect(
        await reason((_, _) => throw const SocketException('x')),
        OffFailure.offline,
      );
      expect(
        await reason(
          (_, _) => Completer<OffHttpResponse>().future,
          timeout: const Duration(milliseconds: 20),
        ),
        OffFailure.unavailable,
      );
      expect(
        await reason((_, _) => const OffHttpResponse(500, '')),
        OffFailure.unavailable,
      );
      expect(
        await reason((_, _) => const OffHttpResponse(200, '<html>')),
        OffFailure.badResponse,
      );
      expect(
        await reason((_, _) => const OffHttpResponse(200, '[1]')),
        OffFailure.badResponse,
      );
    });
  });

  group('ProductLookupService + cache', () {
    late OffCache cache;
    late FakeTransport transport;
    late ProductLookupService service;
    var now = DateTime(2026, 11, 22, 12);
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      now = DateTime(2026, 11, 22, 12);
      cache = OffCache(await SharedPreferences.getInstance(), now: () => now);
      transport = FakeTransport((_, _) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return ok(nutella());
      });
      service = ProductLookupService(
        client: OffClient(config: cfg, transport: transport),
        cache: cache,
      );
    });
    test('invalid code never reaches the network', () async {
      expect(await service.lookup('1234'), isA<LookupInvalidCode>());
      expect(transport.calls, isEmpty);
    });
    test(
      'concurrent identical lookups share one request, then cache serves',
      () async {
        final results = await Future.wait([
          service.lookup('3017620422003'),
          service.lookup('3017620422003'),
          service.lookup('٣٠١٧٦٢٠٤٢٢٠٠٣'),
        ]);
        expect(results.every((r) => r is LookupFound), isTrue);
        expect(transport.calls.length, 1);
        final again = await service.lookup('3017620422003') as LookupFound;
        expect(again.fromCache, isTrue);
        expect(transport.calls.length, 1);
      },
    );
    test('found entry expires after TTL; miss expires sooner', () async {
      await service.lookup('3017620422003');
      now = now.add(const Duration(days: 8));
      await service.lookup('3017620422003');
      expect(transport.calls.length, 2);
    });
    test('not found is cached briefly, not forever', () async {
      var n = 0;
      final t = FakeTransport((_, _) {
        n++;
        return ok({
          'status': 'failure',
          'result': {'id': 'product_not_found'},
        });
      });
      final s = ProductLookupService(
        client: OffClient(config: cfg, transport: t),
        cache: cache,
      );
      expect(await s.lookup('3017620422003'), isA<LookupNotFound>());
      expect(await s.lookup('3017620422003'), isA<LookupNotFound>());
      expect(n, 1);
      now = now.add(const Duration(hours: 7));
      await s.lookup('3017620422003');
      expect(n, 2);
    });
    test('failures are not cached', () async {
      var n = 0;
      final t = FakeTransport((_, _) {
        n++;
        throw const SocketException('x');
      });
      final s = ProductLookupService(
        client: OffClient(config: cfg, transport: t),
        cache: cache,
      );
      await s.lookup('3017620422003');
      await s.lookup('3017620422003');
      expect(n, 2);
    });
    test(
      'cache holds no user identity, trims to max, and clear() wipes it',
      () async {
        final small = OffCache(
          await SharedPreferences.getInstance(),
          now: () => now,
          maxEntries: 2,
        );
        final p = OffProduct.fromV3('3017620422003', nutella())!;
        await small.writeMiss('96385074');
        now = now.add(const Duration(minutes: 1));
        await small.writeMiss('5449000000996');
        now = now.add(const Duration(minutes: 1));
        await small.writeProduct(p.barcode, p);
        expect(small.read('96385074'), isNull);
        expect(small.read(p.barcode), isNotNull);
        final prefs = await SharedPreferences.getInstance();
        for (final k in prefs.getKeys()) {
          expect(prefs.getString(k), isNot(contains('uid')));
        }
        await small.clear();
        expect(
          prefs.getKeys().where((k) => k.startsWith('off_cache')),
          isEmpty,
        );
      },
    );
    test('corrupt cache entry is ignored, not thrown', () async {
      SharedPreferences.setMockInitialValues({
        'off_cache_v1_3017620422003': '{bad',
      });
      final c = OffCache(await SharedPreferences.getInstance(), now: () => now);
      expect(c.read('3017620422003'), isNull);
    });
  });
}
