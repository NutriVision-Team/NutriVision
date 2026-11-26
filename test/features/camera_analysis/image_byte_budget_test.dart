import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sufradepi/features/camera_analysis/data/meal_image_codec.dart';
import 'package:sufradepi/features/camera_analysis/data/meal_image_preparer_native.dart'
    as native;
import 'package:sufradepi/features/camera_analysis/data/meal_image_preparer_web.dart'
    as web;

void main() {
  test('cancellation is idempotent and prevents preparation', () async {
    final cancellation = native.ImagePreparationCancellation();
    var calls = 0;
    cancellation.onCancel(() => calls++);
    final remove = cancellation.onCancel(() => calls += 100);
    remove();
    cancellation.cancel();
    cancellation.cancel();
    expect(calls, 1);
    cancellation.onCancel(() => calls++);
    expect(calls, 2);
    await expectLater(
      const native.MealImagePreparer().prepare(
        'not-read',
        cancellation: cancellation,
      ),
      throwsA(
        isA<ImagePreparationException>().having(
          (e) => e.failure,
          'failure',
          ImagePreparationFailure.cancelled,
        ),
      ),
    );
    await expectLater(
      const web.MealImagePreparer().prepare(
        'not-read',
        cancellation: cancellation,
      ),
      throwsA(
        isA<ImagePreparationException>().having(
          (e) => e.failure,
          'failure',
          ImagePreparationFailure.cancelled,
        ),
      ),
    );
  });
  test(
    'high-detail JPEG over provider cap becomes bounded, same native/web bytes and originals intact',
    () async {
      final image = img.Image(width: 1600, height: 1200), random = Random(42);
      for (final pixel in image) {
        pixel.setRgb(
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
        );
      }
      final input = Uint8List.fromList(img.encodeJpg(image, quality: 82));
      expect(input.length, greaterThan(MealImageCodec.maxOutputBytes));
      final expected = MealImageCodec.prepare(input);
      expect(
        expected.bytes.length,
        lessThanOrEqualTo(MealImageCodec.maxOutputBytes),
      );
      expect(expected.width, lessThan(1600));
      final dir = await Directory.systemTemp.createTemp('sufra-budget');
      try {
        final file = File('${dir.path}/original.jpg');
        await file.writeAsBytes(input);
        final n = await native.MealImagePreparer(
          temporaryDirectory: dir,
        ).prepare(file.path);
        final w = await web.MealImagePreparer().prepare(file.path);
        expect(n.bytes, expected.bytes);
        expect(w.bytes, expected.bytes);
        expect(n.width, w.width);
        expect(n.height, w.height);
        expect(await file.readAsBytes(), input);
        await n.delete();
        await w.delete();
        expect(await File(n.path).exists(), false);
        expect(await file.readAsBytes(), input);
        // Synthetic local evidence only, no photo leaves the device.
        debugPrint(
          'BUDGET input=${input.length},output=${n.bytes.length},size=${n.width}x${n.height}',
        );
      } finally {
        await dir.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
  test(
    'bakes rotation and strips EXIF description device and GPS metadata',
    () {
      final image = img.Image(width: 80, height: 40);
      img.fill(image, color: img.ColorRgb8(240, 30, 10));
      image.exif.imageIfd.orientation = 6;
      image.exif.imageIfd.make = 'Private synthetic device';
      image.exif.imageIfd.imageDescription = 'private synthetic note';
      image.exif.gpsIfd.gpsLatitude = 30.0;
      final result = MealImageCodec.prepare(
        Uint8List.fromList(img.encodeJpg(image)),
      );
      expect(result.width, 40);
      expect(result.height, 80);
      final decoded = img.decodeJpg(result.bytes)!;
      expect(decoded.exif.imageIfd.make, isNull);
      expect(decoded.exif.imageIfd.imageDescription, isNull);
      expect(decoded.exif.gpsIfd.gpsLatitude, isNull);
      expect(decoded.exif.imageIfd.orientation, isNull);
    },
  );
  test(
    'small images stay small and byte guard rejects oversized invalid input',
    () {
      final result = MealImageCodec.prepare(
        Uint8List.fromList(img.encodePng(img.Image(width: 60, height: 40))),
      );
      expect(result.width, 60);
      expect(result.height, 40);
      expect(
        () =>
            MealImageCodec.prepare(Uint8List(MealImageCodec.maxInputBytes + 1)),
        throwsA(
          isA<ImagePreparationException>().having(
            (e) => e.failure,
            'failure',
            ImagePreparationFailure.tooLarge,
          ),
        ),
      );
      expect(
        () => MealImageCodec.prepare(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<ImagePreparationException>()),
      );
    },
  );
}
