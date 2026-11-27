import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Goal-progress ring for the weight hero, faithful to the HTML design:
/// solid green (#4ADE80) rounded arc with a soft glow, white 14% track.
///
/// Feature-local on purpose: the shared core CalorieRing renders a
/// purple/cyan sweep gradient used by other features, and core widgets
/// are outside this feature's ownership.
class GoalRing extends StatelessWidget {
  const GoalRing({
    super.key,
    required this.fraction,
    this.size = 132,
    this.strokeWidth = 12,
    this.child,
  });

  final double fraction;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoalRingPainter(
          fraction.clamp(0.0, 1.0),
          strokeWidth,
          Theme.of(context).colorScheme.onSurface,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  _GoalRingPainter(this.fraction, this.strokeWidth, this.onSurface);
  final Color onSurface;

  final double fraction;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = onSurface.withValues(alpha: 0.14);
    canvas.drawCircle(center, radius, track);

    if (fraction > 0) {
      // Glow: a blurred copy of the arc only, so the ring stays hollow
      // (a shaped BoxShadow would fill the disc).
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = AppColors.greenLight.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, glow);

      final progress = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = AppColors.greenLight;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        progress,
      );
    }
  }

  @override
  bool shouldRepaint(_GoalRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.onSurface != onSurface;
}
