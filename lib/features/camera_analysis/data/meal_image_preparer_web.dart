import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';

import 'meal_image_codec.dart';
import 'image_preparation_cancellation.dart';
import 'meal_image_worker_runner.dart';
export 'image_preparation_cancellation.dart';
export 'meal_image_codec.dart'
    show ImagePreparationFailure, ImagePreparationException;

class PreparedMealImage {
  const PreparedMealImage({
    required this.path,
    required this.bytes,
    required this.width,
    required this.height,
  });
  final String path;
  final Uint8List bytes;
  final int width, height;
  Future<void> delete() async {}
}

class MealImagePreparer {
  const MealImagePreparer();
  static const maxInputBytes = MealImageCodec.maxInputBytes;
  static const maxOutputBytes = MealImageCodec.maxOutputBytes;
  Future<PreparedMealImage> prepare(
    String sourcePath, {
    ImagePreparationCancellation? cancellation,
  }) async {
    cancellation?.check();
    try {
      final input = await XFile(sourcePath).readAsBytes();
      if (input.length > maxInputBytes) {
        throw const ImagePreparationException(ImagePreparationFailure.tooLarge);
      }
      cancellation?.check();
      final result = await prepareInImageWorker(
        input,
        cancellation: cancellation,
      );
      cancellation?.check();
      return PreparedMealImage(
        path: sourcePath,
        bytes: result.bytes,
        width: result.width,
        height: result.height,
      );
    } on ImagePreparationException {
      rethrow;
    } catch (_) {
      throw const ImagePreparationException(
        ImagePreparationFailure.unsupported,
      );
    }
  }
}
