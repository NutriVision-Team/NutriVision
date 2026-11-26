import 'package:sufradepi/features/planner/domain/planner_food_choices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_tools_sheet.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

void main() {
  for (final entry in <(String, String)>[
    ('My weekly plan', '/planner'),
    ('My progress report', '/report'),
    ("Today's meals", '/diary'),
    ('Browse recipes', '/recipes'),
    ('Compare food alternatives', '/alternatives'),
  ]) {
    testWidgets('fixed local tool ${entry.$2} opens only after user tap', (
      t,
    ) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (c, s) => Scaffold(
              body: TextButton(
                onPressed: () => showCoachTools(
                  c,
                  foodChoices: const PlannerFoodChoices(
                    preferred: ['lentil'],
                    excluded: ['tuna'],
                  ),
                ),
                child: const Text('tools'),
              ),
            ),
          ),
          GoRoute(
            path: entry.$2,
            builder: (c, s) {
              if (entry.$2 == '/planner') {
                expect((s.extra! as PlannerFoodChoices).preferred, ['lentil']);
                expect((s.extra! as PlannerFoodChoices).excluded, ['tuna']);
              } else {
                expect(s.extra, isNull);
              }
              return Scaffold(body: Text('destination ${entry.$2}'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await t.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await t.tap(find.text('tools'));
      await t.pumpAndSettle();
      expect(find.textContaining('Only the question you type'), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/');
      await t.tap(find.text(entry.$1));
      await t.pumpAndSettle();
      expect(find.text('destination ${entry.$2}'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
