import 'dart:math' as math;
import 'package:flutter/material.dart';

/// HTML's four-pixel dish float, scoped to hero art rather than scrolling lists.
class DishFloat extends StatefulWidget {
  const DishFloat({super.key, required this.child});
  final Widget child;
  @override
  State<DishFloat> createState() => _DishFloatState();
}

class _DishFloatState extends State<DishFloat>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      motion.stop();
      motion.value = 0;
    } else if (!motion.isAnimating) {
      motion.repeat();
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: motion,
    child: RepaintBoundary(child: widget.child),
    builder: (context, child) => Transform.translate(
      offset: Offset(0, -2 + 2 * math.cos(motion.value * math.pi * 2)),
      child: Transform.rotate(
        angle: math.sin(motion.value * math.pi * 2) * .012,
        child: child,
      ),
    ),
  );
}
