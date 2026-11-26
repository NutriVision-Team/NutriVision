import 'package:flutter/material.dart';

/// Keeps ordered quantities readable inside an otherwise RTL interface.
/// Callers provide values in meaning order: current/total or consumed/target.
class OrderedNumberPair extends StatelessWidget {
  const OrderedNumberPair({
    super.key,
    required this.first,
    required this.second,
    this.style,
  });
  final int first;
  final int second;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => Text(
    '$first / $second',
    key: const ValueKey('ordered-number-pair-text'),
    textDirection: TextDirection.ltr,
    style: style,
  );
}
