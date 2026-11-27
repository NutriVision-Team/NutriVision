import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/health_coach/presentation/screens/coach_health_settings_screen.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

void main() {
  Widget app(void Function(HealthCoachProfile, HealthCoachConsent) save) =>
      MaterialApp(
        locale: const Locale('ar'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CoachHealthSettingsScreen(
          profile: const HealthCoachProfile(),
          consent: const HealthCoachConsent(),
          onSave: save,
        ),
      );
  testWidgets(
    'all fields optional, provider remains disabled and nothing durable',
    (tester) async {
      HealthCoachConsent? result;
      await tester.pumpWidget(
        app((p, c) {
          result = c;
          expect(p.age, isNull);
        }),
      );
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('save_health_choices'));
      await tester.scrollUntilVisible(
        save,
        400,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      final switches = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(switches.first.onChanged, isNull);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(result!.externalAi, false);
      expect(result!.durableMemory, false);
    },
  );
  testWidgets(
    'new built-in focus stores stable ID and free text is preserved',
    (tester) async {
      HealthCoachProfile? result;
      await tester.pumpWidget(app((p, c) => result = p));
      await tester.pumpAndSettle();
      final focus = find.text('تنويع الأكل');
      await tester.scrollUntilVisible(
        focus,
        300,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(focus);
      await tester.pumpAndSettle();
      await tester.tap(focus);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(
              find.ancestor(of: focus, matching: find.byType(FilterChip)),
            )
            .selected,
        true,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('health_goals')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('health_goals')),
        'هدفي الخاص',
      );
      final save = find.byKey(const ValueKey('save_health_choices'));
      await tester.scrollUntilVisible(
        save,
        400,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(result!.goals, ['food_variety', 'هدفي الخاص']);
    },
  );
  testWidgets('Arabic numeric input validates and uses session profile', (
    tester,
  ) async {
    HealthCoachProfile? result;
    await tester.pumpWidget(
      app((p, c) {
        result = p;
      }),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('health_age')), '٢٦');
    await tester.enterText(
      find.byKey(const ValueKey('health_height')),
      '١٧٥٫٥',
    );
    final save = find.byKey(const ValueKey('save_health_choices'));
    await tester.scrollUntilVisible(
      save,
      500,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(result!.age, 26);
    expect(result!.heightCm, 175.5);
  });
  testWidgets(
    'explicit focus chip updates session choice without enabling sharing',
    (tester) async {
      HealthCoachProfile? result;
      HealthCoachConsent? consent;
      await tester.pumpWidget(
        app((p, c) {
          result = p;
          consent = c;
        }),
      );
      await tester.scrollUntilVisible(
        find.text('تنويع الأكل'),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilterChip, 'تنويع الأكل'),
      );
      await tester.tap(find.widgetWithText(FilterChip, 'تنويع الأكل'));
      await tester.pump();
      final save = find.byKey(const ValueKey('save_health_choices'));
      await tester.scrollUntilVisible(
        save,
        400,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(result!.goals, contains('food_variety'));
      expect(consent!.externalAi, false);
      expect(consent!.durableMemory, false);
    },
  );
  testWidgets('budget and time are explicitly unsupported, not promised', (
    tester,
  ) async {
    await tester.pumpWidget(app((p, c) {}));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('health_budget')),
      400,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      find.textContaining('مطابقة الخطط بالأسعار لسه غير متاحة'),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('تصفية الوصفات بالوقت لسه غير متاحة'),
      findsOneWidget,
    );
  });
}
