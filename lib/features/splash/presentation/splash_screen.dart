import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nebula_background.dart';
import '../../../core/widgets/sufra_logo.dart';
import '../../../l10n/app_localizations.dart';

/// Screen 01 — Splash. Logo entrance and glow while the session state
/// resolves; the router redirect picks the real destination.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routePath = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else if (_controller.value < 1 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: MediaQuery.disableAnimationsOf(context)
                              ? 1.0
                              : 0.0,
                          end: 1,
                        ),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 1200),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Opacity(
                            // easeOutBack overshoots past 1.0.
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.7 + 0.3 * value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.turquoise.withValues(
                                  alpha: 0.55,
                                ),
                                blurRadius: 40,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: const SufraLogo(size: 200),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.appName,
                        style: context
                            .displayStyle(size: 44)
                            .copyWith(
                              fontFamily:
                                  Localizations.localeOf(
                                        context,
                                      ).languageCode ==
                                      'ar'
                                  ? 'SufraHeading'
                                  : 'SufraLatinDisplay',
                              fontWeight:
                                  Localizations.localeOf(
                                        context,
                                      ).languageCode ==
                                      'ar'
                                  ? FontWeight.w700
                                  : FontWeight.w800,
                            ),
                      ),
                      Text(
                        l10n.appTagline,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.cyanLight
                              : const Color(0xFF08718B),
                          fontFamily:
                              Localizations.localeOf(context).languageCode ==
                                  'ar'
                              ? 'SufraLight'
                              : 'SufraLatinScript',
                          fontFamilyFallback: const ['SufraBody', 'Cairo'],
                          fontSize: 16,
                          fontWeight:
                              Localizations.localeOf(context).languageCode ==
                                  'ar'
                              ? FontWeight.w100
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.splashBlessing,
                  style: context.accentStyle(
                    size: 22,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.orangeLight
                        : const Color(0xFF9A4800),
                  ).copyWith(
                    fontFamily:
                        Localizations.localeOf(context).languageCode == 'ar'
                        ? 'SufraCalligraphy'
                        : 'SufraBody',
                    fontWeight:
                        Localizations.localeOf(context).languageCode == 'ar'
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(60, 0, 60, 30),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      height: 4,
                      color: Colors.white.withValues(alpha: 0.12),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: 0.6 * _controller.value,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.turquoise,
                                      AppColors.aiPurple,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
