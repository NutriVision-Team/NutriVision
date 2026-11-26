import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared response: orange hover and blue flowing press. Decorative only.
/// Motion is static when the platform requests reduced animation.
class SufraButtonResponse extends StatefulWidget {
  const SufraButtonResponse({
    super.key,
    required this.child,
    required this.pressed,
    required this.hovered,
    this.radius = 18,
    this.intensity = 1,
    this.overlay = false,
  });
  final Widget child;
  final bool pressed, hovered;
  final double radius;
  final double intensity;

  /// Paints the response over the child without clipping it, so outer
  /// shadows stay intact. Used for controls that carry their own shadow.
  final bool overlay;
  @override
  State<SufraButtonResponse> createState() => _SufraButtonResponseState();
}

class _SufraButtonResponseState extends State<SufraButtonResponse>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  void sync() {
    if (widget.pressed && !MediaQuery.disableAnimationsOf(context)) {
      if (!motion.isAnimating) motion.repeat();
    } else {
      motion.stop();
      motion.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didUpdateWidget(covariant SufraButtonResponse oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync();
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.overlay
      ? Stack(
          clipBehavior: Clip.none,
          fit: StackFit.passthrough,
          alignment: Alignment.center,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: widget.intensity * .6,
                  child: AnimatedBuilder(
                    animation: motion,
                    builder: (context, _) => CustomPaint(
                      painter: _ResponsePainter(
                        widget.pressed,
                        widget.hovered,
                        motion.value,
                        widget.radius,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      : ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: widget.intensity,
                    child: AnimatedBuilder(
                      animation: motion,
                      builder: (context, _) => CustomPaint(
                        painter: _ResponsePainter(
                          widget.pressed,
                          widget.hovered,
                          motion.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        );
}

class _ResponsePainter extends CustomPainter {
  const _ResponsePainter(this.pressed, this.hovered, this.phase, [this.radius]);
  final bool pressed, hovered;
  final double phase;
  final double? radius;
  @override
  void paint(Canvas canvas, Size size) {
    if (!pressed && !hovered) return;
    final rect = Offset.zero & size;
    if (radius != null) {
      canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius!)));
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: pressed
              ? const [Color(0xFF164AE5), Color(0xFF087CE5), Color(0xFF06B6D4)]
              : const [Color(0xFFB84409), Color(0xFFDD6817), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    if (pressed) {
      for (var n = 0; n < 2; n++) {
        final path = Path()..moveTo(0, size.height);
        for (var x = 0.0; x <= size.width; x += 3) {
          path.lineTo(
            x,
            size.height * (.4 + n * .23) +
                math.sin(
                      x / size.width * math.pi * 2 + phase * math.pi * 2 + n,
                    ) *
                    size.height *
                    .17,
          );
        }
        path
          ..lineTo(size.width, size.height)
          ..close();
        canvas.drawPath(
          path,
          Paint()..color = Colors.cyanAccent.withValues(alpha: .13 + n * .06),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ResponsePainter old) =>
      pressed != old.pressed || hovered != old.hovered || phase != old.phase;
}

/// Adds visual feedback without changing the child's action or focus behavior.
class SufraControlFeedback extends StatefulWidget {
  const SufraControlFeedback({
    super.key,
    required this.child,
    this.enabled = true,
    this.radius = 99,
    this.intensity = 1,
    this.overlay = false,
  });
  final bool overlay;
  final Widget child;
  final bool enabled;
  final double radius;
  final double intensity;
  @override
  State<SufraControlFeedback> createState() => _SufraControlFeedbackState();
}

class _SufraControlFeedbackState extends State<SufraControlFeedback> {
  bool hovered = false, pressed = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: widget.enabled ? (_) => setState(() => hovered = true) : null,
    onExit: (_) => setState(() => hovered = false),
    child: Listener(
      onPointerDown: widget.enabled
          ? (_) => setState(() => pressed = true)
          : null,
      onPointerUp: (_) => setState(() => pressed = false),
      onPointerCancel: (_) => setState(() => pressed = false),
      child: SufraButtonResponse(
        pressed: widget.enabled && pressed,
        hovered: widget.enabled && hovered,
        radius: widget.radius,
        intensity: widget.intensity,
        overlay: widget.overlay,
        child: widget.child,
      ),
    ),
  );
}
