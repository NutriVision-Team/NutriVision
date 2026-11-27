import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum CameraIssue { permissionDenied, unsupported, other }

/// Seam between the screen and the native scanner plugin so tests and the
/// pixel harness do not need a camera. The real implementation is
/// [MobileScannerCameraView].
abstract class BarcodeCameraController {
  Future<bool> toggleTorch();
}

typedef CameraViewBuilder =
    Widget Function(
      BuildContext context, {
      required ValueChanged<String> onCode,
      required ValueChanged<CameraIssue> onIssue,
      required ValueChanged<BarcodeCameraController> onReady,
    });

Widget mobileScannerCameraView(
  BuildContext context, {
  required ValueChanged<String> onCode,
  required ValueChanged<CameraIssue> onIssue,
  required ValueChanged<BarcodeCameraController> onReady,
}) =>
    MobileScannerCameraView(onCode: onCode, onIssue: onIssue, onReady: onReady);

/// NATIVE PATH, NOT EXERCISED in this environment: needs a real device.
class MobileScannerCameraView extends StatefulWidget {
  const MobileScannerCameraView({
    super.key,
    required this.onCode,
    required this.onIssue,
    required this.onReady,
  });
  final ValueChanged<String> onCode;
  final ValueChanged<CameraIssue> onIssue;
  final ValueChanged<BarcodeCameraController> onReady;

  @override
  State<MobileScannerCameraView> createState() =>
      _MobileScannerCameraViewState();
}

class _Torch implements BarcodeCameraController {
  _Torch(this.controller);
  final MobileScannerController controller;
  @override
  Future<bool> toggleTorch() async {
    await controller.toggleTorch();
    return controller.value.torchState == TorchState.on;
  }
}

class _MobileScannerCameraViewState extends State<MobileScannerCameraView>
    with WidgetsBindingObserver {
  bool _desiredActive = true;
  Future<void> _transition = Future.value();
  late final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
    ],
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.onReady(_Torch(_controller));
    _schedule(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _desiredActive = false;
    unawaited(
      _transition.catchError((Object _) {}).then((_) => _controller.dispose()),
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _schedule(state == AppLifecycleState.resumed);
  }

  void _schedule(bool active) {
    _desiredActive = active;
    _transition = _transition.then((_) async {
      if (!mounted) return;
      try {
        if (_desiredActive) {
          await _controller.start();
        } else {
          await _controller.stop();
        }
      } catch (_) {
        if (mounted && _desiredActive) widget.onIssue(CameraIssue.other);
      }
    });
  }

  @override
  Widget build(BuildContext context) => MobileScanner(
    controller: _controller,
    onDetect: (capture) {
      if (!mounted || !_desiredActive) return;
      for (final b in capture.barcodes) {
        final v = b.rawValue;
        if (v != null && v.isNotEmpty) {
          widget.onCode(v);
          break;
        }
      }
    },
    errorBuilder: (context, error) {
      final issue = switch (error.errorCode) {
        MobileScannerErrorCode.permissionDenied => CameraIssue.permissionDenied,
        MobileScannerErrorCode.unsupported => CameraIssue.unsupported,
        _ => CameraIssue.other,
      };
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onIssue(issue);
      });
      return const SizedBox.shrink();
    },
  );
}
