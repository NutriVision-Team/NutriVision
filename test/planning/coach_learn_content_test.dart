import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/features/coach/domain/coach_learn_content.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_learn_article_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

void main() {
  test(
    'six bounded bilingual topics have observed official source and route',
    () {
      expect(coachLearnTopics.length, 6);
      expect(coachLearnTopics.map((t) => t.id).toSet().length, 6);
      for (final t in coachLearnTopics) {
        expect(t.sections.length, 2);
        expect(Uri.parse(t.sourceUrl).scheme, 'https');
        expect(
          {'www.nhs.uk', 'www.who.int'}.contains(Uri.parse(t.sourceUrl).host),
          true,
        );
        expect(
          {
            '/food-search',
            '/planner',
            '/water',
            '/recipes',
          }.contains(t.actionRoute),
          true,
        );
        for (final s in t.sections) {
          expect(s.bodyAr, isNotEmpty);
          expect(s.bodyEn, isNotEmpty);
        }
      }
    },
  );
  for (final lang in ['ar', 'en']) {
    testWidgets('all topic pages render, scroll and navigate in $lang at 2x', (
      t,
    ) async {
      for (final topic in coachLearnTopics) {
        bool opened = false;
        final router = GoRouter(
          initialLocation: '/learn',
          routes: [
            GoRoute(
              path: '/learn',
              builder: (_, __) => CoachLearnArticleScreen(topic: topic),
            ),
            GoRoute(
              path: topic.actionRoute,
              builder: (_, __) {
                opened = true;
                return const Scaffold(body: Text('Existing tool'));
              },
            ),
          ],
        );
        await t.pumpWidget(
          MaterialApp.router(
            key: UniqueKey(),
            routerConfig: router,
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (c, w) => MediaQuery(
              data: MediaQuery.of(c).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: w!,
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 300));
        expect(t.takeException(), isNull);
        final action = find.text(
          lang == 'ar' ? topic.actionAr : topic.actionEn,
        );
        await t.scrollUntilVisible(
          action,
          300,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await Scrollable.ensureVisible(
          t.element(action),
          duration: Duration.zero,
          alignment: .5,
        );
        await t.pump();
        await t.tap(action);
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(opened, true);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        router.dispose();
      }
    });
  }
}
