import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 390.0, 800.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('Coach and original center action $lang $width $scale', (
          t,
        ) async {
          t.view.physicalSize = Size(width, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          var adds = 0;
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => Scaffold(
                  bottomNavigationBar: SafeArea(
                    child: FloatingGlassNavBar(
                      currentIndex: 0,
                      onAdd: () => adds++,
                      items: [
                        for (final label
                            in lang == 'ar'
                                ? ['الرئيسية', 'اليومية', 'تقدمي', 'حسابي']
                                : ['Home', 'Diary', 'Progress', 'Account'])
                          NavItem(label: label, icon: Icons.home, onTap: () {}),
                      ],
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: '/coach',
                builder: (_, _) => const Scaffold(body: Text('Coach route')),
              ),
            ],
          );
          addTearDown(router.dispose);
          await t.pumpWidget(
            MaterialApp.router(
              routerConfig: router,
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (c, ch) => MediaQuery(
                data: MediaQuery.of(c).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: ch!,
              ),
            ),
          );
          await t.pumpAndSettle();
          final coach = find.text(lang == 'ar' ? 'المدرب' : 'Coach');
          expect(coach.hitTestable(), findsOneWidget);
          final target = find
              .ancestor(of: coach, matching: find.byType(InkWell))
              .first;
          expect(t.getSize(target).height, greaterThanOrEqualTo(48));
          expect(t.getSize(target).width, greaterThanOrEqualTo(48));
          await t.tap(find.byIcon(Icons.add));
          expect(adds, 1);
          await t.tap(coach);
          await t.pumpAndSettle();
          expect(find.text('Coach route'), findsOneWidget);
          expect(t.takeException(), isNull);
        });
      }
    }
  }
}
