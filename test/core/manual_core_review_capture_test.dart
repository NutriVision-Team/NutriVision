import 'package:sufradepi/core/widgets/language_settings.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/diary/presentation/screens/diary_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_review_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_log_hub_screen.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/nutrition_plan/presentation/plan_screen.dart';
import 'package:sufradepi/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import 'package:sufradepi/features/progress/presentation/screens/export_report_screen.dart';
import '../features/progress/progress_test.dart' show FakeWaterWeightRepository;
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;
import '../meal_log/catalog_flow_test.dart' show catalog;

void main() {
  setUpAll(() async {
    await loadRealFonts();
    Directory(
      '/downloads/sufra/manual_review_0539',
    ).createSync(recursive: true);
  });
  testWidgets('manual core responsive review captures', (t) async {
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    for (final config in [
      ('ar', 390.0, 1.0, ThemeMode.light),
      ('ar', 320.0, 2.0, ThemeMode.light),
      ('en', 320.0, 2.0, ThemeMode.dark),
      ('ar', 390.0, 1.0, ThemeMode.dark),
      ('en', 390.0, 1.0, ThemeMode.light),
      ('en', 390.0, 1.0, ThemeMode.dark),
      ('ar', 320.0, 2.0, ThemeMode.dark),
    ]) {
      t.view.physicalSize = Size(config.$2, 844);
      t.platformDispatcher.textScaleFactorTestValue = config.$3;
      for (final name in ['review', 'diary', 'plan', 'log', 'export']) {
        final h = await Harness.signedIn();
        h.setupCubit.update(
          ProfileSetupData(
            nutritionGoal: 'lose',
            gender: 'male',
            dateOfBirth: DateTime(2000, 8, 7),
            heightCm: 175,
            currentWeightKg: 90,
            targetWeightKg: 80,
            activityLevel: 'moderate',
          ),
        );
        while (h.setupCubit.state.step < 6) {
          h.setupCubit.next();
        }
        await t.runAsync(() => h.setupCubit.finish('u1'));
        final Widget screen = switch (name) {
          'review' => MealReviewScreen(portion: FoodPortion(catalog(), 150)),
          'diary' => DiaryScreen(initialDate: DateTime(2026, 11, 22)),
          'plan' => const PlanScreen(),
          'log' => const MealLogHubScreen(),
          _ => ExportReportScreen(
            waterWeightRepository: FakeWaterWeightRepository(),
          ),
        };
        final key = GlobalKey();
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: h.wrap(
              screen,
              locale: Locale(config.$1),
              themeMode: config.$4,
            ),
          ),
        );
        await t.pump(const Duration(seconds: 2));
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await t.pump();
        expect(t.takeException(), isNull, reason: '$config $name top');
        Future<void> capture(String pos) async {
          await t.runAsync(() async {
            for (final element in find.byType(Image).evaluate()) {
              final image = element.widget as Image;
              await precacheImage(image.image, element);
            }
          });
          await t.pump();
          await t.runAsync(() async {
            for (final element in find.byType(Image).evaluate()) {
              final image = element.widget as Image;
              await precacheImage(image.image, element);
            }
          });
          await t.pump();
          await t.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            File(
              '/downloads/sufra/manual_review_0539/${config.$1}_${config.$2.toInt()}_${config.$3.toInt()}_${config.$4.name}_${name}_$pos.png',
            ).writeAsBytesSync(data!.buffer.asUint8List());
            image.dispose();
          });
        }

        await capture('top');
        if (name == 'review') {
          final l = AppLocalizations.of(
            t.element(find.byType(MealReviewScreen)),
          );
          if (find.text(l.mealNotes).evaluate().isEmpty) {
            await t.drag(find.byType(Scrollable).first, const Offset(0, -450));
            await t.pump();
          }
          await Scrollable.ensureVisible(
            t.element(find.text(l.mealNotes)),
            alignment: .3,
          );
          await t.pump();
          await t.tap(find.text(l.mealNotes));
          await t.pump();
          await t.pump(const Duration(milliseconds: 500));
          await capture('sheet');
          Navigator.of(t.element(find.byType(TextField).first)).pop();
          await t.pump();
          await t.pump(const Duration(milliseconds: 500));
        }
        if (name == 'review') {
          final context = t.element(find.byType(MealReviewScreen));
          final l = AppLocalizations.of(context);
          showSufraDialog<void>(
            context: context,
            builder: (c) => SufraAlertDialog(
              title: Text(l.mealDelete),
              content: Text(l.mealDeleteConfirm),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: Text(l.actionCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: Text(l.mealDelete),
                ),
              ],
            ),
          );
          await t.pump();
          await t.pump(const Duration(milliseconds: 500));
          await capture('dialog');
          Navigator.of(t.element(find.byType(SufraAlertDialog))).pop();
          await t.pump();
          await t.pump(const Duration(milliseconds: 500));
        }
        if (name == 'log') {
          final c = t.element(find.byType(MealLogHubScreen));
          ScaffoldMessenger.of(c).showSnackBar(
            SufraSnackBar(content: Text(AppLocalizations.of(c).stateError)),
          );
          await t.pump();
          await t.pump(const Duration(milliseconds: 400));
          await capture('message');
          ScaffoldMessenger.of(c).clearSnackBars();
          await t.pump();
        }
        if (name == 'diary') {
          final context = t.element(find.byType(DiaryScreen));
          showLanguageSettings(context);
          await t.pump();
          await t.pump(const Duration(milliseconds: 500));
          await capture('dialog');
          Navigator.of(
            t.element(find.byWidgetPredicate((w) => w is SimpleDialog)),
          ).pop();
          await t.pump(const Duration(milliseconds: 500));
        }
        final scroll = find.byType(Scrollable);
        if (scroll.evaluate().isNotEmpty) {
          final state = t.state<ScrollableState>(scroll.first);
          state.position.jumpTo(state.position.maxScrollExtent);
          await t.pump(const Duration(milliseconds: 500));
          await capture('bottom');
        }
        expect(t.takeException(), isNull, reason: '$config $name bottom');
        await t.pumpWidget(const SizedBox());
        await h.dispose();
      }
    }
  });
}
