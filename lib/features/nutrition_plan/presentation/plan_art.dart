import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative plan framing from the supplied design. These arcs are not
/// consumption progress or a measured weight trajectory.
class PlanCalorieRings extends CustomPainter {
  const PlanCalorieRings();
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final scale = size.shortestSide / 200;
    for (final ring in [
      (84.0, 14.0, const Color(0xFF67E8F9), 400 / 84),
      (62.0, 8.0, const Color(0xFFFDBA74), 260 / 62),
    ]) {
      final rect = Rect.fromCircle(center: center, radius: ring.$1 * scale);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.$2 * scale
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(
        center,
        ring.$1 * scale,
        paint..color = Colors.white.withValues(alpha: .1),
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        ring.$4,
        false,
        paint..color = ring.$3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PlanCalorieRings oldDelegate) => false;
}

/// A decorative route, intentionally excluded from semantics by its caller.
class PlanRouteArt extends CustomPainter {
  const PlanRouteArt();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 330, size.height / 64);
    final route = Path()
      ..moveTo(10, 50)
      ..cubicTo(80, 50, 110, 20, 170, 28)
      ..cubicTo(230, 36, 260, 14, 320, 12);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5
      ..color = Colors.white.withValues(alpha: .2);
    final metric = route.computeMetrics().first;
    for (double d = 0; d < metric.length; d += 12) {
      canvas.drawPath(metric.extractPath(d, math.min(d + 1, metric.length)), p);
    }
    canvas.drawPath(
      Path()
        ..moveTo(10, 50)
        ..cubicTo(80, 50, 110, 20, 170, 28),
      p
        ..color = const Color(0xFF4ADE80)
        ..strokeWidth = 6,
    );
    canvas.drawCircle(
      const Offset(10, 50),
      8,
      Paint()..color = const Color(0xFFFB8C00),
    );
    canvas.drawCircle(
      const Offset(170, 28),
      9,
      Paint()..color = const Color(0xFF06B6D4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(310, 30)
        ..lineTo(310, 2)
        ..lineTo(324, 7)
        ..lineTo(310, 12)
        ..close(),
      Paint()..color = const Color(0xFFFDBA74),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PlanRouteArt oldDelegate) => false;
}
