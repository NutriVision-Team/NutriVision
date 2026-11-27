import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/glass_shortcut.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness;

void main() {
  testWidgets('shortcut presses, keyboard activation and reduced motion', (
    t,
  ) async {
    var count = 0;
    var reduced = false;
    late StateSetter update;
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: Scaffold(
                body: Center(
                  child: GlassShortcut(
                    label: 'Shortcut',
                    onPressed: () => count++,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    final target = find.byType(GlassShortcut);
    final gesture = await t.startGesture(t.getCenter(target));
    await t.pump(const Duration(milliseconds: 150));
    expect(
      t
          .widget<AnimatedScale>(
            find.descendant(of: target, matching: find.byType(AnimatedScale)),
          )
          .scale,
      .97,
    );
    await gesture.up();
    await t.pump();
    expect(count, 1);
    update(() => reduced = true);
    await t.pump();
    expect(
      t
          .widget<AnimatedScale>(
            find.descendant(of: target, matching: find.byType(AnimatedScale)),
          )
          .duration,
      Duration.zero,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(count, 2);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'glossy hover, actual wave, cancellation and live reduced motion',
    (t) async {
      var count = 0;
      var reduced = false;
      late StateSetter update;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduced),
                child: Scaffold(
                  body: Center(
                    child: GlassShortcut(
                      label: 'Glossy',
                      glossyInteraction: true,
                      onPressed: () => count++,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      final shortcut = find.byType(GlassShortcut);
      BoxDecoration surface() =>
          t
                  .widget<Ink>(
                    find.descendant(of: shortcut, matching: find.byType(Ink)),
                  )
                  .decoration!
              as BoxDecoration;
      List<Color> colors() => (surface().gradient! as LinearGradient).colors;
      final base = colors();
      final pointer = await t.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(t.getCenter(shortcut));
      await t.pumpAndSettle();
      final hover = colors();
      expect(hover, isNot(equals(base)));
      await pointer.down(t.getCenter(shortcut));
      await t.pump(const Duration(milliseconds: 240));
      expect(colors(), isNot(equals(hover)));
      expect(t.hasRunningAnimations, isTrue);
      update(() => reduced = true);
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(t.hasRunningAnimations, isFalse);
      update(() => reduced = false);
      await t.pump();
      expect(t.hasRunningAnimations, isTrue);
      await pointer.cancel();
      await t.pumpAndSettle();
      expect(count, 0);
      expect(t.hasRunningAnimations, isFalse);
      final held = await t.startGesture(t.getCenter(shortcut));
      await t.pump(const Duration(milliseconds: 240));
      await t.pumpWidget(const SizedBox());
      await held.up();
      await pointer.removePointer();
      await t.pump();
      expect(t.takeException(), isNull);
    },
  );
  for (final locale in ['ar', 'en']) {
    testWidgets('Home existing shortcut routes preserved $locale', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await Harness.signedIn();
      await t.runAsync(() async {
        await t.pumpWidget(
          h.wrap(
            const HomeScreen(),
            locale: Locale(locale),
            additionalRoutes: [
              for (final path in [
                '/food-search',
                '/camera',
                '/favorites',
                '/planner',
                '/shopping',
                '/coach',
                '/ramadan',
              ])
                GoRoute(
                  path: path,
                  builder: (_, _) =>
                      Scaffold(appBar: AppBar(), body: Text('shortcut:$path')),
                ),
            ],
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await t.pump(const Duration(seconds: 1));
      final c = t.element(find.byType(HomeScreen));
      final l = AppLocalizations.of(c);
      for (final entry in [
        (l.logHubSearchTitle, '/food-search'),
        (l.logHubPhotoTitle, '/camera'),
        (l.logHubFavoritesTitle, '/favorites'),
        (l.plannerTitle, '/planner'),
        (l.shoppingTitle, '/shopping'),
        (l.coachTitle, '/coach'),
        (l.ramadanGreeting, '/ramadan'),
      ]) {
        final f =
            ['/planner', '/shopping', '/coach', '/ramadan'].contains(entry.$2)
            ? find.byKey(ValueKey('home-action${entry.$2}'))
            : find.byWidgetPredicate(
                (w) => w is GlassShortcut && w.label == entry.$1,
              );
        final pos = t
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        pos.jumpTo(0);
        await t.pump(const Duration(seconds: 1));
        await t.scrollUntilVisible(
          f,
          250,
          maxScrolls: 80,
          scrollable: find.byType(Scrollable).first,
        );
        await t.ensureVisible(f);
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        await t.tap(find.descendant(of: f, matching: find.byType(InkWell)));
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(find.text('shortcut:${entry.$2}'), findsOneWidget);
        GoRouter.of(t.element(find.text('shortcut:${entry.$2}'))).pop();
        await t.pump();
        await t.pump(const Duration(seconds: 1));
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await h.dispose();
    });
  }
}
