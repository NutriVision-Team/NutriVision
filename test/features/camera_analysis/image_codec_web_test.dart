import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sufradepi/features/camera_analysis/data/meal_image_codec.dart';

void main() {
  test(
    'actual browser codec produces provider-sized JPEG for synthetic high detail',
    () {
      final source = img.Image(width: 1600, height: 1200), r = Random(42);
      for (final p in source) {
        p.setRgb(r.nextInt(256), r.nextInt(256), r.nextInt(256));
      }
      final input = Uint8List.fromList(img.encodeJpg(source, quality: 82));
      final result = MealImageCodec.prepare(input);
      expect(input.length, 2807904);
      expect(result.bytes.length, 508579);
      expect(result.width, 675);
      expect(result.height, 506);
      expect(result.bytes.length, lessThanOrEqualTo(512 * 1024));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
