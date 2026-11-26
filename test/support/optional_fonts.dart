import 'dart:io';
import 'package:flutter/services.dart';

/// Optional: load an alternative local font directory for test renders.
/// Requires both SUFRA_*_FONT_FAMILY compile defines.
Future<void> loadPrivateReviewFonts() async {
  final directory = Platform.environment['SUFRA_PRIVATE_FONT_DIR'];
  if (directory == null) return;
  const body = String.fromEnvironment('SUFRA_FONT_FAMILY');
  const display = String.fromEnvironment('SUFRA_DISPLAY_FONT_FAMILY');
  if (body != 'Thmanyah Sans' || display != 'Thmanyah Sans') {
    throw StateError('Private review requires both font-family defines.');
  }
  final loader = FontLoader('Thmanyah Sans');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    final bytes = await File(
      '$directory/thmanyahsans-$weight.otf',
    ).readAsBytes();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}
