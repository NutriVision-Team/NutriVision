import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Slow refracted highlights, painted behind content, never over text or taps.
/// One bounded paint pass per visible card; static when reduced motion is on.
class WaterGlassSurface extends StatefulWidget {
  const WaterGlassSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.tint = const Color(0xFF22D3EE),
  });
  final Widget child;
  final double radius;
  final Color tint;
  @override
  State<WaterGlassSurface> createState() => _WaterGlassSurfaceState();
}

class _WaterGlassSurfaceState extends State<WaterGlassSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
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
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(widget.radius),
    child: Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: motion,
                builder: (context, _) => CustomPaint(
                  painter: _WaterRefraction(motion.value, widget.tint),
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    ),
  );
}

class _WaterRefraction extends CustomPainter {
  const _WaterRefraction(this.phase, this.tint);
  final double phase;
  final Color tint;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    for (var layer = 0; layer < 2; layer++) {
      final path = Path();
      for (var i = 0; i <= 28; i++) {
        final x = size.width * i / 28;
        final y =
            size.height * (.18 + layer * .58) +
            math.sin(i / 28 * math.pi * 2 + phase * math.pi * 2 + layer) *
                size.height *
                .10;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      p.color = Colors.white.withValues(alpha: layer == 0 ? .15 : .06);
      canvas.drawPath(path, p);
    }
    final center = Offset(
      size.width * (.45 + .3 * math.sin(phase * math.pi * 2)),
      size.height * .15,
    );
    final rect = Rect.fromCircle(
      center: center,
      radius: size.longestSide * .65,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [tint.withValues(alpha: .12), Colors.transparent],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_WaterRefraction old) =>
      old.phase != phase || old.tint != tint;
}
