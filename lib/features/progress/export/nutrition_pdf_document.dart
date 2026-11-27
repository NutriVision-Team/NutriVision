import 'coach_report_snapshot.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'nutrition_report_data.dart';
export 'nutrition_report_data.dart';
import '../domain/day_nutrition.dart';
import 'searchable_arabic_font.dart';

/// All values come from the reviewed selected-range snapshot. Fonts remain
/// embedded and text remains searchable; no screenshot is used for text.
class NutritionPdfDocument {
  static const ink = PdfColor.fromInt(0xff0a1022),
      muted = PdfColor.fromInt(0xff64748b),
      blue = PdfColor.fromInt(0xff1565c0),
      line = PdfColor.fromInt(0xffe2e8f0),
      cyan = PdfColor.fromInt(0xff06b6d4);
  static String num(double? n) => n == null || !n.isFinite
      ? '-'
      : n.toStringAsFixed(n == n.roundToDouble() ? 0 : 1);
  static Future<Uint8List> generate(NutritionReportData data) async {
    final regular = SearchableArabicFont(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );
    final bold = SearchableArabicFont(
      await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    );
    final l = data.l10n, days = data.days, a = NutritionAverages.of(data.days);
    final logo = await rootBundle.loadString(
      'assets/images/sufra_logo_watermark.svg',
    );
    final rtl = l.localeName.startsWith('ar');
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold).copyWith(
        defaultTextStyle: pw.TextStyle(
          font: regular,
          fontBold: bold,
          fontSize: 9,
          wordSpacing: 1.5,
          color: ink,
        ),
      ),
    );
    pw.Widget text(
      String value, {
      double size = 10,
      bool strong = false,
      PdfColor color = ink,
      bool ltr = false,
    }) {
      // Shape Arabic units in their own RTL run without reversing numeric ranges.
      if (ltr && RegExp(r'[\u0600-\u06ff]').hasMatch(value)) {
        final runs = RegExp(
          r'[\u0600-\u06ff]+|[^\u0600-\u06ff]+',
        ).allMatches(value);
        return pw.Directionality(
          textDirection: pw.TextDirection.ltr,
          child: pw.Row(
            mainAxisAlignment: rtl
                ? pw.MainAxisAlignment.end
                : pw.MainAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              for (final run in runs)
                pw.Text(
                  run.group(0)!,
                  textDirection:
                      RegExp(r'[\u0600-\u06ff]').hasMatch(run.group(0)!)
                      ? pw.TextDirection.rtl
                      : pw.TextDirection.ltr,
                  style: pw.TextStyle(
                    fontSize: size,
                    fontWeight: strong
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                    color: color,
                    wordSpacing: 1.5,
                  ),
                ),
            ],
          ),
        );
      }
      return pw.Directionality(
        textDirection:
            !ltr &&
                RegExp(r'[\u0600-\u06ff]').hasMatch(value) &&
                !RegExp(r'[A-Za-z0-9]').hasMatch(value)
            ? pw.TextDirection.rtl
            : ltr
            ? pw.TextDirection.ltr
            : rtl
            ? pw.TextDirection.rtl
            : pw.TextDirection.ltr,
        child: pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: size,
            fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
            wordSpacing: 1.5,
          ),
        ),
      );
    }

    pw.Widget heading(String s) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 9, bottom: 4),
      child: text(s, size: 12, strong: true),
    );
    pw.Widget panel(String label, String value) => pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.all(3),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: line),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          children: [
            text(label, color: muted),
            text(value, size: 16, strong: true, color: blue, ltr: true),
          ],
        ),
      ),
    );
    pw.Widget macro(
      String label,
      double? actual,
      double? target,
      PdfColor color,
    ) {
      final ratio = actual == null || target == null || target <= 0
          ? null
          : actual / target;
      final scale = ratio == null || ratio <= 1.2 ? 1.2 : ratio;
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 100,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  text(label),
                  text(
                    '${num(actual)} / ${num(target)} ${l.foodGramUnit}',
                    size: 8,
                    ltr: true,
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.LayoutBuilder(
                builder: (c, b) => pw.SizedBox(
                  height: 12,
                  child: pw.Stack(
                    children: [
                      pw.Positioned.fill(child: pw.Container(color: line)),
                      if (ratio != null)
                        pw.Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: pw.SizedBox(
                            width: b!.maxWidth * (ratio / scale).clamp(0, 1),
                            child: pw.Container(color: color),
                          ),
                        ),
                      if (target != null && target > 0)
                        pw.Positioned(
                          left: (b!.maxWidth / scale).clamp(0, b.maxWidth - 2),
                          top: 0,
                          bottom: 0,
                          child: pw.SizedBox(
                            width: 2,
                            child: pw.Container(color: ink),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            pw.SizedBox(
              width: 42,
              child: text(
                ratio == null ? '-' : '${num(ratio * 100)}%',
                ltr: true,
              ),
            ),
          ],
        ),
      );
    }

    final maxCalories = days
        .map((d) => d.calories ?? 0)
        .fold<double>(1, (a, b) => a > b ? a : b);
    final content = <pw.Widget>[
      text(l.exportTitle, size: 22, strong: true, color: blue),
      text(
        l.localeName.startsWith('ar')
            ? 'تقرير من سجلاتك، وليس تشخيصًا طبيًا'
            : 'From your records, not a medical diagnosis',
        size: 9,
        color: muted,
      ),
      if (days.isNotEmpty)
        text(
          '${days.first.dateKey} - ${days.last.dateKey}',
          color: muted,
          ltr: true,
        ),
      pw.SizedBox(height: 10),
      text(
        data.displayName?.trim().isNotEmpty == true ? data.displayName! : '-',
        size: 13,
        strong: true,
      ),
      for (final line in data.profileLines) text(line, size: 9, color: muted),
      if (data.profileLines.isNotEmpty)
        text(
          rtl ? 'بيانات الملف الحالية' : 'Current profile details',
          size: 8,
          color: muted,
        ),
      pw.Row(
        children: [
          panel(l.reportAverageCalories, num(a.calories)),
          panel(
            rtl ? 'السعرات مقارنة بالهدف' : 'Calories vs target',
            a.calories == null || a.calorieTarget == null
                ? '-'
                : '${num(a.calories! / a.calorieTarget! * 100)}%',
          ),
          panel(
            rtl ? 'تغير الوزن' : 'Weight change',
            data.weight.deltaKg == null
                ? '-'
                : '${data.weight.deltaKg! > 0
                      ? '-'
                      : data.weight.deltaKg! < 0
                      ? '+'
                      : ''}${num(data.weight.deltaKg?.abs())} ${l.unitKg}',
          ),
        ],
      ),
      text(
        rtl ? 'تغطية البيانات المسجلة' : 'Recorded-data coverage',
        size: 11,
        strong: true,
      ),
      for (final entry in <String, int>{
        l.statsCaloriesTitle: days
            .where((d) => d.tracked && d.calories != null)
            .length,
        l.exportProteinLabel: days
            .where((d) => d.tracked && d.protein != null)
            .length,
        rtl ? 'الألياف' : 'Fiber': days
            .where((d) => d.tracked && d.fiber != null)
            .length,
      }.entries)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            text(entry.key, size: 9),
            text('${entry.value} / ${days.length}', size: 9, ltr: true),
          ],
        ),
      text(
        rtl
            ? 'المتوسط لكل قيمة من الأيام المتاحة لها فقط، وليس كل أيام الفترة.'
            : 'Each average uses only days with that value, not all dates in the range.',
        size: 8,
        color: muted,
      ),
      heading(l.exportMacrosTitle),
      text(
        rtl
            ? 'الخط الأسود = الهدف. الأرقام: الفعلي / الهدف بالجرام.'
            : 'Black marker = target. Values: actual / target in grams.',
        size: 8,
        color: muted,
      ),
      macro(l.exportProteinLabel, a.protein, a.proteinTarget, cyan),
      macro(l.exportCarbsLabel, a.carbs, a.carbsTarget, PdfColors.orange),
      macro(l.exportFatLabel, a.fat, a.fatTarget, PdfColors.green),
      heading(l.statsCaloriesTitle),
      text('0 - ${num(maxCalories)} ${l.foodKcal}', color: muted, ltr: true),
      pw.Directionality(
        textDirection: pw.TextDirection.ltr,
        child: pw.SizedBox(
          height: 58,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              for (final d in days)
                pw.Expanded(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.symmetric(horizontal: 1),
                    height: d.calories == null
                        ? 2
                        : (d.calories! / maxCalories * 56).clamp(2, 56),
                    color: d.calories == null ? line : cyan,
                  ),
                ),
            ],
          ),
        ),
      ),
      if (days.isNotEmpty)
        pw.Directionality(
          textDirection: pw.TextDirection.ltr,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              text(days.first.dateKey, size: 8, ltr: true),
              text(days.last.dateKey, size: 8, ltr: true),
            ],
          ),
        ),
      pw.NewPage(freeSpace: 130 + ((days.length / 27).ceil() * 19)),
      pw.Container(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            heading(l.exportTrackingDays(days.length.toString())),
            text('${a.trackedDays} / ${days.length}', ltr: true),
            pw.SizedBox(height: 6),
            pw.Directionality(
              textDirection: pw.TextDirection.ltr,
              child: pw.Wrap(
                spacing: 3,
                runSpacing: 3,
                children: [
                  for (final d in days)
                    pw.Container(
                      width: 16,
                      height: 16,
                      decoration: pw.BoxDecoration(
                        color: d.tracked ? cyan : line,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
            text(
              rtl
                  ? 'الأقدم يسارًا والأحدث يمينًا. الملوّن يوم فيه تسجيل، والرمادي يوم من غير تسجيل. ده مش تقييم للالتزام أو جودة الأكل.'
                  : 'Oldest left, latest right. Color means a logged day; gray means no log. This is not a score for adherence or food quality.',
              size: 8,
              color: muted,
            ),
            text(
              rtl
                  ? 'عدد أيام التسجيل قد يشمل بيانات جزئية. شوف القيم الناقصة في الجدول.'
                  : 'Logged-day count can include partial records. Missing values appear in the table.',
              size: 8,
              color: muted,
            ),
            pw.SizedBox(height: 8),
            text(
              '${data.hydrationGoalMl == null ? l.waterGoalDefaultNote : l.waterGoalChosenNote}: ${num(data.hydrationGoalMl ?? 2000)} ${rtl ? 'مل' : 'ml'}',
              size: 9,
              color: muted,
            ),
          ],
        ),
      ),
      if (data.selectedCoach != null) ...[
        heading(rtl ? 'أهداف وخطوات اخترتها' : 'Your chosen goals and steps'),
        text(
          rtl
              ? 'أهدافك الحالية، مش إثبات لتحقيقها.'
              : 'Current chosen goals, not evidence of completion.',
          color: muted,
        ),
        for (final goal in data.selectedCoach!.goalLabels(rtl)) text(goal),
        for (final habit in data.selectedCoach!.habits)
          text(CoachReportSnapshot.label(habit, rtl)),
        text(data.selectedCoach!.summary(rtl)),
        text(
          rtl
              ? 'تأكيدات منك في الجلسة أو من الأيام المحفوظة المتاحة. الأيام الناقصة مش فشل ولا دليل على عدم التنفيذ.'
              : 'Your confirmations from this session or available saved days. Missing days are unknown, not failures or proof of non-completion.',
          color: muted,
          size: 8,
        ),
        for (final date in (data.selectedCoach!.checkins.keys.toList()..sort()))
          if (data.selectedCoach!.checkins[date]!.isNotEmpty)
            text(
              '$date: ${data.selectedCoach!.checkins[date]!.map((id) => CoachReportSnapshot.label(id, rtl)).join(rtl ? '، ' : ', ')}',
            ),
      ],
      heading(l.exportWeightHistory),
      if (data.weight.logs.isEmpty) text(l.exportNoWeightHistory, color: muted),
      for (final w in data.weight.logs.reversed)
        text('${w.dateKey}: ${num(w.weightKg)} ${l.unitKg}', ltr: true),
      pw.SizedBox(height: 12),
      text(l.progressUnknownNote, size: 9, color: muted),
      pw.SizedBox(height: 10),
      heading('${l.statsCaloriesTitle} / ${l.exportLoggedWater}'),
      text(
        rtl
            ? 'التواريخ والقيم المسجلة يوم بيوم. الشرطة تعني بيانات غير متاحة.'
            : 'Recorded values by date. A dash means unavailable.',
        color: muted,
      ),
      pw.SizedBox(height: 6),
      pw.TableHelper.fromTextArray(
        context: null,
        headers: rtl
            ? [
                'التاريخ',
                'السعرات',
                'بروتين جم',
                'كارب جم',
                'دهون جم',
                'المية مل',
              ]
            : ['Date', 'kcal', 'Protein g', 'Carbs g', 'Fat g', 'Water ml'],
        data: [
          for (final d in days)
            [
              d.dateKey,
              num(d.calories),
              num(d.protein),
              num(d.carbs),
              num(d.fat),
              d.waterMl > 0 ? num(d.waterMl) : '-',
            ],
        ],
        headerStyle: pw.TextStyle(
          font: regular,
          fontBold: bold,
          fontWeight: pw.FontWeight.bold,
          fontSize: 8,
        ),
        cellStyle: pw.TextStyle(font: regular, fontSize: 8),
        headerDecoration: const pw.BoxDecoration(color: line),
        cellAlignment: pw.Alignment.center,
        border: pw.TableBorder.all(color: line, width: .5),
      ),
    ];
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          buildBackground: (_) =>
              pw.Center(child: pw.SvgImage(svg: logo, width: 290, height: 290)),
        ),
        header: (_) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: line)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              text(rtl ? 'سفرة' : 'Sufra', size: 14, strong: true, color: blue),
              text(rtl ? 'تقرير التغذية' : 'Nutrition report', color: muted),
            ],
          ),
        ),
        maxPages: 1000,
        build: (_) => content,
        footer: (c) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: text(
            '${rtl ? 'سفرة' : 'Sufra'}  ·  ${c.pageNumber} / ${c.pagesCount}',
            color: muted,
            ltr: true,
          ),
        ),
      ),
    );
    return doc.save();
  }
}
