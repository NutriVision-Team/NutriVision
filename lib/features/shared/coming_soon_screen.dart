import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/nebula_background.dart';
import '../../core/widgets/sufra_logo.dart';
import '../../l10n/app_localizations.dart';

/// Honest destination for navigation targets scheduled for later
/// milestones, instead of dead buttons or empty routes.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  static const String routePath = '/coming-soon';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SufraLogo(size: 120),
                const SizedBox(height: 16),
                Text(
                  l10n.comingSoonTitle,
                  textAlign: TextAlign.center,
                  style: context.displayStyle(size: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.comingSoonBody,
                  textAlign: TextAlign.center,
                  style: context.mutedStyle(),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: l10n.wizardBack,
                  expand: false,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
