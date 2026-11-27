import 'dart:io';
import 'package:sufradepi/features/progress/export/searchable_arabic_font.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('embedded Arabic shaping proof', () async {
    final font = SearchableArabicFont(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );
    final bold = SearchableArabicFont(
      await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    );
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: bold).copyWith(
        defaultTextStyle: pw.TextStyle(
          font: font,
          fontBold: bold,
          wordSpacing: 1.5,
        ),
      ),
    );
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'سفرة · تقرير التغذية',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'البروتين والكربوهيدرات والدهون',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                'السعرات الحرارية: 1800',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                'المية المسجلة وسجل الوزن',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Text('2026-11-09 - 2026-11-22'),
              ),
            ],
          ),
        ),
      ),
    );
    final dir = Directory('/downloads/sufra/verification');
    await dir.create(recursive: true);
    final bytes = await doc.save();
    await File('${dir.path}/embedded_arabic_probe.pdf').writeAsBytes(bytes);
    expect(bytes.length, greaterThan(1000));
  });
}
