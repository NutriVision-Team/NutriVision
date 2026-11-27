import 'dart:convert';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import '../../camera_analysis/data/meal_image_preparer.dart';

/// Browser-local per-account avatar, never sent to a server.
class LocalAvatarStore {
  const LocalAvatarStore({this.preparer = const MealImagePreparer()});
  final MealImagePreparer preparer;
  String _key(String uid) {
    if (uid.trim().isEmpty) throw ArgumentError('Missing owner');
    return 'sufra_avatar_${base64Url.encode(utf8.encode(uid))}';
  }

  Future<Uint8List?> readBytes(String uid) async {
    final encoded = web.window.localStorage.getItem(_key(uid));
    return encoded == null ? null : base64Decode(encoded);
  }

  Future<String?> read(String uid) async {
    final bytes = await readBytes(uid);
    return bytes == null
        ? null
        : 'data:image/jpeg;base64,${base64Encode(bytes)}';
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
      web.window.localStorage.setItem(_key(uid), base64Encode(prepared.bytes));
      if (!active()) throw StateError('Inactive account');
      return 'data:image/jpeg;base64,${base64Encode(prepared.bytes)}';
    } finally {
      await prepared.delete();
    }
  }
}
