import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Animated slim progress bar (`.bar` in the design).
class SufraProgressBar extends StatelessWidget {
  const SufraProgressBar({
    super.key,
    required this.fraction,
    this.gradient = const LinearGradient(
      colors: [AppColors.turquoise, AppColors.cyanLight],
    ),
    this.height = 9,
  });

  /// 0..1, values above 1 are clamped for display.
  final double fraction;
  final Gradient gradient;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: Colors.white.withValues(alpha: 0.12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Container(
                    width: constraints.maxWidth * value,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(height),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.turquoise.withValues(alpha: 0.7),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Animated calorie ring for daily progress.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.fraction,
    this.size = 150,
    this.strokeWidth = 12,
    this.child,
  });

  final double fraction;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(value, strokeWidth),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.strokeWidth);

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
      ..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, track);

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [AppColors.aiPurple, AppColors.turquoise, AppColors.cyanLight],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, progress);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}

/// One macro nutrient tile (protein / carbs / fat) as in the design.
class MacroTile extends StatelessWidget {
  const MacroTile({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.gradient,
  });

  final String label;
  final double? current;
  final double target;
  final Color color;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final fraction = target > 0 && current != null ? current! / target : 0.0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final large = MediaQuery.textScalerOf(context).scale(18) > 24;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final valueStyle = TextStyle(
      fontFamily: AppTheme.displayFontFamily,
      fontWeight: FontWeight.w700,
      fontSize: 18,
      color: Theme.of(context).colorScheme.onSurface,
    );
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: dark
              ? AppColors.cardGradient
              : const LinearGradient(colors: [Colors.white, Color(0xFFF0F4FA)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.2)
                : AppColors.lightTextMuted.withValues(alpha: .2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(height: 4),
            if (large) ...[
              Text(
                current?.round().toString() ?? '—',
                textDirection: TextDirection.ltr,
                style: valueStyle,
              ),
              Text(
                ar ? 'من' : 'of',
                style: TextStyle(
                  fontSize: 11,
                  color: dark ? AppColors.textMuted : AppColors.lightTextMuted,
                ),
              ),
              Text(
                target > 0 ? target.round().toString() : '—',
                textDirection: TextDirection.ltr,
                style: valueStyle,
              ),
            ] else
              Text(
                current != null
                    ? '${current!.round()}/${target > 0 ? target.round() : '—'}'
                    : '—',
                textDirection: TextDirection.ltr,
                style: valueStyle,
                maxLines: 1,
                softWrap: false,
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: dark ? AppColors.textMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 6),
            SufraProgressBar(
              fraction: fraction,
              height: 5,
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.5)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
