import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/features/health_coach/coach_access_host.dart';

void main() {
  for (final keyboard in [0.0, 300.0]) {
    testWidgets(
      'host preserves page bounds without floating obstruction keyboard$keyboard',
      (t) async {
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('Page')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await t.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(
                disableAnimations: true,
                viewInsets: EdgeInsets.only(bottom: keyboard),
              ),
              child: CoachAccessHost(
                router: router,
                enabled: true,
                child: child!,
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.byType(FloatingActionButton), findsNothing);
        final bounds = t.getRect(find.byType(Scaffold));
        expect(
          bounds.bottom,
          t.view.physicalSize.height / t.view.devicePixelRatio,
        );
        expect(bounds.left, 0);
        expect(
          bounds.width,
          t.view.physicalSize.width / t.view.devicePixelRatio,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
}
