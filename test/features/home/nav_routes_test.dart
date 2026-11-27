import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness;

void main() {
  for (final lang in ['ar', 'en']) {
    for (final path in ['/diary', '/stats', '/profile', '/log']) {
      testWidgets('Home nav route $lang $path', (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final h = await Harness.signedIn();
        await t.runAsync(() async {
          await t.pumpWidget(
            h.wrap(
              const HomeScreen(),
              locale: Locale(lang),
              additionalRoutes: [
                GoRoute(
                  path: path,
                  builder: (_, _) => Scaffold(body: Text('nav:$path')),
                ),
              ],
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 120));
        });
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        final nav = find.byType(FloatingGlassNavBar);
        final icon = switch (path) {
          '/diary' => Icons.calendar_today_rounded,
          '/stats' => Icons.show_chart_rounded,
          '/profile' => Icons.person_outline_rounded,
          _ => Icons.add,
        };
        await t.tap(find.descendant(of: nav, matching: find.byIcon(icon)));
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(find.text('nav:$path'), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await h.dispose();
      });
    }
  }
}
