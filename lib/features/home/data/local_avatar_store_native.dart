import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../camera_analysis/data/meal_image_preparer.dart';

/// Local-only account avatar. Never written to Firestore or uploaded.
class LocalAvatarStore {
  const LocalAvatarStore({
    this.directory,
    this.preparer = const MealImagePreparer(),
  });
  final MealImagePreparer preparer;
  final Directory? directory;
  Future<File> _file(String uid) async {
    if (uid.trim().isEmpty) throw ArgumentError('Missing owner');
    final root = directory ?? await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/avatars');
    await dir.create(recursive: true);
    return File(
      '${dir.path}/${base64Url.encode(utf8.encode(uid)).replaceAll('=', '')}.jpg',
    );
  }

  Future<Uint8List?> readBytes(String uid) async {
    final path = await read(uid);
    return path == null ? null : File(path).readAsBytes();
  }

  Future<String?> read(String uid) async {
    final file = await _file(uid);
    return await file.exists() ? file.path : null;
  }

  Future<String> save(
    String uid,
    String source, {
    required bool Function() active,
  }) async {
    if (!active()) throw StateError('Inactive account');
    final prepared = await preparer.prepare(source);
    try {
      if (!active()) throw StateError('Inactive account');
      final file = await _file(uid);
      if (!active()) throw StateError('Inactive account');
      await file.writeAsBytes(prepared.bytes, flush: true);
      if (!active()) throw StateError('Inactive account');
      return file.path;
    } finally {
      await prepared.delete();
    }
  }
}
