import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../l10n/app_localizations.dart';

/// Screen 31 "سفرة بريميوم", UI only. The brief defers Premium: there is no
/// purchase, trial, price, restore or terms flow here, and the CTA is
/// permanently disabled. Design sample prices and the 7-day trial are
/// intentionally not shown.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final features = [
      (
        Icons.psychology_alt_rounded,
        l.premiumFeatureCoachTitle,
        l.premiumFeatureCoachBody,
        const Color(0xFF7C3AED),
      ),
      (
        Icons.insights_rounded,
        l.premiumFeatureReportsTitle,
        l.premiumFeatureReportsBody,
        const Color(0xFF06B6D4),
      ),
      (
        Icons.calendar_month_rounded,
        l.premiumFeaturePlanTitle,
        l.premiumFeaturePlanBody,
        const Color(0xFFFB8C00),
      ),
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NebulaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                  tooltip: l.premiumBack,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const SizedBox(height: 4),
              const _PremiumHero(),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  l.premiumTitle,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  l.premiumSubtitle,
                  style: context.mutedStyle(size: 14),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFB8C00).withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l.premiumComingSoonChip,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFFFB74D)
                          : const Color(0xFF8C4B00),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              for (final (i, f) in features.indexed)
                _FeatureArrival(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      borderColor: const Color(0x80FFB74D),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: f.$4.withValues(alpha: .22),
                            ),
                            child: Icon(f.$1, color: f.$4),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.$2,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(f.$3, style: context.mutedStyle(size: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              // Disabled on purpose: no purchase path exists.
              Semantics(
                button: true,
                enabled: false,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: .08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                  ),
                  child: Text(
                    l.premiumNotAvailable,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Native Flutter motion. The isolated hero has no purchase affordance.
class _PremiumHero extends StatefulWidget {
  const _PremiumHero();
  @override
  State<_PremiumHero> createState() => _PremiumHeroState();
}

class _PremiumHeroState extends State<_PremiumHero>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      motion.stop();
      motion.value = 0;
    } else if (!motion.isAnimating) {
      motion.repeat();
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final height = MediaQuery.textScalerOf(context).scale(1) > 1.3
        ? 210.0
        : 270.0;
    return Semantics(
      image: true,
      label: AppLocalizations.of(context).premiumTitle,
      child: SizedBox(
        height: height,
        child: AnimatedBuilder(
          animation: motion,
          child: Image.asset(
            'assets/images/art/premium_hero.png',
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          builder: (context, child) {
            final angle = motion.value * math.pi * 2;
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(
                            0xFFB98AFC,
                          ).withValues(alpha: dark ? .24 : .14),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PremiumOrbit(angle: angle, dark: dark),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Transform.translate(
                    offset: Offset(0, math.sin(angle) * 4),
                    child: Transform.rotate(
                      angle: math.sin(angle) * .012,
                      child: child,
                    ),
                  ),
                ),
                for (var i = 0; i < 3; i++)
                  Positioned(
                    left:
                        height * .47 +
                        math.cos(angle * .5 + i * 2.094) * height * .43,
                    top:
                        height * .45 +
                        math.sin(angle * .5 + i * 2.094) * height * .36,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: [
                          const Color(0xFFFFC65B),
                          const Color(0xFF8E6EF7),
                          const Color(0xFF19B9CF),
                        ][i],
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFC65B,
                            ).withValues(alpha: .3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PremiumOrbit extends CustomPainter {
  const _PremiumOrbit({required this.angle, required this.dark});
  final double angle;
  final bool dark;
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromCenter(
      center: s.center(Offset.zero),
      width: s.width * .9,
      height: s.height * .78,
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFFFB74D).withValues(alpha: dark ? .28 : .38);
    c.save();
    c.translate(s.width / 2, s.height / 2);
    c.rotate(-.22);
    c.translate(-s.width / 2, -s.height / 2);
    c.drawOval(r, p);
    p
      ..strokeWidth = 2.4
      ..shader = const LinearGradient(
        colors: [Colors.transparent, Color(0xFFFFD487), Colors.transparent],
      ).createShader(r);
    c.drawArc(r, angle, .8, false, p);
    c.restore();
  }

  @override
  bool shouldRepaint(_PremiumOrbit old) =>
      old.angle != angle || old.dark != dark;
}

class _FeatureArrival extends StatelessWidget {
  const _FeatureArrival({required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 650 + index * 180),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * (18 + index * 6)),
          child: child,
        ),
      ),
    );
  }
}
