import 'dart:io';
import 'package:sufradepi/features/achievements/data/persistence/achievement_progress_store.dart';
import 'support/persistence_fixtures.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/premium/presentation/screens/premium_screen.dart';
import 'package:sufradepi/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:sufradepi/features/dashboard/presentation/destination_hubs.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;
import 'discovery_features_test.dart'
    show StaticActivityLoader, activity, CaptureAchievements;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final light in [true, false]) {
      for (final scale in [1.0, 1.6]) {
        for (final feature in ['achievements', 'premium', 'privacy']) {
          testWidgets('closure $feature $lang $light $scale', (t) async {
            t.view.physicalSize = scale > 1
                ? const Size(320, 640)
                : const Size(390, 844);
            t.view.devicePixelRatio = 1;
            addTearDown(t.view.reset);
            t.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
            final h = await Harness.signedIn();
            final key = GlobalKey();
            final store = AchievementProgressStore(
              userId: 'owner',
              activeUserId: () => 'owner',
              backend: MemoryAchievementsBackend(),
            );
            final rules = await CaptureAchievements().load();
            await store.synchronize(activity(), rules);
            final Widget screen = switch (feature) {
              'achievements' => AchievementsScreen(
                userId: 'owner',
                todayKey: '2026-11-22',
                catalog: CaptureAchievements(),
                progressStore: store,
                loader: StaticActivityLoader(
                  activity(days: {'2026-11-21', '2026-11-22'}),
                ),
              ),
              'premium' => const PremiumScreen(),
              _ => const ProfileHubScreen(),
            };
            await t.pumpWidget(
              RepaintBoundary(
                key: key,
                child: h.wrap(
                  screen,
                  locale: Locale(lang),
                  themeMode: light ? ThemeMode.light : ThemeMode.dark,
                ),
              ),
            );
            await t.pump();
            await t.pump(const Duration(seconds: 2));
            Future<void> shot(String part) async {
              expect(t.takeException(), isNull);
              await t.runAsync(() async {
                for (final e in find.byType(Image).evaluate()) {
                  await precacheImage((e.widget as Image).image, e);
                }
              });
              await t.pump();
              await t.runAsync(() async {
                final im =
                    await (key.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage();
                final b = await im.toByteData(format: ui.ImageByteFormat.png);
                await File(
                  '/downloads/sufra-recovered/closure1843_${feature}_${lang}_${light ? 'light' : 'dark'}_${scale}_$part.png',
                ).writeAsBytes(b!.buffer.asUint8List());
                im.dispose();
              });
            }

            await shot('top');
            if (feature == 'achievements' && lang == 'ar' && scale == 1) {
              for (var n = 0; n < 30; n++) {
                await t.pump(const Duration(milliseconds: 120));
                await shot('motion${n.toString().padLeft(3, '0')}');
              }
            }

            if (feature == 'privacy') {
              final tile = find.text(
                lang == 'ar' ? 'الخصوصية والاستخدام' : 'Privacy and use',
              );
              await t.scrollUntilVisible(
                tile,
                300,
                scrollable: find.byType(Scrollable).first,
              );
              await Scrollable.ensureVisible(t.element(tile), alignment: 0.4);
              await t.pump();
              await t.tap(tile);
              await t.pump();
              await t.pump(const Duration(milliseconds: 500));
              await shot('dialog');
              await t.drag(
                find.byType(SingleChildScrollView).last,
                const Offset(0, -5000),
              );
              await t.pump();
              await shot('dialogscroll');
            } else {
              if (feature == 'achievements' && scale == 1) {
                final badge = find.text(
                  lang == 'ar' ? 'أول وجبة' : 'First Meal',
                );
                await t.scrollUntilVisible(
                  badge,
                  200,
                  scrollable: find.byType(Scrollable).first,
                );
                await Scrollable.ensureVisible(
                  t.element(badge),
                  alignment: 0.4,
                );
                await t.pump();
                await t.tap(badge);
                await t.pump();
                await t.pump(const Duration(milliseconds: 500));
                await shot('badge');
                expect(find.byType(SelectableText), findsOneWidget);
                expect(
                  find.textContaining(
                    lang == 'ar'
                        ? 'أول مرة سفرة سجّل فيها الإنجاز، مش بالضرورة وقت تحقيقه'
                        : 'First recorded by Sufra, not necessarily when earned',
                  ),
                  findsOneWidget,
                );
                await t.tap(find.text(lang == 'ar' ? 'تمام' : 'OK'));
                await t.pump();
                await t.pump(const Duration(milliseconds: 500));
              }

              await t.drag(
                find.byType(Scrollable).first,
                const Offset(0, -600),
              );
              await t.pump(const Duration(milliseconds: 500));
              await shot('scroll');
            }
            await t.pumpWidget(const SizedBox());
            await h.dispose();
          });
        }
      }
    }
  }
}
