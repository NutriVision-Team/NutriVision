import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sufradepi/features/camera_analysis/data/cloudflare_personal_food_recognition.dart';
import 'package:sufradepi/features/camera_analysis/domain/food_recognition_provider.dart';

void main() {
  final jpeg = Uint8List.fromList([255, 216, 1, 255, 217]);
  FoodRecognitionInput input() => FoodRecognitionInput(
    jpegBytes: jpeg,
    mealType: 'lunch',
    notes: 'PRIVATE_NOTE',
  );
  test(
    'disabled, signed-out and mismatched restricted UID never request a token or send',
    () async {
      for (final c in [
        (false, 'owner', 'owner'),
        (true, 'owner', ''),
        (true, 'owner', 'other'),
      ]) {
        var calls = 0;
        final p = CloudflarePersonalFoodRecognitionProvider(
          enabled: c.$1,
          allowedUid: c.$2,
          currentUid: () => c.$3,
          idToken: () async {
            calls++;
            return 'test';
          },
          client: MockClient((_) async {
            calls++;
            return http.Response('{}', 200);
          }),
        );
        expect(p.isAvailable, false);
        await expectLater(
          p.recognize(input()),
          throwsA(isA<FoodRecognitionException>()),
        );
        expect(calls, 0);
      }
    },
  );
  test('an empty allow-list makes analysis available to any signed-in user', () {
    final p = CloudflarePersonalFoodRecognitionProvider(
      enabled: true,
      allowedUid: '',
      currentUid: () => 'someone',
      idToken: () async => 'test',
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    expect(p.isAvailable, true);
  });
  test(
    'owner JPEG sends no profile/notes and only reviewable candidate names return',
    () async {
      final p = CloudflarePersonalFoodRecognitionProvider(
        enabled: true,
        allowedUid: 'owner',
        currentUid: () => 'owner',
        idToken: () async => 'test-token',
        client: MockClient((r) async {
          expect(r.bodyBytes, jpeg);
          expect(r.headers['authorization'], 'Bearer test-token');
          expect(r.headers['content-type'], 'image/jpeg');
          expect(r.url.query, '');
          return http.Response(
            jsonEncode({
              'requiresUserReview': true,
              'items': [
                {
                  'name': 'rice',
                  'calories': 900,
                  'confidence': null,
                  'suggestedPortionGrams': null,
                },
              ],
            }),
            200,
          );
        }),
      );
      final r = await p.recognize(input());
      expect(r.requiresUserReview, true);
      expect(r.items.single.name, 'rice');
      expect(r.items.single.suggestedPortionGrams, null);
      expect(p.disclosureFor('ar'), contains('بريدك'));
      expect(p.processingDisclosure, contains('email'));
    },
  );
  test(
    'account change during token acquisition aborts before upload',
    () async {
      var uid = 'owner', sent = false;
      final p = CloudflarePersonalFoodRecognitionProvider(
        enabled: true,
        allowedUid: 'owner',
        currentUid: () => uid,
        idToken: () async {
          uid = 'other';
          return 'test';
        },
        client: MockClient((_) async {
          sent = true;
          return http.Response('{}', 200);
        }),
      );
      await expectLater(
        p.recognize(input()),
        throwsA(isA<FoodRecognitionException>()),
      );
      expect(sent, false);
    },
  );
  test(
    'limits, auth and malformed output fail closed for manual fallback',
    () async {
      for (final response in [
        http.Response('{}', 401),
        http.Response('{}', 429),
        http.Response('{}', 503),
        http.Response('bad', 200),
      ]) {
        final p = CloudflarePersonalFoodRecognitionProvider(
          enabled: true,
          allowedUid: 'owner',
          currentUid: () => 'owner',
          idToken: () async => 'test',
          client: MockClient((_) async => response),
        );
        await expectLater(
          p.recognize(input()),
          throwsA(isA<FoodRecognitionException>()),
        );
      }
    },
  );
}
