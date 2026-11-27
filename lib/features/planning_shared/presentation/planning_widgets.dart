import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nebula_background.dart';
import '../../../l10n/app_localizations.dart';

/// Shared building blocks for the planning features (planner, shopping,
/// coach, Ramadan). Feature-local: the lead owns shared core widgets.
extension PlanningLocalizations on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// True when the active locale is Arabic.
  Color get planningMuted => Theme.of(this).brightness == Brightness.dark
      ? AppColors.textMuted
      : AppColors.lightTextMuted;

  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}

/// Locale-aware number formatting (Arabic-Indic digits in Arabic).
String planningNumber(BuildContext context, num? value, {int decimals = 0}) {
  if (value == null || !value.isFinite) {
    return AppLocalizations.of(context).foodUnknown;
  }
  final locale = Localizations.localeOf(context).toLanguageTag();
  return NumberFormat(
    '#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}',
    locale,
  ).format(value);
}

/// Formats a grams amount the way the design does (جم، وكيلو من ١٠٠٠ جم).
String planningGrams(BuildContext context, double grams) {
  final l10n = AppLocalizations.of(context);
  if (grams >= 1000) {
    final kg = grams / 1000;
    return '${planningNumber(context, kg, decimals: kg == kg.roundToDouble() ? 0 : 1)} ${l10n.unitKg}';
  }
  return '${planningNumber(context, grams)} ${l10n.foodGramUnit}';
}

/// Standard scaffold for the planning screens: nebula background, safe area
/// and the floating glass navigation shared with the rest of the app.
class PlanningScaffold extends StatelessWidget {
  const PlanningScaffold({
    super.key,
    required this.child,
    required this.currentNavIndex,
    this.showNavigation = true,
    this.avoidNavigationOverlap = false,
  });

  final Widget child;

  /// 0 home, 1 diary, 2 progress, 3 account; -1 when none is active.
  final int currentNavIndex;
  final bool showNavigation;
  final bool avoidNavigationOverlap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NebulaBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                bottom:
                    avoidNavigationOverlap ||
                        MediaQuery.textScalerOf(context).scale(11) > 15
                    ? (showNavigation
                          ? FloatingGlassNavBar.contentClearance(context)
                          : 0)
                    : 0,
                child: child,
              ),
              if (showNavigation)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: FloatingGlassNavBar(
                    currentIndex: currentNavIndex,
                    onAdd: () => context.go('/log'),
                    items: [
                      NavItem(
                        label: l10n.navHome,
                        icon: Icons.home_outlined,
                        onTap: () => context.go('/home'),
                      ),
                      NavItem(
                        label: l10n.navDiary,
                        icon: Icons.book_outlined,
                        onTap: () => context.go('/diary'),
                      ),
                      NavItem(
                        label: l10n.navProgress,
                        icon: Icons.bar_chart,
                        onTap: () => context.go('/stats'),
                      ),
                      NavItem(
                        label: l10n.navAccount,
                        icon: Icons.person_outline,
                        onTap: () => context.go('/profile'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen title in the design's display face.
class PlanningTitle extends StatelessWidget {
  const PlanningTitle(this.text, {super.key, this.size = 28});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size,
          fontFamily: context.l10n.localeName == 'ar'
              ? 'Cairo'
              : AppTheme.displayFontFamily,
          fontWeight: FontWeight.w700,
          height: 1.6,
        ),
      ),
    );
  }
}

/// Scroll container matching the discovery screens' rhythm.
class PlanningList extends StatelessWidget {
  const PlanningList({super.key, required this.children, this.bottom = 120});

  final List<Widget> children;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 24, 16, bottom + 32),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => children[i],
    );
  }
}

/// Retry view for failed loads, wired to the shared state strings.
class PlanningError extends StatelessWidget {
  const PlanningError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.orangeLight,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(l10n.stateError),
          TextButton(onPressed: onRetry, child: Text(l10n.stateRetry)),
        ],
      ),
    );
  }
}

/// Entrance animation shared by planning cards; honors reduced motion.
class PlanningEntrance extends StatelessWidget {
  const PlanningEntrance({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 700 + index * 90),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Rounded glass shell from the HTML, with a neutral category symbol.
/// Catalog records have no verified photo binding, so do not imply that a
/// decorative sprite depicts the actual food or the complete meal.
class PlanningMealIcon extends StatelessWidget {
  const PlanningMealIcon({super.key, required this.icon, this.size = 44});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size + 6,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(size / 2),
        topRight: Radius.circular(size / 2),
        bottomLeft: const Radius.circular(10),
        bottomRight: const Radius.circular(10),
      ),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x33FFFFFF), Color(0x0AFFFFFF)],
      ),
      border: Border.all(color: const Color(0x38FFFFFF)),
    ),
    child: Icon(icon, size: size * 0.58, color: context.planningMuted),
  );
}

/// Category symbols, not asserted photos of a specific catalog food.
IconData planningIconFor(String category) => switch (category) {
  'eggs' => Icons.egg_outlined,
  'dairy' => Icons.water_drop_outlined,
  'fish' => Icons.set_meal_outlined,
  'grains' => Icons.grass_outlined,
  'vegetables' || 'fruits' => Icons.eco_outlined,
  'nuts_seeds' || 'legumes' => Icons.spa_outlined,
  'beverages' => Icons.local_drink_outlined,
  _ => Icons.restaurant_outlined,
};
