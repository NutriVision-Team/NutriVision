import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated water glass reproducing the design's p-Water SVG: tapered
/// glass outline, two layered wave fills, rising bubbles, highlight
/// streaks and measurement ticks.
class WaterGlass extends StatefulWidget {
  const WaterGlass({super.key, required this.fraction});

  /// 0..1 fill fraction of the glass.
  final double fraction;

  @override
  State<WaterGlass> createState() => _WaterGlassState();
}

class _WaterGlassState extends State<WaterGlass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _wave.stop();
    } else if (!_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 236 / 296,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: widget.fraction.clamp(0.0, 1.0)),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, fill, _) => AnimatedBuilder(
          animation: _wave,
          builder: (context, _) {
            return CustomPaint(
              painter: _GlassPainter(
                fraction: fill,
                phase: _wave.value,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({
    required this.fraction,
    required this.phase,
    required this.isDark,
  });

  final double fraction;
  final double phase;
  final bool isDark;

  static const Size _design = Size(236, 296);

  // The SVG glass silhouette: M44 20H192L178 262Q177 278 161 278H75Q59 278 58 262Z
  static Path _glassPath() {
    return Path()
      ..moveTo(44, 20)
      ..lineTo(192, 20)
      ..lineTo(178, 262)
      ..quadraticBezierTo(177, 278, 161, 278)
      ..lineTo(75, 278)
      ..quadraticBezierTo(59, 278, 58, 262)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / _design.width,
      size.height / _design.height,
    );
    canvas.save();
    canvas.translate(
      (size.width - _design.width * scale) / 2,
      (size.height - _design.height * scale) / 2,
    );
    canvas.scale(scale);

    final glass = _glassPath();
    final bounds = glass.getBounds();

    // Shadow ellipse under the glass.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(118, 286), width: 148, height: 14),
      Paint()..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
    );

    // Glass body tint.
    canvas.drawPath(
      glass,
      Paint()..color = const Color(0xFF7DD3FC).withValues(alpha: 0.12),
    );

    // Water fill: two waving layers clipped to the glass.
    canvas.save();
    canvas.clipPath(glass);
    final waterTop = bounds.bottom - bounds.height * fraction - 6;
    if (fraction > 0) {
      _waveLayer(
        canvas,
        bounds,
        waterTop + 6 * math.sin(phase * 2 * math.pi),
        8,
        phase,
        const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xBF22D3EE), Color(0xE61E40AF)],
        ),
      );
      _waveLayer(
        canvas,
        bounds,
        waterTop + 6 * math.sin(phase * 2 * math.pi + 1.4) + 4,
        10,
        phase + 0.35,
        const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7DD3FC), Color(0xFF0369A1)],
        ),
      );
      // Bubbles.
      final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
      final rng = math.Random(7);
      for (var i = 0; i < 10; i++) {
        final bx = bounds.left + 24 + rng.nextDouble() * (bounds.width - 48);
        final travel = (phase + i / 10) % 1.0;
        final by = bounds.bottom - 16 - travel * (bounds.height * fraction);
        if (by > waterTop + 8) {
          canvas.drawCircle(
            Offset(bx, by),
            1.6 + rng.nextDouble() * 2.2,
            bubblePaint,
          );
        }
      }
      // Bottom inner glow.
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(118, 268), width: 100, height: 14),
        Paint()..color = Colors.white.withValues(alpha: 0.12),
      );
    }
    canvas.restore();

    // Outline.
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF38BDF8),
    );

    // Highlight streaks.
    canvas.drawLine(
      const Offset(54, 30),
      const Offset(66, 250),
      Paint()
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0x8CFFFFFF), Color(0x00FFFFFF)],
        ).createShader(const Rect.fromLTWH(54, 30, 12, 220)),
    );
    canvas.drawLine(
      const Offset(178, 34),
      const Offset(172, 120),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.3),
    );

    // Measurement ticks.
    final tickPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.55)
          : const Color(0xFF0369A1).withValues(alpha: 0.7);
    for (final tick in const [
      [180.0, 80.0],
      [176.0, 130.0],
      [172.0, 180.0],
      [169.0, 230.0],
    ]) {
      canvas.drawLine(
        Offset(tick[0], tick[1]),
        Offset(tick[0] + 10, tick[1]),
        tickPaint,
      );
    }
    canvas.restore();
  }

  void _waveLayer(
    Canvas canvas,
    Rect bounds,
    double top,
    double amplitude,
    double phase,
    Gradient gradient,
  ) {
    final path = Path()..moveTo(bounds.left, bounds.bottom + 4);
    for (var x = bounds.left; x <= bounds.right; x += 4) {
      final y =
          top +
          amplitude *
              math.sin((x / bounds.width) * 2 * math.pi + phase * 2 * math.pi);
      path.lineTo(x, y);
    }
    path
      ..lineTo(bounds.right, bounds.bottom + 4)
      ..close();
    canvas.drawPath(path, Paint()..shader = gradient.createShader(bounds));
  }

  @override
  bool shouldRepaint(_GlassPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.phase != phase ||
      oldDelegate.isDark != isDark;
}
