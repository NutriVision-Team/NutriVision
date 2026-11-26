import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A slow light sweep and gentle lift, without hiding content or intercepting taps.
/// Only the decorative overlay repaints every frame. Reduced motion is static.
class SufraLustre extends StatefulWidget {
  const SufraLustre({
    super.key,
    required this.child,
    this.radius = 24,
    this.float = false,
    this.color = const Color(0xFF67E8F9),
  });
  final Widget child;
  final double radius;
  final bool float;
  final Color color;
  @override
  State<SufraLustre> createState() => _SufraLustreState();
}

class _SufraLustreState extends State<SufraLustre>
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
      motion.value = .25;
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
    child: widget.child,
    builder: (context, child) => Transform.translate(
      offset: Offset(
        0,
        widget.float && !MediaQuery.disableAnimationsOf(context)
            ? math.sin(motion.value * math.pi * 2) * 2.5
            : 0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Stack(
          children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LustrePainter(motion.value, widget.color),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LustrePainter extends CustomPainter {
  const _LustrePainter(this.phase, this.color);
  final double phase;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width * (phase * 2.6 - .8);
    final rect = Rect.fromLTWH(
      center - size.width * .22,
      0,
      size.width * .44,
      size.height,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            color.withValues(alpha: .045),
            Colors.white.withValues(alpha: .11),
            Colors.transparent,
          ],
          stops: const [0, .35, .5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_LustrePainter old) =>
      phase != old.phase || color != old.color;
}
