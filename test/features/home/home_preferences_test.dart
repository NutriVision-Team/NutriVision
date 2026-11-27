import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/theme_cubit.dart';
import 'package:sufradepi/core/widgets/theme_switcher.dart';
import 'package:sufradepi/core/widgets/language_settings.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('Home preferences $lang $dark $scale', (t) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.reset);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final h = await Harness.signedIn();
          final key = GlobalKey();
          await t.runAsync(() async {
            await t.pumpWidget(
              RepaintBoundary(
                key: key,
                child: h.wrap(
                  const HomeScreen(),
                  locale: Locale(lang),
                  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
            );
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await t.pump(const Duration(seconds: 2));
          // Exercise the actual Home footer button, not a separately drawn dialog.
          await t.scrollUntilVisible(
            find.byIcon(Icons.palette_outlined),
            250,
            maxScrolls: 70,
            scrollable: find.byType(Scrollable).first,
          );
          await t.pump(const Duration(milliseconds: 1200));
          await t.tap(find.byIcon(Icons.palette_outlined).hitTestable());
          await t.pump(const Duration(milliseconds: 800));
          expect(find.byType(AccentPalettePicker), findsOneWidget);
          final context = t.element(find.byType(AccentPalettePicker));
          final cubit = context.read<ThemeCubit>();
          final other = cubit.accentIdFor(
            dark ? Brightness.light : Brightness.dark,
          );
          final label = find.text(lang == 'ar' ? 'بنفسجي' : 'Purple');
          await t.ensureVisible(label);
          await t.tap(label);
          await t.pump(const Duration(milliseconds: 800));
          expect(
            cubit.accentIdFor(dark ? Brightness.dark : Brightness.light),
            'purple',
          );
          expect(
            cubit.accentIdFor(dark ? Brightness.light : Brightness.dark),
            other,
          );
          expect(
            dark ? h.preferences.darkAccentId : h.preferences.lightAccentId,
            'purple',
          );
          expect(find.byIcon(Icons.check), findsOneWidget);
          Future<void> snap(String name) async {
            expect(t.takeException(), isNull);
            await t.runAsync(() async {
              final image =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '/downloads/sufra-recovered/prefs1555_${lang}_${dark ? 'dark' : 'light'}_${scale}_$name.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }

          // Top of scrollable dialog plus last option can both be reached.
          await t.ensureVisible(find.text(lang == 'ar' ? 'أخضر' : 'Green'));
          await t.pump(const Duration(milliseconds: 800));
          if (scale == 1.6) await snap('accent_bottom');
          await t.ensureVisible(
            find.text(lang == 'ar' ? 'فيروزي' : 'Turquoise'),
          );
          await t.pump(const Duration(milliseconds: 800));
          await snap('accent');
          Navigator.of(context).pop();
          await t.pump();
          await t.pump(const Duration(milliseconds: 800));
          // Reopen proves selected state is retained, no apply button needed.
          await t.ensureVisible(find.byIcon(Icons.palette_outlined));
          await t.pump(const Duration(milliseconds: 1200));
          await t.tap(find.byIcon(Icons.palette_outlined).hitTestable());
          await t.pump(const Duration(milliseconds: 800));
          expect(find.byIcon(Icons.check), findsOneWidget);
          Navigator.of(t.element(find.byType(AccentPalettePicker))).pop();
          await t.pump(const Duration(milliseconds: 800));
          final homeContext = t.element(find.byType(HomeScreen));
          final locale = homeContext.read<LocaleCubit>();
          await locale.setLocale(Locale(lang));
          final future = showLanguageSettings(homeContext);
          await t.pump();
          await t.pump(const Duration(milliseconds: 800));
          expect(find.byType(SufraSimpleDialog), findsOneWidget);
          await snap('language');
          await t.tap(find.text('English'));
          await t.pump(const Duration(milliseconds: 800));
          await future;
          expect(locale.state.languageCode, 'en');
          expect(h.preferences.localeCode, 'en');
          await t.pumpWidget(const SizedBox.shrink());
          await h.dispose();
        });
      }
    }
  }
}
