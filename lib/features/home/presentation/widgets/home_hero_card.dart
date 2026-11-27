import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// The opening card of Home, from the design: chip, two-line headline, short
/// line and the plan button, with a floating dish on the opposite side.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final card = Container(
      constraints: const BoxConstraints(minHeight: 172),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x7AE2B159)),
        gradient: const LinearGradient(
          begin: Alignment(-.6, -1),
          end: Alignment(.6, 1),
          colors: [Color(0xF5071222), Color(0xD6094649), Color(0xE00F2331)],
          stops: [0, .58, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -16,
            right: -16,
            top: -16,
            bottom: -16,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(27),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-.68, -.64),
                      radius: .7,
                      colors: [Color(0x3BE2B159), Color(0x00E2B159)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -16,
            right: -16,
            top: -16,
            bottom: -16,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(27),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(.72, .56),
                      radius: .7,
                      colors: [Color(0x382AB49F), Color(0x002AB49F)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: 2,
            bottom: -8,
            child: IgnorePointer(child: _FloatingDish(reduceMotion: reduce)),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: .68,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: AppColors.goldGradient,
                    ),
                    child: Text(
                      l10n.homeHeroChip,
                      style: context.badgeStyle(
                        size: 11,
                        color: const Color(0xFF17212B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.homeHeroTitleA,
                    style: context
                        .readableDisplayStyle(size: 24)
                        .copyWith(height: 1.35),
                  ),
                  Text(
                    l10n.homeHeroTitleB,
                    style: context
                        .readableDisplayStyle(
                          size: 24,
                          color: const Color(0xFFF5C875),
                        )
                        .copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.homeHeroBody,
                    style: context.mutedStyle(size: 12).copyWith(height: 1.7),
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    button: true,
                    label: l10n.homeHeroCta,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: () => context.push('/planner'),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: AppColors.goldGradient,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4DC9973D),
                              blurRadius: 18,
                              offset: Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                l10n.homeHeroCta,
                                style: context.buttonStyle(
                                  size: 13,
                                  color: const Color(0xFF18232B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Icons.arrow_back_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 16,
                              color: const Color(0xFF18232B),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (reduce) return card;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: child,
        ),
      ),
      child: card,
    );
  }
}

class _FloatingDish extends StatefulWidget {
  const _FloatingDish({required this.reduceMotion});
  final bool reduceMotion;

  @override
  State<_FloatingDish> createState() => _FloatingDishState();
}

class _FloatingDishState extends State<_FloatingDish>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * Curves.easeInOut.transform(_c.value)),
        child: Transform.rotate(angle: -0.087, child: child),
      ),
      child: SizedBox(
        width: 142,
        height: 150,
        child: ClipRect(
          child: OverflowBox(
            minWidth: 142 * 4,
            maxWidth: 142 * 4,
            minHeight: 150 * 4,
            maxHeight: 150 * 4,
            child: Transform.translate(
              offset: Offset(-(3 - 1.5) * 142, -(0 - 1.5) * 150),
              child: Image.asset(
                'assets/images/art/spA.webp',
                width: 142 * 4,
                height: 150 * 4,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
