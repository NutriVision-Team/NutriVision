import 'dart:math' as math;
import '../../../../core/widgets/dish_float.dart';
import '../../../../core/widgets/welcome_heading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/session_cubit.dart';

/// Screen 05 — Welcome. Shown once after registration before personal setup.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const String routePath = '/welcome';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<SessionCubit>().state;
    final name = switch (session) {
      SessionAuthenticated(:final profile) =>
        (profile?.displayName.isNotEmpty ?? false)
            ? profile!.displayName
            : (session.user.email?.split('@').first ?? ''),
      _ => '',
    };

    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 48).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      const _WelcomeArt(),
                      const SizedBox(height: 16),
                      WelcomeHeading(name: name),
                      const SizedBox(height: 12),
                      Text(
                        l10n.welcomeSubtitle,
                        textAlign: TextAlign.center,
                        style: context.mutedStyle(size: 15),
                      ),
                      const SizedBox(height: 18),
                      _EntrancePoint(
                        delay: const Duration(milliseconds: 400),
                        text: l10n.welcomePoint1,
                        color: AppColors.purpleLight,
                      ),
                      const SizedBox(height: 10),
                      _EntrancePoint(
                        delay: const Duration(milliseconds: 700),
                        text: l10n.welcomePoint2,
                        color: AppColors.cyanLight,
                      ),
                      const SizedBox(height: 10),
                      _EntrancePoint(
                        delay: const Duration(milliseconds: 1000),
                        text: l10n.welcomePoint3,
                        color: AppColors.orangeLight,
                      ),
                      const Spacer(),
                      const SizedBox(height: 16),
                      GradientButton(
                        label: l10n.welcomeCta,
                        onPressed: () => context.go('/setup'),
                      ),
                    ],
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

class _WelcomeArt extends StatefulWidget {
  const _WelcomeArt();

  @override
  State<_WelcomeArt> createState() => _WelcomeArtState();
}

class _WelcomeArtState extends State<_WelcomeArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 224,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 245,
            height: 155,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFDAA444).withValues(alpha: 0.25),
                  const Color(0xFF179B8F).withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  _ripple(t, AppColors.gold.withValues(alpha: 0.6)),
                  _ripple(
                    (t + 0.5) % 1.0,
                    const Color(0xFF37B9A7).withValues(alpha: 0.55),
                  ),
                ],
              );
            },
          ),
          IgnorePointer(
            child: DishFloat(
              child: Image.asset(
                'assets/images/art/hero_art.webp',
                width: double.infinity,
                height: 224,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ripple(double t, Color color) {
    return Container(
      width: 175 + 70 * t,
      height: 175 + 70 * t,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: (1 - t) * 0.6)),
      ),
    );
  }
}

class _EntrancePoint extends StatelessWidget {
  const _EntrancePoint({
    required this.delay,
    required this.text,
    required this.color,
  });

  final Duration delay;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final total = delay + const Duration(milliseconds: 900);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : total,
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final elapsed = value * total.inMilliseconds;
        final delayed = ((elapsed - delay.inMilliseconds) / 900).clamp(
          0.0,
          1.0,
        );
        return Opacity(
          opacity: delayed,
          child: Transform.translate(
            offset: Offset(0, 26 * (1 - delayed)),
            child: child,
          ),
        );
      },
      child: GlassCard(
        borderColor: AppColors.orangeLight.withValues(alpha: .5),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CustomPaint(
              size: const Size(30, 30),
              painter: _WelcomeStarPainter(color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two original outlined squares, one rotated45degrees, from the HTML SVG.
class _WelcomeStarPainter extends CustomPainter {
  const _WelcomeStarPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 20, size.height / 20);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRect(const Rect.fromLTWH(4, 4, 12, 12), paint);
    canvas.translate(10, 10);
    canvas.rotate(math.pi / 4);
    canvas.translate(-10, -10);
    canvas.drawRect(const Rect.fromLTWH(4, 4, 12, 12), paint);
  }

  @override
  bool shouldRepaint(covariant _WelcomeStarPainter oldDelegate) =>
      oldDelegate.color != color;
}
