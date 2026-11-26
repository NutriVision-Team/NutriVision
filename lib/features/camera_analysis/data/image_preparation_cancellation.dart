import 'meal_image_codec.dart';

/// One capture operation. Cancellation never authorizes a replacement upload.
class ImagePreparationCancellation {
  bool _cancelled = false;
  final Set<void Function()> _listeners = {};
  bool get isCancelled => _cancelled;
  void check() {
    if (_cancelled) {
      throw const ImagePreparationException(ImagePreparationFailure.cancelled);
    }
  }

  void Function() onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
    return () => _listeners.remove(listener);
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    final listeners = _listeners.toList();
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }
}
