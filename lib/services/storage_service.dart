import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile({
    required String path,
    required Uint8List data,
    String? contentType,
  }) async {
    final reference = _storage.ref().child(path);
    await reference.putData(data, SettableMetadata(contentType: contentType));
    return reference.getDownloadURL();
  }

  Future<void> deleteFile(String path) async {
    await _storage.ref(path).delete();
  }
}
