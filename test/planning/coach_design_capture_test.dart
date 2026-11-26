import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_screen.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'screens_smoke_test.dart'
    show SmokeNutritionRepository, FakeCoachDictation;

void main() {
  setUpAll(loadRealFonts);
  for (final ar in [true, false]) {
    for (final dark in [true, false]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets(
          'actual Coach ${ar ? 'ar' : 'en'} ${dark ? 'dark' : 'light'} scale$scale matrix',
          (t) async {
            t.view.physicalSize = const Size(390, 844);
            t.view.devicePixelRatio = 1;
            addTearDown(t.view.reset);
            final c = CoachCubit(
              userId: 'synthetic',
              store: SessionCoachStore(
                ownerUid: 'synthetic',
                currentUid: () => 'synthetic',
              ),
              nutrition: SmokeNutritionRepository(),
              locale: ar ? 'ar' : 'en',
            );
            await c.load();
            final key = GlobalKey();
            await t.pumpWidget(
              RepaintBoundary(
                key: key,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  theme: dark ? AppTheme.dark() : AppTheme.light(),
                  locale: Locale(ar ? 'ar' : 'en'),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  home: Scaffold(
                    body: CoachScreen(
                      cubit: c,
                      dictation: FakeCoachDictation(),
                    ),
                  ),
                ),
              ),
            );
            await t.pump(const Duration(seconds: 1));
            await t.pump(const Duration(milliseconds: 300));
            expect(t.takeException(), isNull);
            await t.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final b = await im.toByteData(format: ui.ImageByteFormat.png);
              await File(
                '/downloads/sufra-recovered/coach1343_${ar ? 'ar' : 'en'}_${dark ? 'dark' : 'light'}_${scale.toStringAsFixed(1)}.png',
              ).writeAsBytes(b!.buffer.asUint8List());
              im.dispose();
            });

            if (scale > 1) {
              final composer = find.byType(TextField).last;
              await t.ensureVisible(composer);
              await t.pump(const Duration(milliseconds: 400));
              expect(t.getRect(composer).bottom, lessThan(680));
              await t.tap(composer);
              await t.enterText(
                composer,
                ar ? 'مراجعة الواجهة' : 'UI review only',
              );
              await t.pump();
              expect(
                find.text(ar ? 'مراجعة الواجهة' : 'UI review only'),
                findsOneWidget,
              );
              await t.runAsync(() async {
                final im =
                    await (key.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage();
                final b = await im.toByteData(format: ui.ImageByteFormat.png);
                im.dispose();
                await File(
                  '/downloads/sufra-recovered/coverage1945_coach_${ar ? 'ar' : 'en'}_${dark ? 'dark' : 'light'}_composer.png',
                ).writeAsBytes(b!.buffer.asUint8List());
              });
            }
            await t.pumpWidget(const SizedBox());
            await c.close();
          },
        );
      }
    }
  }
}
