import 'dart:io';

Future<void> deleteCapture(String path) async {
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}
