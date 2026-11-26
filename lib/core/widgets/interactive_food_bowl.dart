import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'category_food_art.dart';

/// Decorative vector bowl. This is not a photograph of a catalog meal.
/// Matching editable artwork: assets/images/vector/food_bowl_illustration.svg.
class InteractiveFoodBowl extends StatefulWidget {
  const InteractiveFoodBowl({super.key, this.size = 116, this.category});
  final double size;
  final String? category;
  @override
  State<InteractiveFoodBowl> createState() => _InteractiveFoodBowlState();
}

class _InteractiveFoodBowlState extends State<InteractiveFoodBowl>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  Offset tilt = Offset.zero;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      motion.stop();
      tilt = Offset.zero;
    } else if (widget.size >= 80 && !motion.isAnimating) {
      motion.repeat();
    }
  }

  void update(Offset local) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(
      () => tilt = Offset(
        ((local.dx / widget.size) - .5).clamp(-.5, .5),
        ((local.dy / widget.size) - .5).clamp(-.5, .5),
      ),
    );
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: Localizations.localeOf(context).languageCode == 'ar'
        ? 'رسمة طعام تفاعلية، للزينة'
        : 'Interactive food bowl illustration, decorative',
    child: MouseRegion(
      onHover: (e) => update(e.localPosition),
      onExit: (_) => setState(() => tilt = Offset.zero),
      child: GestureDetector(
        onPanUpdate: (e) => update(e.localPosition),
        onPanEnd: (_) => setState(() => tilt = Offset.zero),
        onPanCancel: () => setState(() => tilt = Offset.zero),
        child: AnimatedBuilder(
          animation: motion,
          builder: (context, _) => Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, .001)
              ..rotateX(-tilt.dy * .2)
              ..rotateY(tilt.dx * .25),
            alignment: Alignment.center,
            child: CustomPaint(
              key: const ValueKey('interactive-vector-bowl'),
              size: Size.square(widget.size),
              painter: widget.category == null
                  ? FoodBowlPainter(phase: motion.value)
                  : CategoryFoodPainter(widget.category!, motion.value),
            ),
          ),
        ),
      ),
    ),
  );
}

class FoodBowlPainter extends CustomPainter {
  const FoodBowlPainter({required this.phase});
  final double phase;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 512, size.height / 512);
    Paint fill(Color color) => Paint()..color = color;
    Paint line(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    c.drawOval(
      const Rect.fromLTWH(186, 386, 140, 26),
      fill(AppColors.aiPurple.withValues(alpha: .45)),
    );
    final bowl = Path()
      ..moveTo(115, 238)
      ..cubicTo(124, 331, 165, 387, 255, 389)
      ..cubicTo(345, 387, 389, 333, 397, 238)
      ..close();
    c.drawPath(
      bowl,
      Paint()
        ..shader = AppColors.primaryGradient.createShader(
          const Rect.fromLTWH(110, 230, 290, 160),
        ),
    );
    c.drawPath(bowl, line(AppColors.cyanLight, 8));
    c.drawOval(
      const Rect.fromLTWH(108, 167, 296, 128),
      fill(AppColors.darkSurface),
    );
    final food = Path()
      ..moveTo(134, 225)
      ..cubicTo(147, 183, 189, 170, 224, 187)
      ..cubicTo(244, 146, 299, 151, 316, 188)
      ..cubicTo(359, 179, 383, 201, 378, 230)
      ..cubicTo(335, 276, 174, 279, 134, 225)
      ..close();
    c.drawPath(food, fill(AppColors.success));
    c.drawOval(
      const Rect.fromLTWH(108, 167, 296, 128),
      line(AppColors.cyanLight, 12),
    );
    for (final r in [
      const Rect.fromLTWH(246, 191, 32, 32),
      const Rect.fromLTWH(166, 223, 28, 28),
    ]) {
      c.drawOval(r, fill(AppColors.pinkLight));
    }
    for (final o in [const Offset(229, 227), const Offset(321, 234)]) {
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(math.pi / 4);
      c.drawRect(const Rect.fromLTWH(-12, -12, 24, 24), fill(AppColors.copper));
      c.restore();
    }
    final highlight = Path()
      ..moveTo(154, 274)
      ..cubicTo(164, 318, 187, 342, 222, 351);
    c.drawPath(highlight, line(AppColors.cyanLight.withValues(alpha: .8), 12));
    for (var i = 0; i < 3; i++) {
      final x = 173.0 + i * 82;
      final drift = math.sin(phase * math.pi * 2 + i) * 7;
      final steam = Path()
        ..moveTo(x, 155)
        ..cubicTo(x - 18 + drift, 128, x + 12 + drift, 120, x, 91);
      c.drawPath(steam, line(AppColors.cyanLight, 8));
    }
    for (final o in [const Offset(115, 150), const Offset(397, 155)]) {
      final star = Path()
        ..moveTo(o.dx, o.dy - 17)
        ..lineTo(o.dx + 5, o.dy - 5)
        ..lineTo(o.dx + 18, o.dy)
        ..lineTo(o.dx + 5, o.dy + 5)
        ..lineTo(o.dx, o.dy + 18)
        ..lineTo(o.dx - 5, o.dy + 5)
        ..lineTo(o.dx - 18, o.dy)
        ..lineTo(o.dx - 5, o.dy - 5)
        ..close();
      c.drawPath(
        star,
        fill(o.dx < 200 ? AppColors.aiPurple : AppColors.copper),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(FoodBowlPainter oldDelegate) => oldDelegate.phase != phase;
}
