import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/manual_food_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final dark in [true, false]) {
      testWidgets('manual food $lang dark=$dark narrow 2x', (t) async {
        t.view.physicalSize = const Size(320, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (c, ch) => MediaQuery(
              data: MediaQuery.of(c).copyWith(
                disableAnimations: true,
                textScaler: const TextScaler.linear(2),
              ),
              child: RepaintBoundary(
                key: const ValueKey('capture'),
                child: ch!,
              ),
            ),
            home: const ManualFoodScreen(),
          ),
        );
        await t.pumpAndSettle();
        for (final suffix in ['top', 'bottom']) {
          if (suffix == 'bottom') {
            await t.scrollUntilVisible(
              find.byType(FilledButton),
              300,
              scrollable: find.byType(Scrollable).first,
            );
            final pos = t
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position;
            pos.jumpTo(pos.maxScrollExtent);
            await t.pump();
          }
          expect(t.takeException(), isNull);
          final b = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('capture')),
          );
          await t.runAsync(() async {
            final im = await b.toImage();
            final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '/downloads/sufra/verification/manual_food_${lang}_${dark}_$suffix.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            im.dispose();
          });
        }
        await t.tap(find.byType(FilledButton));
        await t.pumpAndSettle();
        expect(
          find.text(
            (await AppLocalizations.delegate.load(
              Locale(lang),
            )).foodManualInvalid,
          ),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
        final checkbox = find.byType(Checkbox);
        await t.ensureVisible(checkbox);
        await t.tap(checkbox);
        await t.pump();
        expect(t.widget<Checkbox>(checkbox).value, isTrue);
        await t.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
