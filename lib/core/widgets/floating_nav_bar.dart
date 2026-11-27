import 'package:go_router/go_router.dart';
import 'water_glass_surface.dart';
import 'sufra_button_response.dart';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class NavItem {
  const NavItem({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// Floating glass bottom navigation with the central Add button, matching
/// the design's sticky bar.
class FloatingGlassNavBar extends StatelessWidget {
  const FloatingGlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onAdd,
    this.showIcons = true,
    this.centerLabel,
    this.centerIcon = Icons.add,
    this.centerSelected = false,
  }) : assert(items.length == 4);

  /// Exactly four items; the central Add button sits between index 1 and 2.
  final List<NavItem> items;
  final int currentIndex;
  final VoidCallback onAdd;
  final bool showIcons;
  final String? centerLabel;
  final IconData centerIcon;
  final bool centerSelected;

  static double barHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(11);
    return scale > 15 ? 32 + (scale * 2 + 28) * 2 : 80;
  }

  static double contentClearance(BuildContext context) =>
      barHeight(context) + 36;

  @override
  Widget build(BuildContext context) {
    final large = largeLabel(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget add() => Center(
      child: SizedBox(
        width: 48,
        height: 48,
        child: _AddButton(
          onTap: onAdd,
          label:
              centerLabel ??
              (Localizations.localeOf(context).languageCode == 'ar'
                  ? 'إضافة وجبة'
                  : 'Add meal'),
          icon: centerIcon,
          selected: centerSelected,
        ),
      ),
    );
    return SizedBox(
      height: barHeight(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: dark ? const Color(0x55FFFFFF) : const Color(0x55C89B55),
              ),
              gradient: LinearGradient(
                colors: dark
                    ? [const Color(0xF01B2340), const Color(0xEB111A32)]
                    : [const Color(0xF5FFFFFF), const Color(0xEBE5F4FC)],
              ),
            ),
            child: WaterGlassSurface(
              radius: 26,
              child: large
                  ? Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _navItem(context, 0)),
                              Expanded(child: _navItem(context, 1)),
                              Expanded(child: add()),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _coachItem(context)),
                              Expanded(child: _navItem(context, 2)),
                              Expanded(child: _navItem(context, 3)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _navItem(context, 0)),
                        Expanded(child: _navItem(context, 1)),
                        Expanded(child: add()),
                        Expanded(child: _coachItem(context)),
                        Expanded(child: _navItem(context, 2)),
                        Expanded(child: _navItem(context, 3)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _coachItem(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Semantics(
      button: true,
      label: ar ? 'افتح مدربي الصحي' : 'Open my health coach',
      child: InkWell(
        onTap: () => GoRouter.maybeOf(context)?.go('/coach'),
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            child: largeLabel(context)
                ? Text(
                    ar ? 'المدرب' : 'Coach',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 20),
                      const SizedBox(height: 2),
                      Text(
                        ar ? 'المدرب' : 'Coach',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  bool largeLabel(BuildContext c) => MediaQuery.textScalerOf(c).scale(11) > 15;
  Widget _navItem(BuildContext context, int index) {
    final item = items[index];
    final selected = index == currentIndex;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (dark ? AppColors.cyanLight : const Color(0xFF006A80))
        : (Theme.of(context).brightness == Brightness.dark
              ? AppColors.textMuted
              : const Color(0xFF354562));
    return _NavPressFeedback(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          item.onTap();
        },
        child: Semantics(
          selected: selected,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.turquoise.withValues(alpha: dark ? .28 : .15),
                        AppColors.aiPurple.withValues(alpha: dark ? .20 : .08),
                      ],
                    )
                  : null,
              border: Border.all(
                color: selected
                    ? AppColors.cyanLight.withValues(alpha: .45)
                    : Colors.transparent,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              child:
                  largeLabel(context) && MediaQuery.sizeOf(context).width < 700
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: AnimatedDefaultTextStyle(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: color,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item.label,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showIcons) ...[
                          Icon(item.icon, size: 20, color: color),
                          const SizedBox(height: 2),
                        ],
                        AnimatedDefaultTextStyle(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: color,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
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

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.onTap,
    required this.label,
    required this.icon,
    required this.selected,
  });

  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _NavPressFeedback(
      central: true,
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          label: label,
          selected: selected,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: .28),
                    AppColors.aiPurple.withValues(alpha: .28),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x997C3AED),
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
                ],
                border: const Border.fromBorderSide(
                  BorderSide(color: Color(0xB3FFCC80), width: 1.5),
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}

/// Press animation does not change selection or defer a route action.
class _NavPressFeedback extends StatefulWidget {
  const _NavPressFeedback({required this.child, this.central = false});
  final Widget child;
  final bool central;
  @override
  State<_NavPressFeedback> createState() => _NavPressFeedbackState();
}

class _NavPressFeedbackState extends State<_NavPressFeedback> {
  bool pressed = false, hovered = false, focused = false;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final active = hovered || focused;
    final radius = widget.central ? 40.0 : 18.0;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Focus(
        canRequestFocus: false,
        onFocusChange: (v) => setState(() => focused = v),
        child: Listener(
          onPointerDown: (_) => setState(() => pressed = true),
          onPointerUp: (_) => setState(() => pressed = false),
          onPointerCancel: (_) => setState(() => pressed = false),
          child: AnimatedSlide(
            offset: active && !reduced ? const Offset(0, -.035) : Offset.zero,
            duration: reduced
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedScale(
              scale: pressed && !reduced ? .94 : 1,
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 120),
              child: AnimatedContainer(
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: active || pressed
                      ? [
                          BoxShadow(
                            color:
                                (pressed
                                        ? const Color(0xFF087CE5)
                                        : const Color(0xFFFF9B32))
                                    .withValues(alpha: .4),
                            blurRadius: widget.central ? 24 : 14,
                            spreadRadius: widget.central ? 2 : 0,
                          ),
                        ]
                      : [],
                ),
                child: _NavOrbit(
                  enabled: widget.central,
                  active: active || pressed,
                  pressed: pressed,
                  child: SufraButtonResponse(
                    radius: radius,
                    intensity: widget.central ? 1 : .22,
                    pressed: pressed,
                    hovered: active,
                    child: AnimatedRotation(
                      turns: widget.central && active && !reduced ? .025 : 0,
                      duration: reduced
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: widget.child,
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

/// A bounded orbit around the action lens. No idle ticker or input interception.
class _NavOrbit extends StatefulWidget {
  const _NavOrbit({
    required this.child,
    required this.enabled,
    required this.active,
    required this.pressed,
  });
  final Widget child;
  final bool enabled, active, pressed;
  @override
  State<_NavOrbit> createState() => _NavOrbitState();
}

class _NavOrbitState extends State<_NavOrbit>
    with SingleTickerProviderStateMixin {
  late final orbit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  void sync() {
    if (widget.enabled &&
        widget.active &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (!orbit.isAnimating) orbit.repeat();
    } else {
      orbit.stop();
      orbit.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didUpdateWidget(covariant _NavOrbit old) {
    super.didUpdateWidget(old);
    sync();
  }

  @override
  void dispose() {
    orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: orbit,
    builder: (_, child) => CustomPaint(
      foregroundPainter: widget.enabled
          ? _OrbitPainter(orbit.value, widget.active, widget.pressed)
          : null,
      child: child,
    ),
    child: widget.child,
  );
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter(this.phase, this.active, this.pressed);
  final double phase;
  final bool active, pressed;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x55FFD28A);
    canvas.drawCircle(c, r, base);
    if (!active) return;
    final color = pressed ? const Color(0xFF72EDFF) : const Color(0xFFFFCD7C);
    for (var i = 0; i < 2; i++) {
      final a = phase * math.pi * 2 + i * math.pi;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.4
        ..shader = SweepGradient(
          colors: [color.withValues(alpha: 0), color],
          startAngle: a,
          endAngle: a + 1.3,
          transform: const GradientRotation(0),
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, 1.3, false, p);
      canvas.drawCircle(
        c + Offset(math.cos(a + 1.3), math.sin(a + 1.3)) * r,
        2.2,
        Paint()..color = color,
      );
    }
    if (pressed) {
      final rr = r - 4 + math.sin(phase * math.pi) * 3;
      canvas.drawCircle(
        c,
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color.withValues(alpha: .4),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.phase != phase || old.active != active || old.pressed != pressed;
}
