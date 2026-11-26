import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_accents.dart';
import '../theme/theme_cubit.dart';

/// Boundary around the app content (registered in app.dart) used to
/// snapshot the current interface for the circular reveal.
final GlobalKey sufraRootBoundaryKey = GlobalKey();
final Set<VoidCallback> _revealCancellations = {};
void cancelThemeReveals() {
  for (final cancel in List<VoidCallback>.of(_revealCancellations)) {
    cancel();
  }
}

/// Liquid theme switcher (master 5.3): animated sun/moon icon and a
/// circular reveal that expands from the actual toggle position until the
/// NEW theme covers the complete interface.
///
/// Robustness contract:
/// - Rapid repeated toggles: an in-flight reveal is completed instantly
///   and replaced; overlays never stack and cubit toggles never queue.
/// - Rotation: the overlay re-reads the screen size every frame and the
///   snapshot stretches; the reveal always reaches the farthest corner.
/// - Route transitions: the entry lives on the ROOT overlay, so it
///   survives navigation mid-animation.
/// - Reduced motion: honors MediaQuery.disableAnimations with an instant
///   toggle and no overlay.
/// - Disposal: the AnimationController, OverlayEntry and the ui.Image
///   snapshot are always released, including mid-animation disposal of
///   this widget.
class LiquidThemeButton extends StatefulWidget {
  const LiquidThemeButton({super.key, this.size = 40, this.capture});

  final Future<ui.Image> Function(RenderRepaintBoundary boundary)? capture;

  final double size;

  @override
  State<LiquidThemeButton> createState() => _LiquidThemeButtonState();
}

class _LiquidThemeButtonState extends State<LiquidThemeButton>
    with TickerProviderStateMixin {
  _RevealSession? _session;
  int _captureGeneration = 0;
  int _pendingToggles = 0;
  bool _applyPending(ThemeCubit cubit) {
    final count = _pendingToggles;
    _pendingToggles = 0;
    for (var i = 0; i < count; i++) {
      unawaited(cubit.toggle());
    }
    return count.isOdd;
  }

  @override
  void initState() {
    super.initState();
    _revealCancellations.add(_cancelCapture);
  }

  void _cancelCapture() {
    _pendingToggles = 0;
    _captureGeneration++;
    _finishSession();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _applyPending(context.read<ThemeCubit>());
      _cancelCapture();
    }
  }

  /// Idempotently finishes any in-flight reveal: removes the overlay and
  /// releases the controller and snapshot. Safe to call from anywhere.
  void _finishSession() {
    final session = _session;
    _session = null;
    if (session == null) return;
    session.entry.remove();
    session.controller.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      session.image.dispose();
      session.entry.dispose();
    });
  }

  @override
  void dispose() {
    _revealCancellations.remove(_cancelCapture);
    _cancelCapture();
    super.dispose();
  }

  Future<void> _toggle() async {
    unawaited(HapticFeedback.selectionClick());
    final generation = ++_captureGeneration;
    _pendingToggles++;
    final cubit = context.read<ThemeCubit>();
    if (cubit.state.mode == ThemeMode.system) {
      unawaited(
        cubit.setMode(
          Theme.of(context).brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
        ),
      );
    }
    // Rapid-toggle safety: complete the previous reveal instantly. The
    // theme underneath was already switched when that reveal started.
    _finishSession();

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _applyPending(cubit);
      return;
    }

    final boundary = sufraRootBoundaryKey.currentContext?.findRenderObject();
    final box = context.findRenderObject() as RenderBox?;
    final overlayState = Overlay.of(context, rootOverlay: true);
    if (boundary is! RenderRepaintBoundary || box == null) {
      _applyPending(cubit);
      return;
    }

    // Snapshot the CURRENT (old-theme) interface; the new theme builds
    // underneath and is revealed through the expanding circular hole.
    final ui.Image image;
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || generation != _captureGeneration) return;
      image = await (widget.capture?.call(boundary) ?? boundary.toImage());
    } catch (_) {
      if (mounted && generation == _captureGeneration) {
        _applyPending(cubit);
      }
      return;
    }
    if (!mounted ||
        generation != _captureGeneration ||
        !overlayState.mounted ||
        !box.attached) {
      image.dispose();
      return;
    }

    if (_pendingToggles.isEven) {
      _applyPending(cubit);
      image.dispose();
      return;
    }
    _finishSession();
    final overlayBox = overlayState.context.findRenderObject() as RenderBox;
    final center = overlayBox.globalToLocal(
      box.localToGlobal(box.size.center(Offset.zero)),
    );
    // Master 5.3 target duration: ~650-800ms.
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        if (_session?.entry != entry) return const SizedBox.shrink();
        return AnimatedBuilder(
          animation: controller,
          builder: (overlayContext, _) {
            if (_session?.entry != entry) return const SizedBox.shrink();
            // Re-read the size every frame so rotation mid-reveal still
            // covers the complete interface.
            final size = MediaQuery.of(overlayContext).size;
            final t = Curves.easeInOut.transform(controller.value);
            final radius = _distanceToFarthestCorner(center, size) * t;
            return IgnorePointer(
              child: ClipPath(
                clipper: _CircleHoleClipper(center, radius),
                child: RawImage(
                  image: image,
                  fit: BoxFit.fill,
                  width: size.width,
                  height: size.height,
                ),
              ),
            );
          },
        );
      },
    );

    _session = _RevealSession(
      entry: entry,
      controller: controller,
      image: image,
    );
    overlayState.insert(entry);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finishSession();
    });
    unawaited(controller.forward());

    // Switch the theme now: the snapshot hides the swap and the growing
    // hole reveals the new theme from the toggle position.
    _applyPending(cubit);
  }

  void _cycleAccent() {
    final brightness = Theme.of(context).brightness;
    final cubit = context.read<ThemeCubit>();
    final next = SufraAccents.next(
      cubit.accentIdFor(brightness).isEmpty
          ? (brightness == Brightness.dark
                ? SufraAccents.defaultDark.id
                : SufraAccents.defaultLight.id)
          : cubit.accentIdFor(brightness),
    );
    unawaited(HapticFeedback.selectionClick());
    unawaited(cubit.setAccent(brightness, next.id));
  }

  double _distanceToFarthestCorner(Offset point, Size screen) {
    final corners = [
      Offset.zero,
      Offset(screen.width, 0),
      Offset(0, screen.height),
      Offset(screen.width, screen.height),
    ];
    return corners.map((c) => (c - point).distance).reduce(math.max);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return IconButton(
      tooltip: Localizations.localeOf(context).languageCode == 'ar'
          ? (isDark ? 'الوضع النهاري' : 'الوضع الليلي')
          : (isDark ? 'Light mode' : 'Dark mode'),
      icon: AnimatedSwitcher(
        duration: reduced ? Duration.zero : const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => RotationTransition(
          turns: Tween(begin: 0.5, end: 1.0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          key: ValueKey(isDark),
          size: widget.size * 0.55,
        ),
      ),
      onPressed: _toggle,
      onLongPress: _cycleAccent,
    );
  }
}

class _RevealSession {
  const _RevealSession({
    required this.entry,
    required this.controller,
    required this.image,
  });

  final OverlayEntry entry;
  final AnimationController controller;
  final ui.Image image;
}

/// Full-screen clip with a circular hole at [center]: the old-theme
/// snapshot stays visible outside the hole while the new (live) theme
/// shows through it.
class _CircleHoleClipper extends CustomClipper<Path> {
  _CircleHoleClipper(this.center, this.radius);

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Offset.zero & size)
    ..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_CircleHoleClipper oldClipper) =>
      oldClipper.radius != radius || oldClipper.center != center;
}

/// Isolated accent control (master 5.3): one dot per catalog accent for
/// the CURRENT brightness. Choices persist independently per mode. Placed
/// wherever the integrator wants it; semantic colors are not selectable.
class AccentPalettePicker extends StatelessWidget {
  const AccentPalettePicker({super.key, this.dotSize = 28, this.named = false});

  final double dotSize;
  final bool named;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cubit = context.watch<ThemeCubit>();
    final activeId = cubit.accentIdFor(brightness).isEmpty
        ? (brightness == Brightness.dark
              ? SufraAccents.defaultDark.id
              : SufraAccents.defaultLight.id)
        : cubit.accentIdFor(brightness);
    if (!named) {
      return Wrap(
        alignment: WrapAlignment.center,
        children: [
          for (final option in SufraAccents.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Semantics(
                button: true,
                selected: option.id == activeId,
                label: Localizations.localeOf(context).languageCode == 'ar'
                    ? const {
                            'turquoise': 'فيروزي',
                            'blue': 'أزرق',
                            'purple': 'بنفسجي',
                            'copper': 'نحاسي',
                            'green': 'أخضر',
                          }[option.id] ??
                          option.id
                    : option.id,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    unawaited(cubit.setAccent(brightness, option.id));
                  },
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    width: dotSize < 44 ? 44 : dotSize,
                    height: dotSize < 44 ? 44 : dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: option.color,
                      border: Border.all(
                        color: option.id == activeId
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: option.id == activeId
                        ? Icon(
                            Icons.check,
                            size: dotSize * .55,
                            color: SufraAccents.onAccent(option.color),
                          )
                        : null,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final dark = brightness == Brightness.dark;
    final ink = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ar
              ? (dark
                    ? 'لون الأزرار والروابط في الوضع الداكن بس. الفاتح له اختيار مستقل.'
                    : 'لون الأزرار والروابط في الوضع الفاتح بس. الداكن له اختيار مستقل.')
              : (dark
                    ? 'Button and link color for dark mode. Light mode keeps its own choice.'
                    : 'Button and link color for light mode. Dark mode keeps its own choice.'),
          style: TextStyle(fontSize: 13, color: ink.withValues(alpha: .8)),
        ),
        const SizedBox(height: 14),
        for (final option in SufraAccents.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              selected: option.id == activeId,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('accent-${option.id}'),
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    unawaited(cubit.setAccent(brightness, option.id));
                  },
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: option.color.withValues(alpha: dark ? .15 : .08),
                      border: Border.all(
                        color: option.id == activeId
                            ? const Color(0xFFD99A35)
                            : ink.withValues(alpha: .16),
                        width: option.id == activeId ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            color: option.color,
                            shape: BoxShape.circle,
                          ),
                          child: option.id == activeId
                              ? Icon(
                                  Icons.check,
                                  size: dotSize * .65,
                                  color: SufraAccents.onAccent(option.color),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ar
                                ? const {
                                    'turquoise': 'فيروزي',
                                    'blue': 'أزرق',
                                    'purple': 'بنفسجي',
                                    'copper': 'نحاسي',
                                    'green': 'أخضر',
                                  }[option.id]!
                                : const {
                                    'turquoise': 'Turquoise',
                                    'blue': 'Blue',
                                    'purple': 'Purple',
                                    'copper': 'Copper',
                                    'green': 'Green',
                                  }[option.id]!,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
