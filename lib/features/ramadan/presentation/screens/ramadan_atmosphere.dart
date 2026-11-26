import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative crescent, suspended lanterns and stars. Never prayer-time data.
class RamadanAtmosphere extends StatefulWidget {
  const RamadanAtmosphere({super.key});
  @override
  State<RamadanAtmosphere> createState() => _RamadanAtmosphereState();
}

class _RamadanAtmosphereState extends State<RamadanAtmosphere>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      motion.stop();
      motion.value = .3;
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
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: motion,
          builder: (context, _) => CustomPaint(
            painter: _Atmosphere(
              motion.value,
              Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ),
      ),
    ),
  );
}

class _Atmosphere extends CustomPainter {
  const _Atmosphere(this.phase, this.dark);
  final double phase;
  final bool dark;
  @override
  void paint(Canvas c, Size s) {
    final gold = dark ? const Color(0xFFFDE68A) : const Color(0xFF9A530E);
    final p = Paint()
      ..color = gold.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var i = 0; i < 3; i++) {
      final anchor = Offset(s.width * [.13, .84, .94][i], 0);
      final length = [74.0, 62.0, 102.0][i];
      final angle = math.sin(phase * math.pi * 2 + i) * .045;
      c.save();
      c.translate(anchor.dx, anchor.dy);
      c.rotate(angle);
      c.drawLine(Offset.zero, Offset(0, length), p);
      c.drawCircle(Offset(0, length + 3), 3, p);
      final body = Path()
        ..moveTo(-7, length + 10)
        ..lineTo(-11, length + 20)
        ..lineTo(-8, length + 39)
        ..lineTo(8, length + 39)
        ..lineTo(11, length + 20)
        ..lineTo(7, length + 10)
        ..close();
      c.drawPath(body, Paint()..color = gold.withValues(alpha: .10));
      c.drawPath(body, p);
      c.drawLine(Offset(0, length + 11), Offset(0, length + 38), p);
      c.drawLine(Offset(-8, length + 41), Offset(8, length + 41), p);
      c.drawCircle(
        Offset(0, length + 25),
        4,
        Paint()
          ..color = gold.withValues(
            alpha: .30 + .16 * math.sin(phase * math.pi * 2 + i),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      c.restore();
    }
    for (var i = 0; i < 14; i++) {
      final x = s.width * ((i * .618 + .22) % 1), y = 20.0 + (i * 31 % 135);
      final alpha = .2 + .35 * (1 + math.sin(phase * math.pi * 2 + i)) / 2;
      c.drawCircle(
        Offset(x, y),
        i % 3 == 0 ? 1.7 : 1.0,
        Paint()..color = gold.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_Atmosphere old) => phase != old.phase || dark != old.dark;
}
