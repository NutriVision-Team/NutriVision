import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;
// Visual-proof captures for the master 5.3 liquid reveal. Run with
// --update-goldens to regenerate; the PNGs under test/goldens/theme/ are
// the inspected evidence attachments.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/config/app_preferences.dart';
import 'package:sufradepi/core/theme/app_accents.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/theme/theme_cubit.dart';
import 'package:sufradepi/core/widgets/theme_switcher.dart';

Future<ThemeCubit> _cubit([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await AppPreferences.load();
  return ThemeCubit(prefs);
}

/// Asymmetric old/new content: a copper block on the LEFT and a cyan
/// panel with a primary-colored button on the RIGHT, so the reveal
/// boundary is unambiguous in the capture.
Widget _proofApp(
  ThemeCubit cubit, {
  bool disableAnimations = false,
  bool plainThemes = false,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: const Size(800, 600),
      disableAnimations: disableAnimations,
    ),
    child: BlocProvider<ThemeCubit>.value(
      value: cubit,
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          final light = SufraAccents.resolve(
            state.lightAccentId,
            brightness: Brightness.light,
          );
          final dark = SufraAccents.resolve(
            state.darkAccentId,
            brightness: Brightness.dark,
          );
          // Reveal-proof app uses plain themes (no InkSparkle) so any
          // expanding circle in the capture is the reveal hole, not a
          // splash. Accent proofs below use AppTheme.
          return MaterialApp(
            theme: plainThemes
                ? ThemeData.light()
                : AppTheme.light(accent: light.color),
            darkTheme: plainThemes
                ? ThemeData.dark()
                : AppTheme.dark(accent: dark.color),
            themeMode: state.mode,
            home: RepaintBoundary(
              key: sufraRootBoundaryKey,
              // Builder: Theme.of must read BELOW MaterialApp.
              child: Builder(
                builder: (context) => Scaffold(
                  body: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: LiquidThemeButton(),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(12),
                                  // Theme-dependent on purpose: old dark
                                  // snapshot vs new light UI read as
                                  // unmistakably different blocks.
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF0D47A1)
                                      : const Color(0xFFFB8C00),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  margin: const EdgeInsets.all(12),
                                  color: const Color(0xFF67E8F9),
                                  child: Center(
                                    child: FilledButton(
                                      onPressed: () {},
                                      child: const SizedBox(
                                        width: 90,
                                        height: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: AccentPalettePicker()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  setUpAll(loadRealFonts);
  testWidgets(
    'proof: mid-reveal shows old snapshot outside, new theme inside',
    (tester) async {
      final cubit = await _cubit();
      await tester.pumpWidget(_proofApp(cubit, plainThemes: true));
      await tester.tap(find.byType(LiquidThemeButton));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(find.byType(RawImage), findsOneWidget);
      for (var i = 1; i <= 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../goldens/theme/reveal_f$i.png'),
        );
      }
      await tester.pumpAndSettle();
    },
  );

  testWidgets('proof: dark mode with copper accent', (tester) async {
    final cubit = await _cubit(const {'accent_dark': 'copper'});
    await tester.pumpWidget(_proofApp(cubit));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/theme/accent_dark_copper.png'),
    );
  });

  testWidgets('proof: light mode with green accent', (tester) async {
    final cubit = await _cubit(const {
      'theme_mode': 'light',
      'accent_light': 'green',
    });
    await tester.pumpWidget(_proofApp(cubit));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/theme/accent_light_green.png'),
    );
  });

  testWidgets('proof: reduced motion switches instantly, no overlay remnants', (
    tester,
  ) async {
    final cubit = await _cubit();
    await tester.pumpWidget(_proofApp(cubit, disableAnimations: true));
    await tester.tap(find.byType(LiquidThemeButton));
    // The toggle is synchronous under disableAnimations (asserted in the
    // switcher contract tests); settle so the capture shows the final
    // state and proves no overlay remnants remain.
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/theme/reduced_motion_after_toggle.png'),
    );
  });
}
