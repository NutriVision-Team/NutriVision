import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/progress_widgets.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets('page and progress transitions honor reduced $reduced', (
      t,
    ) async {
      final key = GlobalKey<NavigatorState>();
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          navigatorKey: key,
          builder: (c, w) => MediaQuery(
            data: MediaQuery.of(c).copyWith(disableAnimations: reduced),
            child: w!,
          ),
          home: const Scaffold(body: Text('home')),
        ),
      );
      key.currentState!.push(
        MaterialPageRoute<void>(
          builder: (c) => const Scaffold(
            body: Column(
              children: [
                Text('destination'),
                SufraProgressBar(fraction: .8),
                CalorieRing(fraction: .6),
              ],
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 70));
      final page = find.text('destination');
      final slides = find.ancestor(
        of: page,
        matching: find.byType(SlideTransition),
      );
      if (reduced) {
        expect(slides, findsNothing);
      } else {
        expect(slides, findsWidgets);
      }
      final progress = t.widgetList<TweenAnimationBuilder<double>>(
        find.byType(TweenAnimationBuilder<double>),
      );
      expect(progress.length, 2);
      for (final p in progress) {
        expect(p.duration, reduced ? Duration.zero : isNonZero);
      }
      await t.pump(const Duration(seconds: 2));
      key.currentState!.pop();
      await t.pump();
      await t.pump(const Duration(milliseconds: 70));
      if (reduced) {
        expect(
          find.ancestor(of: page, matching: find.byType(SlideTransition)),
          findsNothing,
        );
      }
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 1));
    });
  }
}

const isNonZero = _NonZero();

class _NonZero extends Matcher {
  const _NonZero();
  @override
  bool matches(Object? item, Map matchState) =>
      item is Duration && item > Duration.zero;
  @override
  Description describe(Description d) => d.add('nonzero duration');
}
