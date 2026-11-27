import 'dart:typed_data';
import 'image_preparation_cancellation.dart';
import 'meal_image_codec.dart';

// VM-only support for shared-code unit tests. Never selected by a web build.
Future<({Uint8List bytes, int width, int height})> prepareInImageWorker(
  Uint8List input, {
  ImagePreparationCancellation? cancellation,
}) async {
  cancellation?.check();
  return MealImageCodec.prepare(input);
}
