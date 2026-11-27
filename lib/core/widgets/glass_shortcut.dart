import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'glass_highlight.dart';

/// Compact shortcut with existing glass surfaces and native focus/ink feedback.
/// Text remains unconstrained for accessibility and source labels stay intact.
class GlassShortcut extends StatefulWidget {
  const GlassShortcut({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.glossyInteraction = false,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool glossyInteraction;
  @override
  State<GlassShortcut> createState() => _GlassShortcutState();
}

class _GlassShortcutState extends State<GlassShortcut>
    with SingleTickerProviderStateMixin {
  bool _pressed = false, _hovered = false, _focused = false;
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  void _press(bool value) {
    setState(() => _pressed = value);
    if (value &&
        widget.glossyInteraction &&
        !MediaQuery.disableAnimationsOf(context)) {
      _wave.repeat();
    } else {
      _wave.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _wave.stop();
    } else if (_pressed && widget.glossyInteraction && !_wave.isAnimating) {
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final active =
        widget.glossyInteraction && (_hovered || _focused || _pressed);
    final ink = _pressed && widget.glossyInteraction
        ? Colors.white
        : dark
        ? AppColors.cyanLight
        : AppColors.primaryBlue;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    return AnimatedScale(
      scale: _pressed ? .97 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 120),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: (_pressed ? AppColors.turquoise : AppColors.copper)
                        .withValues(alpha: dark ? .38 : .24),
                    blurRadius: _pressed ? 18 : 24,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.glossyInteraction && _pressed
                    ? [
                        AppColors.primaryBlue,
                        AppColors.turquoise,
                        AppColors.blueDeep,
                      ]
                    : active
                    ? [
                        AppColors.orangeLight,
                        AppColors.copper,
                        AppColors.orangeDeep,
                      ]
                    : dark
                    ? [
                        Colors.white.withValues(alpha: .12),
                        Colors.white.withValues(alpha: .04),
                      ]
                    : [
                        Colors.white.withValues(alpha: .9),
                        AppColors.primaryBlue.withValues(alpha: .06),
                      ],
              ),
              border: Border.all(
                color: active
                    ? Colors.white.withValues(alpha: .6)
                    : ink.withValues(alpha: .28),
              ),
            ),
            child: InkWell(
              customBorder: shape,
              onHighlightChanged: _press,
              onHover: (value) => setState(() => _hovered = value),
              onFocusChange: (value) => setState(() => _focused = value),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onPressed();
              },
              child: AnimatedBuilder(
                animation: _wave,
                builder: (context, child) => CustomPaint(
                  foregroundPainter: _pressed && widget.glossyInteraction
                      ? _ShortcutWave(_wave.value)
                      : null,
                  child: child,
                ),
                child: GlassHighlight(
                  radius: 18,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 19, color: ink),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? (_pressed
                                          ? Colors.white
                                          : AppColors.darkBackground)
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutWave extends CustomPainter {
  const _ShortcutWave(this.phase);
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
    );
    for (var layer = 0; layer < 2; layer++) {
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width + 2; x += 2) {
        final y =
            size.height * .72 +
            math.sin(
                  x / size.width * math.pi * 2 +
                      phase * math.pi * 2 +
                      layer * 1.8,
                ) *
                6;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: layer == 0 ? 0.11 : 0.08),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShortcutWave old) => old.phase != phase;
}
