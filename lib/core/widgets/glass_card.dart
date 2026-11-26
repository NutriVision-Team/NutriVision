import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass_highlight.dart';
import 'sufra_button_response.dart';

/// The design system's signature frosted-glass card.
///
/// Reproduces the HTML `.c` class: soft translucent gradient, subtle
/// luminous border, layered shadow and gentle entrance animation.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 24,
    this.gradient,
    this.borderColor,
    this.onTap,
    this.blur = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;

  /// Disable the backdrop blur on very low-end paths; blur is used
  /// selectively because excessive BackdropFilter hurts performance.
  final bool blur;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovered = false, _pressed = false;
  Widget get child => widget.child;
  EdgeInsetsGeometry get padding => widget.padding;
  EdgeInsetsGeometry? get margin => widget.margin;
  double get borderRadius => widget.borderRadius;
  Gradient? get gradient => widget.gradient;
  Color? get borderColor => widget.borderColor;
  VoidCallback? get onTap => widget.onTap;
  bool get blur => widget.blur;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final decoration = BoxDecoration(
      gradient:
          gradient ??
          (isDark
              ? AppColors.cardGradient
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xEBFFFFFF), Color(0xADFFFFFF)],
                )),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color:
            borderColor ??
            (_hovered
                ? AppColors.orangeLight
                : (isDark
                      ? AppColors.gold.withValues(alpha: 0.55)
                      : AppColors.goldDeep.withValues(alpha: 0.6))),
        width: _hovered ? 1.6 : 1.1,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF03081C).withValues(alpha: isDark ? 0.5 : 0.12),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: (_hovered ? AppColors.orangeDeep : AppColors.gold).withValues(
            alpha: _hovered ? 0.5 : (isDark ? 0.16 : 0.2),
          ),
          blurRadius: _hovered ? 24 : 12,
        ),
      ],
    );

    Widget content = Container(
      decoration: decoration,
      child: GlassHighlight(
        radius: borderRadius,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : SufraButtonResponse(
                radius: borderRadius,
                hovered: _hovered,
                pressed: _pressed,
                intensity: 0.8,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );

    if (blur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      content = Semantics(
        button: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            onHover: (v) => setState(() => _hovered = v),
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(borderRadius),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
