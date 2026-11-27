import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_colors.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/progress_widgets.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

double ratio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
}

void main() {
  setUpAll(loadRealFonts);
  for (final dark in [false, true]) {
    testWidgets('macro text has contrast in ${dark ? 'dark' : 'light'} theme', (
      t,
    ) async {
      final theme = dark ? AppTheme.dark() : AppTheme.light();
      await t.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Row(
              children: [
                MacroTile(
                  label: 'Protein',
                  current: 22,
                  target: 180,
                  color: AppColors.turquoise,
                  gradient: AppColors.primaryGradient,
                ),
              ],
            ),
          ),
        ),
      );
      final total = t.widget<Text>(find.text('22/180'));
      expect(
        ratio(total.style!.color!, dark ? AppColors.darkSurface : Colors.white),
        greaterThanOrEqualTo(4.5),
      );
      expect(total.style!.fontFamily, AppTheme.displayFontFamily);
    });
  }
  testWidgets(
    'Home navigation preserves content clearance without covering the body',
    (t) async {
      final h = await Harness.signedIn();
      await t.pumpWidget(
        h.wrap(HomeScreen(clock: () => DateTime(2026, 11, 22, 18))),
      );
      await t.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await t.pump();
      expect(
        t
            .widget<FloatingGlassNavBar>(find.byType(FloatingGlassNavBar))
            .showIcons,
        isTrue,
      );
      expect(
        t.widget<Scaffold>(find.byType(Scaffold).first).extendBody,
        isFalse,
      );
      final listFinder = find.byType(ListView).first;
      final list = t.widget<ListView>(listFinder);
      final padding = list.padding! as EdgeInsets;
      expect(padding.bottom, greaterThanOrEqualTo(16));
      final bodyBottom = t.getBottomLeft(listFinder).dy;
      final navTop = t.getTopLeft(find.byType(FloatingGlassNavBar)).dy;
      expect(bodyBottom, lessThanOrEqualTo(navTop));
      await t.pumpWidget(const SizedBox.shrink());
      await h.dispose();
    },
  );
  testWidgets('light Home nutrition values retain dark readable text', (
    t,
  ) async {
    final h = await Harness.signedIn();
    await t.pumpWidget(
      h.wrap(
        HomeScreen(clock: () => DateTime(2026, 11, 22, 18)),
        themeMode: ThemeMode.light,
      ),
    );
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await t.pump(const Duration(seconds: 1));
    await t.scrollUntilVisible(
      find.text('420 kcal'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final calories = t.widget<Text>(find.text('420 kcal').first);
    expect(calories.style!.color, AppColors.lightTextPrimary);
    expect(
      ratio(calories.style!.color!, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
    await h.dispose();
  });
}
