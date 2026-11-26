import 'dart:io';
import 'package:clock/clock.dart';
import 'package:sufradepi/data/models/daily_log_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// Test-only native path boundary override; transitive plugin interface.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sufradepi/core/widgets/app_buttons.dart';
import 'package:sufradepi/features/progress/presentation/screens/export_report_screen.dart';
import 'progress_test.dart' as f;

class _Nutrition extends f.FakeNutritionRepository {
  @override
  Future<DailyLogModel?> getDailyLog(String uid, String key) async =>
      key == '2026-11-22' ? f.log(key) : null;
}

class _Temp extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async =>
      '/downloads/sufra/verification/route-temp';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final lang in ['ar', 'en']) {
    for (final preset in ['day', 'week', 'month']) {
      testWidgets(
        'actual export route $lang $preset reaches PDF share boundary',
        (
          t,
        ) async => withClock(Clock.fixed(DateTime(2026, 11, 22, 12)), () async {
          final previous = PathProviderPlatform.instance;
          PathProviderPlatform.instance = _Temp();
          addTearDown(() => PathProviderPlatform.instance = previous);
          t.view.physicalSize = const Size(800, 1000);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          final captured = <Map<dynamic, dynamic>>[];
          t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/share'),
            (call) async {
              expect(call.method, 'share');
              captured.add(Map<dynamic, dynamic>.from(call.arguments as Map));
              return 'dev.fluttercommunity.plus/share/dismissed';
            },
          );
          addTearDown(
            () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              const MethodChannel('dev.fluttercommunity.plus/share'),
              null,
            ),
          );
          await f.pumpScreen(
            t,
            ExportReportScreen(
              waterWeightRepository: f.FakeWaterWeightRepository(),
            ),
            _Nutrition()..logs = [f.log('2026-11-22')],
            locale: Locale(lang),
          );
          final labels = lang == 'ar'
              ? {'day': 'يومي', 'week': 'أسبوعي', 'month': 'شهري'}
              : {'day': 'Daily', 'week': 'Weekly', 'month': 'Monthly'};
          await t.tap(find.text(labels[preset]!));
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          for (var button = 0; button < 2; button++) {
            final finder = find.byType(GradientButton).at(button);
            await t.ensureVisible(finder);
            await t.pump(const Duration(milliseconds: 300));
            expect(t.widget<GradientButton>(finder).onPressed, isNotNull);
            await t.runAsync(() async {
              await t.tap(finder);
              for (var i = 0; i < 100 && captured.length <= button; i++) {
                await Future<void>.delayed(const Duration(milliseconds: 50));
              }
            });
            await t.pump();
            expect(captured.length, button + 1);
            final args = captured.last;
            expect(args['mimeTypes'], ['application/pdf']);
            expect(args['text'], isNull);
            expect(
              args['subject'],
              lang == 'ar'
                  ? 'سفرة · تقرير التغذية'
                  : 'Sufra · Nutrition report',
            );
            final paths = (args['paths'] as List).cast<String>();
            expect(paths, hasLength(1));
            await t.runAsync(() async {
              final file = File(paths.single);
              final bytes = await file.readAsBytes();
              expect(String.fromCharCodes(bytes.take(4)), '%PDF');
              final output =
                  '/downloads/sufra/verification/route_${lang}_${preset}_$button.pdf';
              await file.copy(output);
              final extracted = await Process.run('pdftotext', [
                '-layout',
                output,
                '-',
              ]);
              final text = extracted.stdout as String;
              expect(text, contains('2026-11-22'));
              if (preset == 'day') expect(text, isNot(contains('2026-11-21')));
              if (preset == 'week') expect(text, contains('2026-11-16'));
              if (preset == 'month') expect(text, contains('2026-11-01'));
              expect(text, contains('1800'));
              expect(text, contains('750'));
            });
          }
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        }),
      );
    }
  }
}
