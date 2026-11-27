import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/progress/presentation/screens/report_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/export_report_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/stats_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/water_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/weight_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'progress_test.dart' as f;
import 'package:sufradepi/core/widgets/floating_nav_bar.dart';
import 'package:sufradepi/features/progress/presentation/progress_format.dart';

void main() {
  setUpAll(loadRealFonts);
  for (final locale in ['ar', 'en']) {
    for (final scale in [1.5, 2.0]) {
      testWidgets('export percentages stay intact $locale scale$scale', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await f.pumpScreen(
          tester,
          Builder(
            builder: (context) => Localizations.override(
              context: context,
              locale: Locale(locale),
              child: MediaQuery(
                data: MediaQueryData(
                  size: const Size(390, 844),
                  textScaler: TextScaler.linear(scale),
                ),
                child: ExportReportScreen(
                  waterWeightRepository: f.FakeWaterWeightRepository(),
                ),
              ),
            ),
          ),
          f.FakeNutritionRepository()..logs = [f.log('2026-11-22')],
        );
        await tester.pump(const Duration(seconds: 1));
        final percentages = find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.style?.fontSize == 12 &&
              (w.data?.endsWith('%') ?? false),
        );
        expect(percentages, findsNWidgets(3));
        for (final element in percentages.evaluate()) {
          final text = element.widget as Text;
          expect(text.maxLines, 1);
          expect(text.softWrap, false);
          final paragraph = element.renderObject! as RenderParagraph;
          expect(paragraph.didExceedMaxLines, false);
          expect(
            paragraph.getMaxIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(paragraph.size.width + 0.1),
          );
        }
        for (final label in [
          locale == 'en' ? 'Export PDF' : 'تصدير PDF',
          locale == 'en' ? 'Share file' : 'مشاركة الملف',
        ]) {
          final finder = find.text(label);
          expect(finder, findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(finder);
          expect(paragraph.didExceedMaxLines, false);
          expect(paragraph.size.height, greaterThan(20));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets('active light navigation label has readable contrast', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: FloatingGlassNavBar(
            currentIndex: 0,
            onAdd: () {},
            items: [
              for (var i = 0; i < 4; i++)
                NavItem(label: 'tab$i', icon: Icons.home, onTap: () {}),
            ],
          ),
        ),
      ),
    );
    final color = DefaultTextStyle.of(
      tester.element(find.text('tab0')),
    ).style.color!;
    final luminance = color.computeLuminance();
    expect((1.05) / (luminance + 0.05), greaterThanOrEqualTo(4.5));
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('progress numbers use the chosen UI language', () {
    expect(ProgressFormat.oneDecimal(88.2, locale: 'en'), '88.2');
    expect(ProgressFormat.intDigits(1842, locale: 'en'), '1,842');
    expect(ProgressFormat.oneDecimal(88.2, locale: 'ar'), '٨٨.٢');
  });
  testWidgets('large text water wraps and report export stays in flow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Widget scaled(Widget child) => MediaQuery(
      data: const MediaQueryData(
        size: Size(390, 844),
        textScaler: TextScaler.linear(1.5),
      ),
      child: child,
    );
    await f.pumpScreen(
      tester,
      scaled(WaterScreen(waterWeightRepository: f.FakeWaterWeightRepository())),
      f.FakeNutritionRepository(),
      theme: AppTheme.light(),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await f.pumpScreen(
      tester,
      scaled(const ReportScreen()),
      f.FakeNutritionRepository()..logs = [f.log('2026-11-22')],
      theme: AppTheme.light(),
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final dark in [false, true]) {
    for (final report in [false, true]) {
      testWidgets(
        'progress ${report ? 'report' : 'stats'} contrast theme dark=$dark',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final key = GlobalKey();
          final theme = dark ? AppTheme.dark() : AppTheme.light();
          await f.pumpScreen(
            tester,
            RepaintBoundary(
              key: key,
              child: report
                  ? const ReportScreen()
                  : StatsScreen(
                      waterWeightRepository: f.FakeWaterWeightRepository(),
                    ),
            ),
            f.FakeNutritionRepository()..logs = [f.log('2026-11-22')],
            theme: theme,
          );
          await tester.pump(const Duration(seconds: 1));
          final title = find.text(
            report ? 'الأيام اللي سجلت فيها أكلك' : 'السعرات',
          );
          expect(title, findsOneWidget);
          expect(
            tester.widget<Text>(title).style?.color,
            theme.colorScheme.onSurface,
          );
          if (report) {
            expect(
              tester.getTopLeft(find.text('الأيام اللي سجلت فيها أكلك')).dy,
              lessThan(tester.getTopLeft(find.text('متوسط القيم المسجّلة')).dy),
            );
            expect(
              tester
                  .getTopLeft(
                    find.text(
                      AppLocalizations.of(
                        tester.element(find.byType(ReportScreen)),
                      ).reportWaterToday,
                    ),
                  )
                  .dy,
              lessThan(650),
            );
          } else {
            expect(
              tester.widget<Text>(find.text('شارات')).style?.color,
              theme.colorScheme.onSurface,
            );
            expect(
              tester.getTopLeft(find.text('شارات')).dy,
              lessThan(tester.getTopLeft(find.text('متوسط أداء الماكروز')).dy),
            );
          }
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '/downloads/sufra/contrast_${report ? 'report' : 'stats'}_${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
  for (final dark in [false, true]) {
    for (final water in [false, true]) {
      testWidgets('water weight primary composition dark=$dark water=$water', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final key = GlobalKey();
        await f.pumpScreen(
          tester,
          RepaintBoundary(
            key: key,
            child: water
                ? WaterScreen(
                    waterWeightRepository: f.FakeWaterWeightRepository(),
                  )
                : WeightScreen(
                    waterWeightRepository: f.FakeWaterWeightRepository(),
                  ),
          ),
          f.FakeNutritionRepository(),
          theme: dark ? AppTheme.dark() : AppTheme.light(),
        );
        await tester.pump(const Duration(seconds: 1));
        if (!water) {
          expect(
            tester.getTopLeft(find.text('+ سجّل وزن اليوم')).dy,
            greaterThan(650),
          );
        }
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra/layout_${water ? 'water' : 'weight'}_${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
