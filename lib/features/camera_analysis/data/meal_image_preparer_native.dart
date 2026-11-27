import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../../core/utils/operation_id.dart';

import 'meal_image_codec.dart';
import 'image_preparation_cancellation.dart';
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
  Future<void> delete() async {
    final file = File(path);
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      /* Already removed or no longer accessible. */
    }
  }
}

/// Re-encoding removes metadata and caps the bytes sent to a recognition provider.
class MealImagePreparer {
  const MealImagePreparer({this.temporaryDirectory});
  final Directory? temporaryDirectory;
  static const maxInputBytes = MealImageCodec.maxInputBytes;
  static const maxOutputBytes = MealImageCodec.maxOutputBytes;
  Future<PreparedMealImage> prepare(
    String sourcePath, {
    ImagePreparationCancellation? cancellation,
  }) async {
    cancellation?.check();
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const ImagePreparationException(ImagePreparationFailure.missing);
    }
    if (await source.length() > maxInputBytes) {
      throw const ImagePreparationException(ImagePreparationFailure.tooLarge);
    }
    final input = await source.readAsBytes();
    final result = await Isolate.run(() => MealImageCodec.prepare(input));
    cancellation?.check();
    final dir = temporaryDirectory ?? await getTemporaryDirectory();
    await dir.create(recursive: true);
    final file = File('${dir.path}/${newOperationId('meal-photo')}.jpg');
    await file.writeAsBytes(result.bytes, flush: true);
    if (cancellation?.isCancelled ?? false) {
      await file.delete();
      cancellation!.check();
    }
    return PreparedMealImage(
      path: file.path,
      bytes: result.bytes,
      width: result.width,
      height: result.height,
    );
  }
}
