import 'package:flutter/material.dart';

/// The reference's upper reflected light and narrow inset rim. Text is never
/// filtered: the reflection sits behind the content and ignores input.
class GlassHighlight extends StatelessWidget {
  const GlassHighlight({
    super.key,
    required this.child,
    this.radius = 18,
    this.showBorder = true,
  });
  final Widget child;
  final double radius;
  final bool showBorder;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const RadialGradient(
                center: Alignment(-.4, -1.6),
                radius: 1.3,
                colors: [Color(0x70FFFFFF), Color(0x00FFFFFF)],
                stops: [0, .72],
              ),
              border: showBorder
                  ? Border.all(
                      color: Colors.white.withValues(alpha: .16),
                      width: .7,
                    )
                  : null,
            ),
          ),
        ),
      ),
      child,
    ],
  );
}
