import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/meal_log/presentation/widgets/meal_budget_card.dart';
import 'package:sufradepi/features/meal_log/domain/meal_budget_preview.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final ar in [true, false]) {
    testWidgets(
      'whole meal budget warning ${ar ? 'ar' : 'en'} signals once and keeps alternative reversible',
      (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        var warnings = 0;
        var consumed = 1700.0;
        late StateSetter update;
        final key = GlobalKey();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (c, s) => Scaffold(
                body: SafeArea(
                  child: SingleChildScrollView(
                    child: StatefulBuilder(
                      builder: (c, set) {
                        update = set;
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: MealBudgetCard(
                            preview: MealBudgetPreview.calculate(
                              target: 2000,
                              consumed: consumed,
                              meal: 550,
                            )!,
                            warn: () async {
                              warnings++;
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/alternatives',
              builder: (c, s) => Scaffold(
                body: TextButton(
                  onPressed: () => c.pop(),
                  child: const Text('return without replacing'),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp.router(
              routerConfig: router,
              theme: ar ? AppTheme.dark() : AppTheme.light(),
              locale: Locale(ar ? 'ar' : 'en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
            ),
          ),
        );
        await t.pump(const Duration(seconds: 1));
        expect(warnings, 1);
        expect(find.text(ar ? '250 سعرة' : '250 kcal'), findsOneWidget);
        update(() {});
        await t.pump();
        expect(warnings, 1);
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final d = await im.toByteData(format: ui.ImageByteFormat.png);
          im.dispose();
          await File(
            '/downloads/sufra-recovered/meal_budget_${ar ? 'ar' : 'en'}_fixture.png',
          ).writeAsBytes(d!.buffer.asUint8List());
        });
        await t.tap(find.text(ar ? 'استكشف بدائل' : 'Explore alternatives'));
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(find.text('return without replacing'), findsOneWidget);
        await t.tap(find.text('return without replacing'));
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(find.text(ar ? '250 سعرة' : '250 kcal'), findsOneWidget);
        expect(warnings, 1);
        update(() => consumed = 1000);
        await t.pump();
        expect(find.text('Explore alternatives'), findsNothing);
        expect(find.text('استكشف بدائل'), findsNothing);
        update(() => consumed = 1700);
        await t.pump();
        expect(warnings, 2);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}
