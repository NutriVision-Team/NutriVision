import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/app_states.dart';
import 'package:sufradepi/features/home/presentation/widgets/home_loading_skeleton.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

Widget app(Widget child, {bool reduced = false}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(320, 700),
      disableAnimations: reduced,
    ),
    child: Scaffold(body: child),
  ),
);
void main() {
  testWidgets('loading geometry has no invented numeric health values', (
    tester,
  ) async {
    await tester.pumpWidget(app(const HomeLoadingSkeleton()));
    expect(find.byType(SkeletonBlock), findsWidgets);
    expect(find.textContaining('420'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(app(const SizedBox()));
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonBlock), findsNothing);
  });
  testWidgets('reduced-motion shimmer is static with no ticker', (
    tester,
  ) async {
    await tester.pumpWidget(app(const SkeletonBlock(), reduced: true));
    await tester.pumpAndSettle();
    final first = tester.widget<Container>(
      find.descendant(
        of: find.byType(SkeletonBlock),
        matching: find.byType(Container),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    final second = tester.widget<Container>(
      find.descendant(
        of: find.byType(SkeletonBlock),
        matching: find.byType(Container),
      ),
    );
    expect(first.decoration, second.decoration);
    expect(tester.binding.hasScheduledFrame, false);
  });
}
