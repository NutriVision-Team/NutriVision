import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/personalized_headings.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

void main() {
  for (final lang in ['ar', 'en']) {
    test(
      '$lang headings omit absent names without dangling punctuation',
      () async {
        final l = await AppLocalizations.delegate.load(Locale(lang));
        for (final name in ['', '   ']) {
          expect(
            planHeading(l, name),
            lang == 'ar' ? 'خطتك جاهزة!' : 'Your plan is ready!',
          );
          expect(
            welcomeHeading(l, name),
            lang == 'ar' ? 'أهلاً بيك' : 'Welcome',
          );
        }
        expect(planHeading(l, ' Noor '), l.planTitle('Noor'));
        expect(welcomeHeading(l, ' Noor '), l.welcomeTitle('Noor'));
      },
    );
  }
}
