import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/core/widgets/app_buttons.dart';
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/diary/presentation/screens/diary_screen.dart';
import 'package:sufradepi/features/premium/presentation/screens/premium_screen.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;
import 'catalog_flow_test.dart' show catalog;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final premium in [false, true]) {
      testWidgets('${premium ? 'premium' : 'diary'} $lang 320px2x', (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(320, 640);
        addTearDown(() => t.view.reset());
        final h = await Harness.signedIn();
        h.nutritionRepository.meals = [
          FoodPortion(catalog(), 150).toMeal(
            uid: 'u1',
            id: 'meal',
            at: DateTime(2026, 11, 22, 14),
            mealType: 'lunch',
          ),
        ];
        h.nutritionRepository.logs = [
          DailyLogModel(
            dateKey: '2026-11-22',
            timezone: 'Africa/Cairo',
            totalCalories: 300,
            totalProtein: 15,
            totalCarbs: 30,
            totalFat: 12,
            totalFiber: 6,
            totalSugar: 3,
            totalSodium: 75,
            calorieTarget: 1850,
            proteinTarget: 100,
            carbsTarget: 200,
            fatTarget: 60,
            waterIntakeMl: 0,
            mealCount: 1,
          ),
        ];
        final screen = premium
            ? const PremiumScreen()
            : DiaryScreen(initialDate: DateTime(2026, 11, 22));
        await t.pumpWidget(
          h.wrap(
            Builder(
              builder: (c) => Localizations.override(
                context: c,
                locale: Locale(lang),
                child: MediaQuery(
                  data: MediaQuery.of(
                    c,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: RepaintBoundary(
                    key: const ValueKey('shot'),
                    child: screen,
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(t.takeException(), isNull);
        final p = Platform.environment['SUFRA_DIARY_PIXEL'];
        Future<void> shot(String suffix) async {
          if (p == null) return;
          final b = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('shot')),
          );
          await t.runAsync(() async {
            final i = await b.toImage();
            final d = await i.toByteData(format: ui.ImageByteFormat.png);
            File(
              '$p-${premium ? 'premium' : 'diary'}-$lang-$suffix.png',
            ).writeAsBytesSync(d!.buffer.asUint8List());
            i.dispose();
          });
        }

        await shot('top');
        final l = await AppLocalizations.delegate.load(Locale(lang));
        if (!premium) {
          final selected = find.byKey(const ValueKey('diary-day-2026-11-22'));
          expect(
            t
                .getSize(
                  find.descendant(of: selected, matching: find.text('22')),
                )
                .height,
            lessThan(60),
          );
          final last = find.byKey(const ValueKey('diary-day-2026-11-27'));
          await t.ensureVisible(last);
          await t.pump();
          await t.tap(last);
          await t.pump();
          await t.pump(const Duration(milliseconds: 100));
          expect(t.takeException(), isNull);
          await t.tap(find.byKey(const ValueKey('diary-next-week')));
          await t.pump();
          await t.pump(const Duration(milliseconds: 100));
          expect(
            find.byKey(const ValueKey('diary-day-2026-12-4')),
            findsOneWidget,
          );
          await t.tap(find.byKey(const ValueKey('diary-previous-week')));
          await t.pump();
          await t.pump(const Duration(milliseconds: 100));
        }

        final scroll = t.state<ScrollableState>(
          find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .first,
        );
        for (var i = 0; i < 5; i++) {
          scroll.position.jumpTo(scroll.position.maxScrollExtent);
          await t.pump();
        }
        expect(t.takeException(), isNull);
        if (!premium) {
          await t.scrollUntilVisible(
            find.byKey(const ValueKey('diary-slot-snack')),
            100,
            scrollable: find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .first,
          );
          await t.pump();
          final card = t.getRect(
            find.byKey(const ValueKey('diary-slot-snack')),
          );
          final nav = t.getRect(find.byType(FloatingGlassNavBar));
          final listTop = t.getRect(find.byType(ListView).first).top;
          expect(card.top, greaterThanOrEqualTo(listTop));
          expect(card.bottom, lessThanOrEqualTo(nav.top));
          final addMeal = find.descendant(
            of: find.byKey(const ValueKey('diary-slot-snack')),
            matching: find.byType(GradientButton),
          );
          expect(addMeal.hitTestable(), findsOneWidget);
          for (final label in [
            l.navHome,
            l.navDiary,
            l.navProgress,
            l.navAccount,
          ]) {
            final text = t.widget<Text>(
              find.descendant(
                of: find.byType(FloatingGlassNavBar),
                matching: find.text(label),
              ),
            );
            expect(text.maxLines, 1);
            expect(text.overflow, isNull);
          }
        }
        await shot('bottom');
        if (premium) {
          final label = find.text(l.premiumNotAvailable);
          expect(label, findsOneWidget);
          expect(t.getRect(label).bottom, lessThanOrEqualTo(640));
          expect(find.byType(ElevatedButton), findsNothing);
        }

        await t.pumpWidget(const SizedBox.shrink());
        await h.dispose();
      });
    }
  }
}
