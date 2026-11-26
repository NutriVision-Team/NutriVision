import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_accents.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/theme/theme_cubit.dart';
import 'package:sufradepi/core/widgets/theme_switcher.dart';
import 'package:sufradepi/core/widgets/journey_theme_control.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_log_hub_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  testWidgets('actual Sufra circular reveal both directions', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = await Harness.signedIn();
    final shot = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: shot,
        child: h.wrap(
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              final light = SufraAccents.resolve(
                state.lightAccentId,
                brightness: Brightness.light,
              );
              final dark = SufraAccents.resolve(
                state.darkAccentId,
                brightness: Brightness.dark,
              );
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: const Locale('ar'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: AppTheme.light(accent: light.color),
                darkTheme: AppTheme.dark(accent: dark.color),
                themeMode: state.mode,
                themeAnimationDuration: Duration.zero,
                builder: (_, child) =>
                    RepaintBoundary(key: sufraRootBoundaryKey, child: child!),
                home: const JourneyThemeControl(child: MealLogHubScreen()),
              );
            },
          ),
        ),
      ),
    );
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await t.pump(const Duration(seconds: 1));
    await t.pump();
    final dir = Directory('/downloads/sufra/verification/theme_motion0625');
    dir.createSync(recursive: true);
    var index = 0;
    Future<void> frame() async {
      await t.runAsync(() async {
        final im =
            await (shot.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${dir.path}/frame_${(index++).toString().padLeft(3, '0')}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        im.dispose();
      });
    }

    for (var direction = 0; direction < 2; direction++) {
      for (var i = 0; i < 8; i++) {
        await frame();
      }
      await t.tap(find.byType(LiquidThemeButton));
      await t.pump();
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await t.pump();
      expect(
        find.byWidgetPredicate((w) => w is RawImage && w.fit == BoxFit.fill),
        findsOneWidget,
      );
      for (var i = 0; i < 22; i++) {
        await frame();
        await t.pump(const Duration(milliseconds: 35));
      }
      expect(
        find.byWidgetPredicate((w) => w is RawImage && w.fit == BoxFit.fill),
        findsNothing,
      );
      for (var i = 0; i < 8; i++) {
        await frame();
      }
    }
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump();
    await h.dispose();
  });
}
