import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A camera may support capture but expose no zoom capability.
Future<double> cameraZoomOrOne(Future<double> Function() read) async {
  try {
    return await read();
  } on PlatformException catch (e) {
    if (e.code == 'zoomLevelNotSupported') return 1;
    rethrow;
  } on CameraException catch (e) {
    if (e.code == 'zoomLevelNotSupported') return 1;
    rethrow;
  }
}

enum CaptureStatus {
  starting,
  ready,
  denied,
  restricted,
  unavailable,
  failed,
  paused,
}

abstract class CaptureDevice extends ChangeNotifier {
  CaptureStatus get status;
  double get minZoom;
  double get maxZoom;
  Widget preview();
  Future<void> initialize();
  Future<void> pause();
  Future<String> capture();
  Future<void> zoom(double value);
  Future<bool> flash(bool enabled);
}

class NativeCaptureDevice extends CaptureDevice {
  CameraController? _controller;
  CaptureStatus _status = CaptureStatus.starting;
  int _generation = 0;
  bool _disposed = false;
  double _minZoom = 1, _maxZoom = 1;
  @override
  CaptureStatus get status => _status;
  @override
  double get minZoom => _minZoom;
  @override
  double get maxZoom => _maxZoom;
  void _set(CaptureStatus value) {
    if (!_disposed) {
      _status = value;
      notifyListeners();
    }
  }

  @override
  Widget preview() {
    final c = _controller;
    return c != null && c.value.isInitialized
        ? CameraPreview(c)
        : const SizedBox.shrink();
  }

  @override
  Future<void> initialize() async {
    if (_disposed) return;
    final generation = ++_generation;
    final old = _controller;
    _controller = null;
    _set(CaptureStatus.starting);
    await old?.dispose();
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (_disposed || generation != _generation) return;
      if (cameras.isEmpty) {
        _set(CaptureStatus.unavailable);
        return;
      }
      final camera =
          cameras
              .where((v) => v.lensDirection == CameraLensDirection.back)
              .firstOrNull ??
          cameras.first;
      controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (_disposed || generation != _generation) {
        await controller.dispose();
        return;
      }
      _minZoom = await cameraZoomOrOne(controller.getMinZoomLevel);
      _maxZoom = await cameraZoomOrOne(controller.getMaxZoomLevel);
      if (_disposed || generation != _generation) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      _set(CaptureStatus.ready);
    } on CameraException catch (e) {
      await controller?.dispose();
      if (generation != _generation) return;
      _set(switch (e.code) {
        'CameraAccessDenied' => CaptureStatus.denied,
        'CameraAccessDeniedWithoutPrompt' ||
        'CameraAccessRestricted' => CaptureStatus.restricted,
        _ => CaptureStatus.failed,
      });
    } catch (_) {
      await controller?.dispose();
      if (generation == _generation) _set(CaptureStatus.failed);
    }
  }

  @override
  Future<void> pause() async {
    ++_generation;
    final old = _controller;
    _controller = null;
    _set(CaptureStatus.paused);
    await old?.dispose();
  }

  @override
  Future<String> capture() async {
    final c = _controller;
    if (status != CaptureStatus.ready || c == null || c.value.isTakingPicture) {
      throw StateError('Camera not ready');
    }
    return (await c.takePicture()).path;
  }

  @override
  Future<void> zoom(double value) async {
    if (status == CaptureStatus.ready) {
      await _controller?.setZoomLevel(value.clamp(minZoom, maxZoom));
    }
  }

  @override
  Future<bool> flash(bool enabled) async {
    try {
      if (status != CaptureStatus.ready) return false;
      await _controller?.setFlashMode(
        enabled ? FlashMode.torch : FlashMode.off,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    final old = _controller;
    _controller = null;
    old?.dispose();
    super.dispose();
  }
}
