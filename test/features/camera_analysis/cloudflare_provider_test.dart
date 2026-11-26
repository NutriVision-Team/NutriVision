import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sufradepi/features/camera_analysis/data/cloudflare_food_recognition.dart';
import 'package:sufradepi/features/camera_analysis/domain/food_recognition_provider.dart';

void main() {
  tearDown(() {
    FoodVisionQualification.bearer = null;
    FoodVisionQualification.fixtureHash = null;
  });
  test('default and nonmatching image cannot send any bytes', () async {
    var calls = 0;
    final p = CloudflareFoodRecognitionProvider(
      client: MockClient((r) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    final input = FoodRecognitionInput(
      jpegBytes: Uint8List.fromList([1, 2]),
      mealType: 'lunch',
    );
    expect(p.isAvailable, false);
    await expectLater(
      p.recognize(input),
      throwsA(isA<FoodRecognitionException>()),
    );
    FoodVisionQualification.bearer = 'unit-test-not-a-real-capability';
    FoodVisionQualification.fixtureHash = 'different';
    await expectLater(
      p.recognize(input),
      throwsA(isA<FoodRecognitionException>()),
    );
    expect(calls, 0);
  });
  test(
    'exact qualified JPEG sends only bytes and review response cannot supply nutrition',
    () async {
      final bytes = Uint8List.fromList([255, 216, 1, 255, 217]);
      FoodVisionQualification.bearer = 'unit-test-not-a-real-capability';
      FoodVisionQualification.fixtureHash = sha256.convert(bytes).toString();
      final p = CloudflareFoodRecognitionProvider(
        client: MockClient((r) async {
          expect(r.url, CloudflareFoodRecognitionProvider.endpoint);
          expect(r.bodyBytes, bytes);
          expect(r.headers['content-type'], 'image/jpeg');
          expect(
            utf8
                .decode(r.bodyBytes, allowMalformed: true)
                .contains('PRIVATE_NOTES'),
            false,
          );
          return http.Response(
            jsonEncode({
              'requiresUserReview': true,
              'items': [
                {
                  'name': 'rice',
                  'calories': 999,
                  'confidence': null,
                  'suggestedPortionGrams': null,
                },
              ],
            }),
            200,
          );
        }),
      );
      final result = await p.recognize(
        FoodRecognitionInput(
          jpegBytes: bytes,
          mealType: 'lunch',
          notes: 'PRIVATE_NOTES',
        ),
      );
      expect(result.requiresUserReview, true);
      expect(result.items.single.name, 'rice');
      expect(result.items.single.matchedFoodId, null);
      expect(result.items.single.suggestedPortionGrams, null);
    },
  );
  test(
    'backend error and malformed response never turn into success',
    () async {
      final bytes = Uint8List.fromList([255, 216, 1, 255, 217]);
      FoodVisionQualification.bearer = 'unit-test-not-a-real-capability';
      FoodVisionQualification.fixtureHash = sha256.convert(bytes).toString();
      for (final response in [
        http.Response('{}', 429),
        http.Response('bad', 200),
      ]) {
        final p = CloudflareFoodRecognitionProvider(
          client: MockClient((_) async => response),
        );
        await expectLater(
          p.recognize(
            FoodRecognitionInput(jpegBytes: bytes, mealType: 'lunch'),
          ),
          throwsA(isA<FoodRecognitionException>()),
        );
      }
    },
  );
}
