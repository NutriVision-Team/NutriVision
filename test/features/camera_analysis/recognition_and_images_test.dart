import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sufradepi/features/camera_analysis/data/meal_image_preparer.dart';
import 'package:sufradepi/features/camera_analysis/domain/food_recognition_provider.dart';

void main() {
  Map<String, dynamic> response() => {
    'items': [
      {
        'name': 'فول',
        'matchedFoodId': 'beans',
        'confidence': .8,
        'suggestedPortionGrams': null,
        'uncertaintyNotes': ['راجع المكونات'],
      },
    ],
    'generalNotes': [],
    'requiresUserReview': true,
  };
  FoodRecognitionResult parse(Map<String, dynamic> value) =>
      FoodRecognitionResult.parse(jsonEncode(value), catalogIds: {'beans'});
  test('accepts food candidates only, never model nutrition', () {
    final value = response();
    (value['items'] as List).first['calories'] = 9999;
    final result = parse(value);
    expect(result.requiresUserReview, isTrue);
    expect(result.items.single.matchedFoodId, 'beans');
    expect(result.items.single.confidence, .8);
    expect(result.items.single.suggestedPortionGrams, isNull);
  });
  test('unknown model food IDs are not catalog references', () {
    final value = response();
    (value['items'] as List).first['matchedFoodId'] = 'invented';
    expect(parse(value).items.single.matchedFoodId, isNull);
  });
  test('rejects silent review bypass and invalid response shape', () {
    expect(
      () => parse(response()..['requiresUserReview'] = false),
      throwsFormatException,
    );
    expect(() => parse(response()..['items'] = 'food'), throwsFormatException);
    expect(
      () => FoodRecognitionResult.parse('not JSON', catalogIds: {}),
      throwsFormatException,
    );
  });
  test('rejects invalid confidence, portion and name', () {
    for (final pair in [
      ('confidence', 1.1),
      ('confidence', -1),
      ('suggestedPortionGrams', 0),
      ('suggestedPortionGrams', 10001),
      ('name', ''),
    ]) {
      final value = response();
      (value['items'] as List).first[pair.$1] = pair.$2;
      expect(() => parse(value), throwsFormatException);
    }
  });
  test('caps response and item count', () {
    expect(
      () => FoodRecognitionResult.parse(' ' * 65537, catalogIds: {}),
      throwsFormatException,
    );
    final value = response();
    value['items'] = List.filled(21, (value['items'] as List).first);
    expect(() => parse(value), throwsFormatException);
  });
  test('empty recognition stays empty, not invented results', () {
    expect(parse(response()..['items'] = []).items, isEmpty);
  });
  test(
    'manual provider is explicitly unavailable and never returns sample foods',
    () async {
      const provider = ManualFoodRecognitionProvider();
      expect(provider.isAvailable, isFalse);
      await expectLater(
        provider.recognize(
          FoodRecognitionInput(jpegBytes: Uint8List(0), mealType: 'lunch'),
        ),
        throwsA(isA<FoodRecognitionException>()),
      );
    },
  );
  test(
    'prepares real image, constrains dimensions and removes temporary result only',
    () async {
      final dir = await Directory.systemTemp.createTemp('sufra-photo-test');
      try {
        final source = File('${dir.path}/original.png');
        await source.writeAsBytes(
          img.encodePng(img.Image(width: 1800, height: 900)),
        );
        final prepared = await MealImagePreparer(
          temporaryDirectory: dir,
        ).prepare(source.path);
        expect(prepared.width, 1600);
        expect(prepared.height, 800);
        expect(prepared.bytes.take(2), [255, 216]);
        expect(await source.exists(), isTrue);
        await prepared.delete();
        expect(await File(prepared.path).exists(), isFalse);
        expect(await source.exists(), isTrue);
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
  test('rejects missing, unsupported and oversized input files', () async {
    final dir = await Directory.systemTemp.createTemp('sufra-photo-invalid');
    try {
      final preparer = MealImagePreparer(temporaryDirectory: dir);
      await expectLater(
        preparer.prepare('${dir.path}/missing'),
        throwsA(isA<ImagePreparationException>()),
      );
      final bad = File('${dir.path}/invalid')
        ..writeAsStringSync('not an image');
      await expectLater(
        preparer.prepare(bad.path),
        throwsA(isA<ImagePreparationException>()),
      );
      final huge = File('${dir.path}/huge');
      final handle = await huge.open(mode: FileMode.write);
      await handle.truncate(MealImagePreparer.maxInputBytes + 1);
      await handle.close();
      await expectLater(
        preparer.prepare(huge.path),
        throwsA(
          isA<ImagePreparationException>().having(
            (e) => e.failure,
            'failure',
            ImagePreparationFailure.tooLarge,
          ),
        ),
      );
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
