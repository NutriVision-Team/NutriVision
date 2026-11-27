import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/app/back_guard.dart';

void main() {
  late GoRouter router;
  late int exits;
  var stepBackCalls = 0;
  var canStepBack = false;

  Future<void> pumpApp(WidgetTester t, String start) async {
    exits = 0;
    stepBackCalls = 0;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    Widget page(String n) => Scaffold(
      body: Center(
        child: TextButton(onPressed: () {}, child: Text(n)),
      ),
    );
    router = GoRouter(
      initialLocation: start,
      routes: [
        for (final p in [
          'home',
          'diary',
          'stats',
          'profile',
          'login',
          'register',
          'setup',
          'detail',
        ])
          GoRoute(path: '/$p', builder: (_, _) => page(p)),
      ],
    );
    addTearDown(router.dispose);
    await t.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (_, child) => BackGuard(
          router: router,
          stepBack: () {
            stepBackCalls++;
            return canStepBack;
          },
          child: child!,
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  String here() =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;

  testWidgets(
    'a tab reached with go returns to home, then home exits on a second press',
    (t) async {
      await pumpApp(t, '/home');
      router.go('/diary');
      await t.pumpAndSettle();
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(here(), '/home');
      expect(exits, 0);
      await t.binding.handlePopRoute();
      await t.pump();
      expect(exits, 0, reason: 'first press on home only warns');
      expect(find.text('Press back again to exit'), findsOneWidget);
      await t.binding.handlePopRoute();
      await t.pump();
      expect(exits, 1, reason: 'second press exits');
    },
  );

  testWidgets('pushed pages pop back first, then tab goes home', (t) async {
    await pumpApp(t, '/home');
    router.go('/stats');
    await t.pumpAndSettle();
    router.push('/detail');
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(here(), '/stats');
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(here(), '/home');
  });

  testWidgets('dialogs close before anything else', (t) async {
    await pumpApp(t, '/home');
    router.go('/profile');
    await t.pumpAndSettle();
    showDialog<void>(
      context: t.element(find.byType(Scaffold)),
      builder: (_) => const AlertDialog(title: Text('dlg')),
    );
    await t.pumpAndSettle();
    expect(find.text('dlg'), findsOneWidget);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('dlg'), findsNothing);
    expect(here(), '/profile');
  });

  testWidgets('bottom sheets close before anything else', (t) async {
    await pumpApp(t, '/home');
    router.go('/profile');
    await t.pumpAndSettle();
    showModalBottomSheet<void>(
      context: t.element(find.byType(Scaffold)),
      builder: (_) => const SizedBox(height: 200, child: Text('sheet')),
    );
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
    expect(here(), '/profile');
  });

  testWidgets('register goes to login; login exits', (t) async {
    await pumpApp(t, '/register');
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(here(), '/login');
    await t.binding.handlePopRoute();
    await t.pump();
    expect(exits, 1);
  });

  testWidgets('setup wizard steps back before leaving', (t) async {
    await pumpApp(t, '/setup');
    canStepBack = true;
    await t.binding.handlePopRoute();
    await t.pump();
    expect(stepBackCalls, 1);
    expect(exits, 0);
    canStepBack = false;
    await t.binding.handlePopRoute();
    await t.pump();
    expect(exits, 1);
  });
}
