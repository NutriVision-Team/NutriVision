import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/features/progress/export/native_nutrition_pdf.dart';
import 'package:sufradepi/features/progress/domain/day_nutrition.dart';
import 'package:sufradepi/features/progress/presentation/cubit/weight_cubit.dart';
import 'package:sufradepi/data/models/weight_log_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final lang in ['ar', 'en']) {
    test('native report $lang fixture', () async {
      final l = await AppLocalizations.delegate.load(Locale(lang));
      final days = List.generate(
        14,
        (i) => DayNutrition(
          dateKey: '2026-11-${(i + 9).toString().padLeft(2, '0')}',
          date: DateTime(2026, 11, i + 9),
          tracked: true,
          calories: i % 3 == 0 ? null : 1400 + i * 40,
          protein: 110,
          carbs: 170,
          fat: 60,
          calorieTarget: 2000,
          proteinTarget: 100,
          carbsTarget: 220,
          fatTarget: 70,
          waterMl: i % 2 == 0 ? 1500 : 0,
        ),
      );
      final file = await NativeNutritionPdf.write(
        NutritionReportData(
          days: days,
          weight: WeightState(
            logs: [
              WeightLogModel(
                weightId: 'w2',
                weightKg: 88.2,
                recordedAt: DateTime(2026, 11, 22),
                dateKey: '2026-11-22',
              ),
              WeightLogModel(
                weightId: 'w1',
                weightKg: 89,
                recordedAt: DateTime(2026, 11, 10),
                dateKey: '2026-11-10',
              ),
            ],
          ),
          l10n: l,
          displayName: lang == 'ar' ? 'بيانات اختبار' : 'QA example',
        ),
        Directory('/downloads/sufra/verification'),
      );
      await file.copy(
        '/downloads/sufra/verification/native_report_${lang}_fixture.pdf',
      );
      if (lang == 'ar') {
        await file.copy(
          '/downloads/sufra/verification/native_report_fixture.pdf',
        );
      }
      await file.delete();
      expect(
        await File(
          '/downloads/sufra/verification/native_report_${lang}_fixture.pdf',
        ).length(),
        greaterThan(1000),
      );
    });
  }
  for (final count in [0, 1, 30, 366]) {
    test('native PDF paginates $count days without loss', () async {
      final l = await AppLocalizations.delegate.load(const Locale('ar'));
      final days = List.generate(
        count,
        (i) => DayNutrition.empty(
          DateTime(2025, 1, 1 + i).toIso8601String().substring(0, 10),
        ),
      );
      final file = await NativeNutritionPdf.write(
        NutritionReportData(days: days, weight: const WeightState(), l10n: l),
        Directory('/downloads/sufra/verification'),
      );
      await file.copy('/downloads/sufra/verification/native_report_$count.pdf');
      final extracted = await Process.run('pdftotext', [
        '-layout',
        file.path,
        '-',
      ]);
      expect(extracted.exitCode, 0);
      final text = extracted.stdout as String;
      for (final day in days) {
        expect(
          text,
          contains(day.dateKey),
          reason: 'Every selected date must survive pagination',
        );
      }
      await file.delete();
    });
  }
}
