import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Separate paragraphs keep display-font Arabic shaping away from user names.
/// The same stacked layout is used at every width to avoid script collisions.
class WelcomeHeading extends StatelessWidget {
  const WelcomeHeading({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trimmed = name.trim();
    final greeting = trimmed.isEmpty
        ? l10n.welcomeTitleUnnamed
        : l10n.welcomeTitle('').trim();
    final style = context
        .displayStyle(size: 30)
        .copyWith(fontFamily: AppTheme.fontFamily, height: 1.4);
    return Semantics(
      header: true,
      label: trimmed.isEmpty ? greeting : l10n.welcomeTitle(trimmed),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(greeting, textAlign: TextAlign.center, style: style),
            if (trimmed.isNotEmpty)
              Text(
                trimmed,
                textAlign: TextAlign.center,
                // Each paragraph resolves its own first-strong script.
                style: style,
              ),
          ],
        ),
      ),
    );
  }
}
