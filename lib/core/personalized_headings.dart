import '../l10n/app_localizations.dart';

String planHeading(AppLocalizations l, String name) =>
    name.trim().isEmpty ? l.planTitleUnnamed : l.planTitle(name.trim());

String welcomeHeading(AppLocalizations l, String name) =>
    name.trim().isEmpty ? l.welcomeTitleUnnamed : l.welcomeTitle(name.trim());
