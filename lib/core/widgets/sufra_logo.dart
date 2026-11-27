import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Original Sufra logo extracted from the supplied design HTML, with the
/// design's turquoise drop-shadow glow.
class SufraLogo extends StatelessWidget {
  const SufraLogo({super.key, this.size = 200, this.glow = true});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/sufra_logo.webp',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.restaurant_rounded,
        size: size * 0.6,
        color: AppColors.turquoise,
      ),
    );
  }
}

/// Circular artwork container used where the design shows food sprite art.
///
/// Decorative circular surface. Factual food imagery is bound separately by identity.
class FoodArtCircle extends StatelessWidget {
  const FoodArtCircle({
    super.key,
    this.size = 76,
    this.glowColor = AppColors.copper,
    this.child,
  });

  final double size;
  final Color glowColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF07102A),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.35),
            blurRadius: 22,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child:
          child ??
          Center(
            child: Icon(
              Icons.dinner_dining_rounded,
              size: size * 0.45,
              color: glowColor.withValues(alpha: 0.85),
            ),
          ),
    );
  }
}

/// Arch-shaped (mihrab) food image container from the design language.
class ArchImageContainer extends StatelessWidget {
  const ArchImageContainer({
    super.key,
    required this.child,
    this.height = 380,
    this.gradient,
    this.showShadow = true,
  });

  final bool showShadow;
  final Widget child;
  final double height;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(190),
          topRight: Radius.circular(190),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        gradient:
            gradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x597C3AED), Color(0x3306B6D4)],
            ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF03081C).withValues(alpha: 0.6),
                  blurRadius: 50,
                  offset: const Offset(0, 20),
                ),
              ]
            : [],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
