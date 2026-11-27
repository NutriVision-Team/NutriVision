import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_accents.dart';
import '../theme/app_theme.dart';
import 'glass_highlight.dart';
import 'sufra_button_response.dart';

/// Primary gradient CTA (`.btn` in the design): blue→turquoise gradient,
/// rounded, with a subtle pressed scale and optional haptic feedback.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient = AppColors.primaryGradient,
    this.height = 54,
    this.expand = true,
    this.isLoading = false,
    this.textColor = Colors.white,
    this.fontSize = 17,
    this.borderRadius = 18,
    this.labelPadding = EdgeInsets.zero,
    this.labelAlign,
  });

  final String label;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final double height;
  final bool expand;
  final bool isLoading;
  final Color textColor;
  final double fontSize;
  final double borderRadius;
  final EdgeInsetsGeometry labelPadding;
  final TextAlign? labelAlign;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final colors = context.accentColors;
    final defaultAccent = Theme.of(context).brightness == Brightness.dark
        ? SufraAccents.defaultDark.color
        : SufraAccents.defaultLight.color;
    final customized =
        colors.accent != defaultAccent &&
        widget.gradient == AppColors.primaryGradient;
    final gradient = customized
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.accent,
              Color.lerp(colors.accent, Colors.white, .16)!,
            ],
          )
        : widget.gradient;
    final ink = customized ? colors.onAccent : widget.textColor;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: enabled,
      child: FocusableActionDetector(
        enabled: enabled,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (enabled) widget.onPressed!();
              return null;
            },
          ),
        },
        child: MouseRegion(
          onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: enabled
                ? () => setState(() => _pressed = false)
                : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onPressed!();
                  }
                : null,
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1,
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              child: AnimatedOpacity(
                opacity: enabled ? 1 : 0.6,
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                child: AnimatedContainer(
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  height: widget.height,
                  width: widget.expand ? double.infinity : null,
                  padding: widget.expand
                      ? null
                      : const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (customized ? colors.accent : AppColors.turquoise)
                                .withValues(alpha: 0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color:
                            (_hovered ? AppColors.orangeDeep : AppColors.gold)
                                .withValues(alpha: _hovered ? 0.7 : 0.38),
                        blurRadius: _hovered ? 26 : 14,
                        spreadRadius: _hovered ? 2 : 0,
                      ),
                    ],
                    border: Border.all(
                      color: _focused
                          ? Colors.white
                          : _hovered
                          ? AppColors.orangeLight
                          : AppColors.gold,
                      width: _focused
                          ? 2
                          : _hovered
                          ? 1.8
                          : 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: SufraButtonResponse(
                    radius: widget.borderRadius,
                    hovered: enabled && _hovered,
                    pressed: enabled && _pressed,
                    child: GlassHighlight(
                      radius: widget.borderRadius,
                      child: Center(
                        child: widget.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Padding(
                                padding: widget.labelPadding,
                                child: Text(
                                  widget.label,
                                  textAlign: widget.labelAlign,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: _pressed || _hovered
                                        ? Colors.white
                                        : ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: widget.fontSize,
                                  ),
                                ),
                              ),
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

/// Pill CTA with a circular gradient icon on the trailing side, used by the
/// login / register designs.
class IconPillButton extends StatelessWidget {
  const IconPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final colors = context.accentColors;
    final defaultAccent = Theme.of(context).brightness == Brightness.dark
        ? SufraAccents.defaultDark.color
        : SufraAccents.defaultLight.color;
    final customized = colors.accent != defaultAccent;
    final iconColor = customized ? colors.onAccent : Colors.white;
    return SufraControlFeedback(
      enabled: enabled,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.4,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150),
        child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onPressed!();
                  }
                : null,
            borderRadius: BorderRadius.circular(99),
            child: Ink(
              height: 64,
              padding: const EdgeInsetsDirectional.only(start: 8, end: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Row(
                textDirection: Directionality.of(context) == TextDirection.rtl
                    ? TextDirection.ltr
                    : TextDirection.rtl,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: customized
                          ? LinearGradient(
                              colors: [
                                colors.accent,
                                Color.lerp(colors.accent, Colors.white, .16)!,
                              ],
                            )
                          : AppColors.copperGradient,
                      boxShadow: [
                        BoxShadow(
                          color: (customized ? colors.accent : AppColors.copper)
                              .withValues(alpha: .6),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(13),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            color: iconColor,
                            textDirection: TextDirection.ltr,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass pill used for secondary providers (Google / phone) in auth screens.
class GlassPillButton extends StatelessWidget {
  const GlassPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.expand = false,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget? leading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = SufraControlFeedback(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(99),
          child: Ink(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 10)],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

/// Selectable chip matching the design's chip style (selected: AI gradient).
class SelectableSufraChip extends StatelessWidget {
  const SelectableSufraChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SufraControlFeedback(
      radius: 99,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.aiGradient : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
