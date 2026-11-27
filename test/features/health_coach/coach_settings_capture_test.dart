import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/health_coach/presentation/screens/coach_health_settings_screen.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final ar in [true, false]) {
    testWidgets('simple context settings ${ar ? 'ar' : 'en'}', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            theme: AppTheme.light(),
            locale: Locale(ar ? 'ar' : 'en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CoachHealthSettingsScreen(
              profile: const HealthCoachProfile(),
              consent: const HealthCoachConsent(),
              providerAvailable: true,
              contextSharingAvailable: true,
              onSave: (_, __) {},
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final save = find.byKey(const ValueKey('save_health_choices'));
      await t.scrollUntilVisible(
        save,
        500,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.ensureVisible(save);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final tiles = t
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(tiles.length, 4);
      expect(tiles.every((x) => !x.value), isTrue);
      await t.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/downloads/sufra-recovered/coach2047-settings-${ar ? 'ar' : 'en'}.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
