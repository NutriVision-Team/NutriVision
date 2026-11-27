import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// A slow reflected-water caustic behind content, never a filter over letters.
class WaterGlass extends StatefulWidget {
  const WaterGlass({super.key, required this.child});
  final Widget child;
  @override
  State<WaterGlass> createState() => _WaterGlassState();
}

class _WaterGlassState extends State<WaterGlass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
      _motion.value = 0;
    } else if (!_motion.isAnimating && _motion.value < 1) {
      _motion.forward();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? [const Color(0x501D5268), const Color(0x480A1022)]
                  : [const Color(0x9EFFFFFF), const Color(0x6BDDFAFF)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: dark ? const Color(0x70C1F7FF) : const Color(0xC0FFFFFF),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30030B22),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _WaterReflection(_motion, dark),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _WaterReflection extends CustomPainter {
  _WaterReflection(this.motion, this.dark) : super(repaint: motion);
  final Animation<double> motion;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: dark ? .19 : .4);
    for (var line = 0; line < 3; line++) {
      final path = Path();
      for (var x = 0.0; x <= size.width; x += 4) {
        final y =
            3 +
            line * 2 +
            math.sin(
                  x / size.width * math.pi * 1.4 +
                      motion.value * math.pi * 2 +
                      line * .8,
                ) *
                1.5;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WaterReflection old) => old.dark != dark;
}
