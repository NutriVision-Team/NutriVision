import 'dart:io';
import 'package:sufradepi/features/auth/presentation/personal_educational_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/auth/presentation/owner_policy_consent.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

void main() {
  test(
    'personal default policy exactly matches owner-reviewed Arabic text',
    () {
      expect(personalEducationalPolicy.ready, isTrue);
      expect(personalEducationalPolicy.isLocal, isTrue);
      expect(
        personalEducationalPolicyTextAr,
        File('test/fixtures/consent_policy_ar.txt').readAsStringSync().trim(),
      );
      expect(
        personalEducationalPolicy.termsText,
        personalEducationalPolicy.privacyText,
      );
    },
  );
  const c = OwnerPolicyConfig(
    termsUrl: 'https://example.org/terms',
    termsVersion: 'v1',
    privacyUrl: 'https://example.org/privacy',
    privacyVersion: 'v1',
  );
  test(
    'absent/unsafe policy is closed, acceptance tied to all URLs and versions',
    () {
      final a = PolicyAcceptance();
      expect(OwnerPolicyConfig.absent.ready, isFalse);
      a.update(OwnerPolicyConfig.absent, true);
      expect(a.accepts(OwnerPolicyConfig.absent), isFalse);
      for (final url in [
        'http://example.org',
        'javascript:alert(1)',
        'https://user:pass@example.org',
        'https://example.invalid',
        'https://127.0.0.1',
        'https://localhost',
        'https://example.org/#token',
      ]) {
        expect(OwnerPolicyConfig.safeUri(url), isNull);
      }
      expect(a.accepts(c), isFalse);
      a.update(c, true);
      expect(a.accepts(c), isTrue);
      for (final changed in [
        const OwnerPolicyConfig(
          termsUrl: 'https://example.org/new',
          termsVersion: 'v1',
          privacyUrl: 'https://example.org/privacy',
          privacyVersion: 'v1',
        ),
        const OwnerPolicyConfig(
          termsUrl: 'https://example.org/terms',
          termsVersion: 'v2',
          privacyUrl: 'https://example.org/privacy',
          privacyVersion: 'v1',
        ),
        const OwnerPolicyConfig(
          termsUrl: 'https://example.org/terms',
          termsVersion: 'v1',
          privacyUrl: 'https://example.org/new',
          privacyVersion: 'v1',
        ),
        const OwnerPolicyConfig(
          termsUrl: 'https://example.org/terms',
          termsVersion: 'v1',
          privacyUrl: 'https://example.org/privacy',
          privacyVersion: 'v2',
        ),
      ]) {
        expect(a.accepts(changed), isFalse);
      }
      a.update(c, false);
      expect(a.accepts(c), isFalse);
    },
  );
  testWidgets(
    'links use injected external opener, unchecked voluntary consent resets on replacement',
    (t) async {
      final opened = <Uri>[];
      bool accepted = false;
      Future<void> pump(OwnerPolicyConfig config) async {
        await t.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: OwnerPolicyConsent(
                config: config,
                onChanged: (v) => accepted = v,
                opener: (u) async {
                  opened.add(u);
                  return false;
                },
              ),
            ),
          ),
        );
        await t.pump();
      }

      await pump(c);
      expect(
        t.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
      await t.tap(find.text('Terms'));
      await t.pump();
      expect(opened.single.toString(), c.termsUrl);
      expect(find.byWidgetPredicate((w) => w is SnackBar), findsOneWidget);
      expect(accepted, isFalse);
      await t.tap(find.byType(CheckboxListTile));
      await t.pump();
      expect(accepted, isTrue);
      await pump(
        const OwnerPolicyConfig(
          termsUrl: 'https://example.org/terms',
          termsVersion: 'v2',
          privacyUrl: 'https://example.org/privacy',
          privacyVersion: 'v1',
        ),
      );
      expect(
        t.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
      await pump(OwnerPolicyConfig.absent);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    },
  );
  test(
    'local documents require both contents and bind acceptance to content',
    () {
      const local = OwnerPolicyConfig(
        termsText: 'Educational terms',
        privacyText: 'Actual practices',
        termsVersion: '1',
        privacyVersion: '1',
      );
      final acceptance = PolicyAcceptance();
      expect(local.ready, isTrue);
      expect(OwnerPolicyConfig.absent.ready, isFalse);
      acceptance.update(local, true);
      expect(acceptance.accepts(local), isTrue);
      expect(
        acceptance.accepts(
          const OwnerPolicyConfig(
            termsText: 'Changed terms',
            privacyText: 'Actual practices',
            termsVersion: '1',
            privacyVersion: '1',
          ),
        ),
        isFalse,
      );
      expect(
        const OwnerPolicyConfig(
          termsText: 'Only terms',
          termsVersion: '1',
          privacyVersion: '1',
        ).ready,
        isFalse,
      );
      expect(
        const OwnerPolicyConfig(
          termsText: 'Terms',
          privacyText: 'Privacy',
          termsUrl: 'https://example.org',
          termsVersion: '1',
          privacyVersion: '1',
        ).ready,
        isFalse,
      );
    },
  );
  testWidgets(
    'local documents open in app without external request and consent resets',
    (t) async {
      const local = OwnerPolicyConfig(
        termsText: 'Educational terms content',
        privacyText: 'Actual privacy content',
        termsVersion: '1',
        privacyVersion: '1',
      );
      var external = 0;
      Future<void> pump(OwnerPolicyConfig config) async {
        await t.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: OwnerPolicyConsent(
                config: config,
                onChanged: (_) {},
                opener: (_) async {
                  external++;
                  return true;
                },
              ),
            ),
          ),
        );
        await t.pump();
      }

      await pump(local);
      expect(
        t.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
      await t.tap(find.text('Terms'));
      await t.pumpAndSettle();
      expect(find.text('Terms (1)'), findsOneWidget);
      expect(find.text('Educational terms content'), findsOneWidget);
      await t.tap(find.text('Close'));
      await t.pumpAndSettle();
      await t.tap(find.text('Privacy policy'));
      await t.pumpAndSettle();
      expect(find.text('Actual privacy content'), findsOneWidget);
      await t.tap(find.text('Close'));
      await t.pumpAndSettle();
      await t.tap(find.byType(CheckboxListTile));
      await t.pump();
      expect(
        t.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue,
      );
      await pump(
        const OwnerPolicyConfig(
          termsText: 'Changed',
          privacyText: 'Actual privacy content',
          termsVersion: '1',
          privacyVersion: '1',
        ),
      );
      expect(
        t.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
      expect(external, 0);
    },
  );
}
