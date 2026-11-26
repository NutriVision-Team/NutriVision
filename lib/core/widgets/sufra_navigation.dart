import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'floating_nav_bar.dart';
import '../../l10n/app_localizations.dart';

/// Stable destination order shared by all signed-in feature shells.
/// Indices: Home 0, Diary 1, Progress 2, Account 3. Same bar as the home screen.
class SufraNavigation extends StatelessWidget {
  const SufraNavigation({super.key, required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FloatingGlassNavBar(
      currentIndex: currentIndex,
      onAdd: () => context.go('/log'),
      items: [
        for (final item in [
          (l10n.navHome, Icons.home_rounded, '/home'),
          (l10n.navDiary, Icons.calendar_today_rounded, '/diary'),
          (l10n.navProgress, Icons.show_chart_rounded, '/stats'),
          (l10n.navAccount, Icons.person_outline_rounded, '/profile'),
        ])
          NavItem(
            label: item.$1,
            icon: item.$2,
            onTap: () => context.go(item.$3),
          ),
      ],
    );
  }
}
