import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/features/progress/presentation/screens/report_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'progress_test.dart' as fixture;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('report $lang dark$dark scale$scale visual matrix', (
          t,
        ) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.reset);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final n = fixture.FakeNutritionRepository()
            ..logs = [for (var d = 16; d <= 22; d++) fixture.log('2026-11-$d')];
          final key = GlobalKey();
          await fixture.pumpScreen(
            t,
            RepaintBoundary(key: key, child: const ReportScreen()),
            n,
            locale: Locale(lang),
            theme: dark ? AppTheme.dark() : AppTheme.light(),
          );
          await t.pump(const Duration(seconds: 1));
          for (var page = 0; page < 3; page++) {
            if (page == 2) {
              await t.scrollUntilVisible(
                find.byType(ExpansionTile),
                200,
                scrollable: find.byType(Scrollable).first,
                maxScrolls: 15,
              );
              await t.tap(find.byType(ExpansionTile));
              await t.pump(const Duration(milliseconds: 450));
            }
            expect(t.takeException(), isNull);
            await t.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
              final stage =
                  Platform.environment['SUFRA_REPORT_STAGE'] ?? 'after';
              await File(
                '/downloads/sufra-recovered/report1348_${stage}_${lang}_${dark ? 'dark' : 'light'}_${scale}_$page.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              im.dispose();
            });
            await t.drag(find.byType(ListView).first, const Offset(0, -450));
            await t.pump(const Duration(milliseconds: 400));
          }
          await t.pumpWidget(const SizedBox());
        });
      }
    }
  }
  testWidgets('report explains real meal counts and honors reduced motion', (
    t,
  ) async {
    final n = fixture.FakeNutritionRepository()
      ..logs = [fixture.log('2026-11-22')]
      ..meals = [
        MealEntryModel(
          mealId: 'test',
          userId: 'u1',
          dateKey: '2026-11-22',
          consumedAt: DateTime(2026, 11, 22),
          mealType: 'breakfast',
          inputMethod: 'catalog',
          title: 'Fixture meal',
          items: const [],
          totalCalories: 100,
          totalProtein: null,
          totalCarbs: null,
          totalFat: null,
          totalFiber: null,
          totalSugar: null,
          totalSodium: null,
          analysisStatus: 'confirmed',
        ),
      ];
    await fixture.pumpScreen(
      t,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: const ReportScreen(),
        ),
      ),
      n,
      locale: const Locale('en'),
      theme: AppTheme.light(),
    );
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Breakfast: 1'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Achievements'), findsNothing);
    expect(find.text('No meal details to show a breakdown'), findsNothing);
    final tween = t.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>).first,
    );
    expect(tween.duration, Duration.zero);
    final cells = t
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .where((c) => c.key.toString().contains('report-recorded'));
    expect(cells, isNotEmpty);
    expect(cells.every((c) => c.duration == Duration.zero), isTrue);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  for (final dark in [false, true]) {
    testWidgets('report motion evidence dark$dark', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final key = GlobalKey();
      final n = fixture.FakeNutritionRepository()
        ..logs = [fixture.log('2026-11-22')];
      await fixture.pumpScreen(
        t,
        RepaintBoundary(key: key, child: const ReportScreen()),
        n,
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        locale: const Locale('en'),
      );
      for (var frame = 0; frame < 7; frame++) {
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra-recovered/report1348_motion_${dark ? 'dark' : 'light'}_$frame.png',
          ).writeAsBytes(b!.buffer.asUint8List());
          im.dispose();
        });
        await t.pump(const Duration(milliseconds: 166));
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
