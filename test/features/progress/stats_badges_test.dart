import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/achievements/domain/achievement_activity.dart';
import 'package:sufradepi/features/progress/presentation/stats_achievement_card.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

class BadgeActivity implements AchievementActivityLoader {
  BadgeActivity({this.fail = false});
  final bool fail;
  @override
  Future<AchievementActivity> load(String uid) async {
    if (fail) throw StateError('Unavailable');
    return AchievementActivity(
      userId: uid,
      loggedDays: const {'2026-11-22'},
      mealCount: 1,
      distinctFoods: const {'rice'},
      mealTypesByDay: const {
        '2026-11-22': {'lunch'},
      },
      categoriesByDay: const {},
    );
  }
}

void main() {
  testWidgets('Stats uses genuine achievement activity and opens details', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: StatsAchievementCard(
              uid: 'u1',
              currentUid: () => 'u1',
              loader: BadgeActivity(),
            ),
          ),
        ),
        GoRoute(
          path: '/achievements',
          builder: (_, _) => const Scaffold(body: Text('details')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.dark(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('badges earned'), findsOneWidget);
    expect(find.text('Badge status not loaded yet'), findsNothing);
    await tester.tap(find.text('Badges'));
    await tester.pumpAndSettle();
    expect(find.text('details'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });
  testWidgets('failed badges never claim an earned result', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatsAchievementCard(
            uid: 'u1',
            currentUid: () => 'u1',
            loader: BadgeActivity(fail: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('badges earned'), findsNothing);
    expect(find.byType(TextButton), findsOneWidget);
  });
}
