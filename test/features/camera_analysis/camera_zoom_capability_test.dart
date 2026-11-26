import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/camera_analysis/presentation/capture_device.dart';

void main() {
  test(
    'only unsupported zoom falls back to fixed1, capture need not fail',
    () async {
      expect(await cameraZoomOrOne(() async => 3.0), 3);
      expect(
        await cameraZoomOrOne(
          () async => throw PlatformException(code: 'zoomLevelNotSupported'),
        ),
        1,
      );
      expect(
        await cameraZoomOrOne(
          () async => throw CameraException('zoomLevelNotSupported', 'no zoom'),
        ),
        1,
      );
    },
  );
  test('permission and unexpected errors are never swallowed', () async {
    await expectLater(
      cameraZoomOrOne(
        () async => throw PlatformException(code: 'CameraAccessDenied'),
      ),
      throwsA(isA<PlatformException>()),
    );
    await expectLater(
      cameraZoomOrOne(() async => throw StateError('broken')),
      throwsStateError,
    );
  });
}
