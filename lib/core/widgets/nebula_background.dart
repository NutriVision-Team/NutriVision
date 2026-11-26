import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen background used by the first-journey screens.
///
/// Reproduces the design's composition: the `--neb` nebula photo
/// (assets/images/art/neb.jpg, extracted from the design HTML) painted with
/// BoxFit.cover over the dark base color, the design's dimmed overlay
/// (rgba(10,16,34,.22)), and the drifting blurred nebula blobs (`.b` drift
/// keyframes) on top of the photo, matching the HTML layering.
class NebulaBackground extends StatefulWidget {
  const NebulaBackground({super.key, required this.child, this.vector = false});

  final Widget child;
  final bool vector;

  @override
  State<NebulaBackground> createState() => _NebulaBackgroundState();
}

class _NebulaBackgroundState extends State<NebulaBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A route nested in the app host shares its full-viewport background.
    // Repainting another cover image inside each body creates seams at nav bars.
    if (context.dependOnInheritedWidgetOfExactType<_NebulaScope>() != null) {
      return widget.child;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return ColoredBox(
      color: base,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!isDark)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(.6, -1),
                  radius: 1.3,
                  colors: [Color(0xFFE3F2FD), Color(0xFFF5F7FA)],
                  stops: [0, .6],
                ),
              ),
            ),
          if (!isDark)
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-.6, -.4),
                    radius: .85,
                    colors: [Color(0x2267E8F9), Color(0x0067E8F9)],
                  ),
                ),
              ),
            ),
          if (!isDark)
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(.6, .4),
                    radius: .8,
                    colors: [Color(0x25A78BFA), Color(0x00A78BFA)],
                  ),
                ),
              ),
            ),
          if (isDark && widget.vector)
            const CustomPaint(painter: VectorNebulaPainter()),
          if (isDark && !widget.vector)
            // The design's --neb nebula photo, center/cover as in the HTML.
            Image.asset(
              'assets/images/art/neb.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          if (isDark)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _blob(
                      alignment: Alignment(
                        -0.85 + 0.15 * math.sin(t * math.pi),
                        -0.9,
                      ),
                      color: AppColors.aiPurple.withValues(alpha: 0.28),
                      size: 340,
                    ),
                    _blob(
                      alignment: Alignment(
                        0.9,
                        -0.2 + 0.2 * math.sin(t * math.pi + 1),
                      ),
                      color: AppColors.turquoise.withValues(alpha: 0.20),
                      size: 300,
                    ),
                    _blob(
                      alignment: Alignment(
                        -0.4,
                        0.85 - 0.15 * math.sin(t * math.pi + 2),
                      ),
                      color: AppColors.primaryBlue.withValues(alpha: 0.22),
                      size: 380,
                    ),
                  ],
                );
              },
            ),
          // Dimmed overlay matching the design's linear-gradient dim layer.
          IgnorePointer(
            child: ColoredBox(
              color: isDark
                  ? AppColors.darkBackground.withValues(alpha: 0.22)
                  : Colors.transparent,
            ),
          ),
          _NebulaScope(child: widget.child),
        ],
      ),
    );
  }

  Widget _blob({
    required Alignment alignment,
    required Color color,
    required double size,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Resolution-independent layered ribbons in the established brand colors.
class VectorNebulaPainter extends CustomPainter {
  const VectorNebulaPainter();
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 390, size.height / 844);
    for (final item in <(Color, Path)>[
      (
        AppColors.aiPurple,
        Path()
          ..moveTo(-80, -30)
          ..cubicTo(270, 20, 225, 90, 170, 151)
          ..cubicTo(95, 225, -75, 109, -60, 261),
      ),
      (
        AppColors.turquoise,
        Path()
          ..moveTo(404, -90)
          ..cubicTo(292, 107, 416, 138, 450, 258)
          ..cubicTo(482, 375, 349, 387, 340, 452),
      ),
      (
        AppColors.copper,
        Path()
          ..moveTo(466, 385)
          ..cubicTo(330, 493, 423, 529, 426, 645)
          ..cubicTo(428, 753, 313, 707, 270, 844),
      ),
      (
        AppColors.primaryBlue,
        Path()
          ..moveTo(-70, 366)
          ..cubicTo(98, 440, 31, 498, 33, 603)
          ..cubicTo(38, 713, 144, 694, 169, 878),
      ),
    ]) {
      c.drawPath(
        item.$2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 105
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [
              item.$1.withValues(alpha: .01),
              item.$1.withValues(alpha: .38),
              item.$1.withValues(alpha: .06),
            ],
          ).createShader(const Rect.fromLTWH(0, 0, 390, 844)),
      );
      c.drawPath(
        item.$2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = item.$1.withValues(alpha: .35),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(VectorNebulaPainter old) => false;
}

class _NebulaScope extends InheritedWidget {
  const _NebulaScope({required super.child});
  @override
  bool updateShouldNotify(_NebulaScope oldWidget) => false;
}
