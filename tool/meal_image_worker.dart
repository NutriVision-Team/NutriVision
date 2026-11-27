// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:sufradepi/features/camera_analysis/data/meal_image_codec.dart';

void main() {
  final scope =
      html.WorkerGlobalScope.instance as html.DedicatedWorkerGlobalScope;
  html.DedicatedWorkerGlobalScope.messageEvent.forTarget(scope).listen((event) {
    try {
      final data = event.data;
      if (data is! ByteBuffer) {
        throw const ImagePreparationException(
          ImagePreparationFailure.unsupported,
        );
      }
      final result = MealImageCodec.prepare(Uint8List.view(data));
      scope.postMessage(
        {
          'bytes': result.bytes.buffer,
          'width': result.width,
          'height': result.height,
        },
        [result.bytes.buffer],
      );
    } on ImagePreparationException catch (e) {
      scope.postMessage({'error': e.failure.name});
    } catch (_) {
      scope.postMessage({'error': 'unsupported'});
    }
  });
}
