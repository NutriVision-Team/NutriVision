import 'dart:typed_data';
import 'package:image/image.dart' as img;

enum ImagePreparationFailure { tooLarge, unsupported, missing, cancelled }

class ImagePreparationException implements Exception {
  const ImagePreparationException(this.failure);
  final ImagePreparationFailure failure;
}

/// Same deterministic byte budget for native and web. No upload happens here.
abstract final class MealImageCodec {
  static const maxInputBytes = 20 * 1024 * 1024;
  static const maxOutputBytes = 512 * 1024;
  static const maxPixels = 24000000;
  static const maxSide = 1600;
  static const _qualities = [82, 70, 58];
  static ({Uint8List bytes, int width, int height}) prepare(Uint8List input) {
    if (input.length > maxInputBytes) {
      throw const ImagePreparationException(ImagePreparationFailure.tooLarge);
    }
    try {
      final decoder = img.findDecoderForData(input);
      final info = decoder?.startDecode(input);
      if (info == null) {
        throw const ImagePreparationException(
          ImagePreparationFailure.unsupported,
        );
      }
      if (info.width * info.height > maxPixels) {
        throw const ImagePreparationException(ImagePreparationFailure.tooLarge);
      }
      final decoded = decoder!.decodeFrame(0);
      if (decoded == null) {
        throw const ImagePreparationException(
          ImagePreparationFailure.unsupported,
        );
      }
      final upright = img.bakeOrientation(decoded);
      var side = maxSide;
      // Bounded work: at most 6 scales, 3 encodes each. Never lower below quality58.
      for (var scale = 0; scale < 6; scale++) {
        final resized = upright.width > side || upright.height > side
            ? img.copyResize(
                upright,
                width: upright.width >= upright.height ? side : null,
                height: upright.height > upright.width ? side : null,
              )
            : upright;
        // Fresh pixels, not a metadata-bearing clone. White background for alpha.
        final clean = img.Image(
          width: resized.width,
          height: resized.height,
          numChannels: 3,
        );
        img.fill(clean, color: img.ColorRgb8(255, 255, 255));
        img.compositeImage(clean, resized);
        for (final quality in _qualities) {
          final bytes = Uint8List.fromList(
            img.encodeJpg(clean, quality: quality),
          );
          if (bytes.length <= maxOutputBytes) {
            return (bytes: bytes, width: clean.width, height: clean.height);
          }
        }
        side = (side * .75).floor();
      }
      throw const ImagePreparationException(ImagePreparationFailure.tooLarge);
    } on ImagePreparationException {
      rethrow;
    } catch (_) {
      throw const ImagePreparationException(
        ImagePreparationFailure.unsupported,
      );
    }
  }
}
