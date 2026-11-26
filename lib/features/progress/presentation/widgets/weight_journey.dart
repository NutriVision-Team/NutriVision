import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';

/// The design's p-Weight journey path: a dashed full course toward the
/// goal flag, a solid glowing travelled portion, and the "you are here"
/// marker positioned by the actual goal fraction.
class WeightJourney extends StatelessWidget {
  const WeightJourney({
    super.key,
    required this.fraction,
    required this.currentLabel,
    required this.goalLabel,
    required this.hereLabel,
  });

  /// 0..1 travelled portion; 0 when unknown.
  final double fraction;
  final String currentLabel;
  final String goalLabel;
  final String hereLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: CustomPaint(
        painter: _JourneyPainter(
          fraction: fraction.clamp(0.0, 1.0),
          currentLabel: currentLabel,
          goalLabel: goalLabel,
          hereLabel: hereLabel,
          onSurface: Theme.of(context).colorScheme.onSurface,
          direction: Directionality.of(context),
          dark: Theme.of(context).brightness == Brightness.dark,
          muted: Theme.of(context).brightness == Brightness.dark
              ? AppColors.textMuted
              : AppColors.lightTextMuted,
        ),
      ),
    );
  }
}

class _JourneyPainter extends CustomPainter {
  _JourneyPainter({
    required this.fraction,
    required this.currentLabel,
    required this.goalLabel,
    required this.hereLabel,
    required this.onSurface,
    required this.muted,
    required this.direction,
    required this.dark,
  });

  final Color onSurface, muted;
  final TextDirection direction;
  final bool dark;
  final double fraction;
  final String currentLabel;
  final String goalLabel;
  final String hereLabel;

  static const Size _design = Size(350, 150);

  // Full course from the SVG: starts at the start dot (340,128) and
  // ends at the goal flag (30,28).
  static Path _course() {
    return Path()
      ..moveTo(340, 128)
      ..cubicTo(290, 128, 270, 96, 225, 98)
      ..cubicTo(150, 70, 150, 70, 110, 56)
      ..cubicTo(50, 30, 50, 30, 30, 28);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / _design.width).clamp(0.0, 10.0);
    canvas.save();
    canvas.scale(scale, size.height / _design.height);

    final course = _course();
    final metrics = course.computeMetrics().toList();
    if (metrics.isEmpty) {
      canvas.restore();
      return;
    }
    final metric = metrics.first;

    // Dashed remaining course.
    final dashPaint = Paint()
      ..color = onSurface.withValues(alpha: 0.35)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final m in course.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 1), dashPaint);
        d += 14;
      }
    }

    // Travelled glowing portion.
    final travelled = metric.extractPath(0, metric.length * fraction);
    canvas.drawPath(
      travelled,
      Paint()
        ..color = const Color(0xFF4ADE80)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
    );

    // Start dot (orange), current marker (turquoise, pulsing look via
    // halo), milestone dot.
    canvas.drawCircle(
      const Offset(340, 128),
      9,
      Paint()..color = const Color(0xFFFB8C00),
    );
    final here = metric.getTangentForOffset(metric.length * fraction);
    if (here != null) {
      canvas.drawCircle(
        here.position,
        18,
        Paint()..color = const Color(0x3306B6D4),
      );
      canvas.drawCircle(
        here.position,
        14,
        Paint()..color = const Color(0xFF06B6D4),
      );
    }
    // Goal flag.
    final flag = Path()
      ..moveTo(30, 28)
      ..lineTo(30, 8)
      ..lineTo(46, 14)
      ..lineTo(30, 20)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xFFFDBA74));

    _label(
      canvas,
      goalLabel,
      const Offset(52, 14),
      dark ? const Color(0xFFFDBA74) : const Color(0xFF985000),
      12,
      FontWeight.w700,
      TextAlign.left,
    );
    if (here != null) {
      final pos = here.position;
      _label(
        canvas,
        hereLabel,
        Offset(pos.dx, pos.dy - 30),
        dark ? const Color(0xFF67E8F9) : const Color(0xFF006A80),
        13,
        FontWeight.w700,
        TextAlign.center,
      );
    }
    _label(
      canvas,
      currentLabel,
      const Offset(110, 40),
      muted,
      11,
      FontWeight.w400,
      TextAlign.center,
    );

    canvas.restore();
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at,
    Color color,
    double size,
    FontWeight weight,
    TextAlign align,
  ) {
    if (text.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: color,
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      textDirection: direction,
      textAlign: align,
    )..layout();
    final dx = align == TextAlign.center ? at.dx - tp.width / 2 : at.dx;
    tp.paint(
      canvas,
      Offset(
        dx.clamp(4.0, _design.width - tp.width - 4),
        at.dy - tp.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_JourneyPainter oldDelegate) =>
      oldDelegate.dark != dark ||
      oldDelegate.direction != direction ||
      oldDelegate.onSurface != onSurface ||
      oldDelegate.muted != muted ||
      oldDelegate.fraction != fraction ||
      oldDelegate.currentLabel != currentLabel ||
      oldDelegate.goalLabel != goalLabel;
}
