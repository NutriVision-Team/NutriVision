import 'dart:math';

/// One ID per explicit user operation, retained across ambiguous retries.
String newOperationId(String prefix) {
  final random = Random.secure();
  return '$prefix-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}
