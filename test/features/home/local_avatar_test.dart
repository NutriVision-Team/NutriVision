import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:sufradepi/features/home/data/local_avatar_store.dart';
import 'package:sufradepi/features/camera_analysis/data/meal_image_preparer.dart';

void main() {
  test(
    'local avatar is account-separated, re-encoded, and never changes another account',
    () async {
      final dir = await Directory.systemTemp.createTemp('sufra-avatar-test');
      addTearDown(() => dir.delete(recursive: true));
      final input = File('${dir.path}/input.png')
        ..writeAsBytesSync(image.encodePng(image.Image(width: 20, height: 20)));
      final store = LocalAvatarStore(
        directory: dir,
        preparer: MealImagePreparer(temporaryDirectory: dir),
      );
      final path = await store.save('u1/a', input.path, active: () => true);
      expect(path.endsWith('.jpg'), true);
      expect(await store.read('u1/a'), path);
      expect(await store.read('u1?a'), isNull);
      expect(image.decodeJpg(await File(path).readAsBytes()), isNotNull);
      expect(await input.exists(), true);
    },
  );
  test('inactive account cannot start avatar save', () async {
    final dir = await Directory.systemTemp.createTemp('sufra-avatar-inactive');
    addTearDown(() => dir.delete(recursive: true));
    final store = LocalAvatarStore(
      directory: dir,
      preparer: MealImagePreparer(temporaryDirectory: dir),
    );
    await expectLater(
      store.save('u1', 'unused', active: () => false),
      throwsStateError,
    );
    expect(await store.read('u1'), isNull);
  });
}
