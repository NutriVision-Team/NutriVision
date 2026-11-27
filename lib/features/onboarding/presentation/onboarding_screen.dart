import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ordered_number_pair.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/layered_food_art.dart';
import '../../../core/widgets/nebula_background.dart';
import '../../../core/widgets/sufra_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/screens/login_screen.dart';

/// Three native pages. Positions follow the supplied 390 x 844 HTML canvas;
/// the page body scrolls on smaller screens or with large accessibility text.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.preferences});
  static const String routePath = '/onboarding';
  final AppPreferences preferences;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await widget.preferences.setOnboardingSeen();
    if (mounted) context.go(LoginScreen.routePath);
  }

  void _next() {
    if (_page == 2) {
      _finish();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(_page + 1);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      (l10n.onboarding1Title, l10n.onboarding1Body),
      (l10n.onboarding2Title, l10n.onboarding2Body),
      (l10n.onboarding3Title, l10n.onboarding3Body),
    ];
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                SizedBox(
                  height: 30,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Semantics(
                          button: true,
                          child: GestureDetector(
                            onTap: _finish,
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              l10n.onboardingSkip,
                              style: context.mutedStyle(),
                            ),
                          ),
                        ),
                        OrderedNumberPair(
                          key: const ValueKey('onboarding-counter'),
                          first: _page + 1,
                          second: 3,
                          style: context.mutedStyle(),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) {
                      final (title, body) = pages[index];
                      return SingleChildScrollView(
                        key: ValueKey('onboarding-page-$index-scroll'),
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            ArchImageContainer(
                              showShadow: false,
                              height:
                                  MediaQuery.textScalerOf(context).scale(15) >
                                      20
                                  ? 240
                                  : 382,
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: 350,
                                    height: 350,
                                    child: Center(
                                      child: LayeredFoodArt(
                                        asset:
                                            'assets/images/art/w${index + 1}.webp',
                                        hint: l10n.artRotateHint,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: context
                                  .displayStyle(size: 27)
                                  .copyWith(height: 1.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              body,
                              textAlign: TextAlign.center,
                              style: context
                                  .mutedStyle(size: 15)
                                  .copyWith(height: 29 / 15),
                            ),
                            const SizedBox(height: 12),
                            _PageDots(count: 3, index: index),
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                GradientButton(
                  label: _page == 2
                      ? l10n.onboardingStart
                      : l10n.onboardingNext,
                  onPressed: _next,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});
  final int count;
  final int index;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < count; i++)
        AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == index ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: i == index
                ? AppColors.turquoise
                : Colors.white.withValues(alpha: .3),
            boxShadow: i == index
                ? [
                    BoxShadow(
                      color: AppColors.turquoise.withValues(alpha: .8),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
    ],
  );
}
