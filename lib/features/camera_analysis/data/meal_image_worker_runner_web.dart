// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'image_preparation_cancellation.dart';
import 'meal_image_codec.dart';

/// No main-thread codec fallback. Missing/blocked worker fails to manual entry.
Future<({Uint8List bytes, int width, int height})> prepareInImageWorker(
  Uint8List input, {
  ImagePreparationCancellation? cancellation,
}) async {
  cancellation?.check();
  html.Worker? worker;
  StreamSubscription<html.MessageEvent>? messages;
  StreamSubscription<html.Event>? errors;
  void Function()? removeCancel;
  final result = Completer<({Uint8List bytes, int width, int height})>();
  try {
    final uri = Uri.parse(
      html.document.baseUri!,
    ).resolve('meal_image_worker.js');
    worker = html.Worker(uri.toString());
    messages = worker.onMessage.listen((event) {
      if (result.isCompleted) return;
      final data = event.data;
      if (data is Map && data['error'] is String) {
        final failure = data['error'] == 'tooLarge'
            ? ImagePreparationFailure.tooLarge
            : ImagePreparationFailure.unsupported;
        result.completeError(ImagePreparationException(failure));
      } else if (data is Map &&
          data['bytes'] is ByteBuffer &&
          data['width'] is int &&
          data['height'] is int) {
        final bytes = Uint8List.view(data['bytes'] as ByteBuffer);
        final width = data['width'] as int, height = data['height'] as int;
        if (bytes.isEmpty ||
            bytes.length > MealImageCodec.maxOutputBytes ||
            width < 1 ||
            height < 1 ||
            width > MealImageCodec.maxSide ||
            height > MealImageCodec.maxSide) {
          result.completeError(
            const ImagePreparationException(
              ImagePreparationFailure.unsupported,
            ),
          );
        } else {
          result.complete((bytes: bytes, width: width, height: height));
        }
      } else {
        result.completeError(
          const ImagePreparationException(ImagePreparationFailure.unsupported),
        );
      }
    });
    errors = worker.onError.listen((event) {
      if (!result.isCompleted) {
        result.completeError(
          const ImagePreparationException(ImagePreparationFailure.unsupported),
        );
      }
    });
    removeCancel = cancellation?.onCancel(() {
      worker?.terminate();
      if (!result.isCompleted) {
        result.completeError(
          const ImagePreparationException(ImagePreparationFailure.cancelled),
        );
      }
    });
    cancellation?.check();
    // Structured cloning keeps source bytes owned by the caller intact.
    worker.postMessage(input.buffer);
    return await result.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        throw const ImagePreparationException(
          ImagePreparationFailure.unsupported,
        );
      },
    );
  } on ImagePreparationException {
    rethrow;
  } catch (_) {
    throw const ImagePreparationException(ImagePreparationFailure.unsupported);
  } finally {
    removeCancel?.call();
    await messages?.cancel();
    await errors?.cancel();
    worker?.terminate();
  }
}
