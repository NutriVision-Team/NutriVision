import 'dart:io';
import 'nutrition_pdf_document.dart';
export 'nutrition_report_data.dart';

class NativeNutritionPdf {
  static String num(double? n) => NutritionPdfDocument.num(n);
  static Future<File> write(
    NutritionReportData data,
    Directory directory,
  ) async {
    await directory.create(recursive: true);
    return File(
      '${directory.path}/sufra_nutrition_report_${DateTime.now().microsecondsSinceEpoch}.pdf',
    ).writeAsBytes(await NutritionPdfDocument.generate(data));
  }
}
