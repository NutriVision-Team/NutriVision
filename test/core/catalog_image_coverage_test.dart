import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/catalog_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    '101 catalog foods have loadable illustration bytes and recorded provenance',
    () async {
      final data =
          jsonDecode(await rootBundle.loadString('assets/data/foods.json'))
              as Map<String, dynamic>;
      final foods = data['foods'] as List;
      expect(foods.length, 101);
      final illustrated = foods;
      expect(illustrated.length, 101);
      expect(CatalogPhoto.bindings.length, 10);
      expect(CatalogPhoto.generatedIds.length, 91);
      final manifest =
          (jsonDecode(
                    File(
                      'test/fixtures/catalog_artwork_manifest.json',
                    ).readAsStringSync(),
                  )
                  as List)
              .cast<Map>();
      for (final food in illustrated) {
        final id = food['id'] as String;
        final name = CatalogPhoto.forFood(id);
        expect(name, isNotNull, reason: id);
        final entry = manifest.where((m) => m['foodId'] == id);
        expect(entry, hasLength(1), reason: id);
        expect(entry.single['kind'], 'new_generated_illustration');
        final folder = CatalogPhoto.generatedIds.contains(name)
            ? 'generated_food'
            : 'catalog_photos';
        final bytes = await rootBundle.load('assets/images/$folder/$name.png');
        expect(bytes.lengthInBytes, greaterThan(100), reason: id);
        expect(bytes.getUint32(0), 0x89504E47, reason: id);
      }
    },
  );
}
