import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/camera_analysis/data/synthetic_firebase_recognition.dart';
import 'package:sufradepi/features/camera_analysis/data/synthetic_plate_fixture.dart';
import 'package:sufradepi/features/camera_analysis/domain/food_recognition_provider.dart';

void main() {
  FoodRecognitionInput fixture({String notes = ''}) => FoodRecognitionInput(
    jpegBytes: syntheticPlateFixture,
    mealType: 'lunch',
    notes: notes,
  );
  test('disabled provider makes no request', () async {
    var calls = 0;
    final p = SyntheticFirebaseFoodRecognitionProvider(
      catalogIds: {},
      send: (_) async {
        calls++;
        return '';
      },
    );
    expect(p.isAvailable, false);
    await expectLater(
      p.recognize(fixture()),
      throwsA(isA<FoodRecognitionException>()),
    );
    expect(calls, 0);
  });
  test(
    'only the bundled synthetic bytes are permitted, notes cannot leave',
    () async {
      var calls = 0;
      final p = SyntheticFirebaseFoodRecognitionProvider(
        enabled: true,
        catalogIds: {},
        send: (_) async {
          calls++;
          return '';
        },
      );
      await expectLater(
        p.recognize(
          FoodRecognitionInput(
            jpegBytes: Uint8List.fromList([1, 2, 3]),
            mealType: 'lunch',
          ),
        ),
        throwsA(isA<FoodRecognitionException>()),
      );
      await expectLater(
        p.recognize(fixture(notes: 'personal context')),
        throwsA(isA<FoodRecognitionException>()),
      );
      expect(calls, 0);
    },
  );
  test(
    'result remains review-only and ungrounded ids are removed; rate gate holds',
    () async {
      var calls = 0;
      final p = SyntheticFirebaseFoodRecognitionProvider(
        enabled: true,
        catalogIds: {'rice'},
        send: (_) async {
          calls++;
          return '{"requiresUserReview":true,"items":[{"name":"rice","matchedFoodId":"untrusted","confidence":0.5}]}';
        },
      );
      final r = await p.recognize(fixture());
      expect(r.requiresUserReview, true);
      expect(r.items.single.matchedFoodId, isNull);
      await expectLater(
        p.recognize(fixture()),
        throwsA(isA<FoodRecognitionException>()),
      );
      expect(calls, 1);
    },
  );
  test('malformed or nonreviewed result fails closed', () async {
    final p = SyntheticFirebaseFoodRecognitionProvider(
      enabled: true,
      catalogIds: {},
      send: (_) async => '{"requiresUserReview":false,"items":[]}',
    );
    await expectLater(
      p.recognize(fixture()),
      throwsA(
        isA<FoodRecognitionException>().having(
          (e) => e.failure,
          'failure',
          RecognitionFailure.invalidResponse,
        ),
      ),
    );
  });
  test('concurrent request cannot double-send', () async {
    final pending = Completer<String?>();
    var calls = 0;
    final p = SyntheticFirebaseFoodRecognitionProvider(
      enabled: true,
      catalogIds: {},
      send: (_) {
        calls++;
        return pending.future;
      },
    );
    final first = p.recognize(fixture());
    await expectLater(
      p.recognize(fixture()),
      throwsA(isA<FoodRecognitionException>()),
    );
    pending.complete('{"requiresUserReview":true,"items":[]}');
    await first;
    expect(calls, 1);
  });
}
