import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'nutrition_pdf_document.dart';

/// Browser download only, no recipient, upload, or external rendering service.
class ReportPdfExporter {
  static Future<void> shareNative(
    NutritionReportData data, {
    required bool Function() canShare,
  }) async {
    if (!canShare()) throw StateError('Inactive report account');
    final bytes = await NutritionPdfDocument.generate(data);
    if (!canShare()) throw StateError('Report account changed');
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    final url = web.URL.createObjectURL(blob);
    final a = web.HTMLAnchorElement()
      ..href = url
      ..download =
          'sufra_nutrition_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    web.document.body!.append(a);
    a.click();
    a.remove();
    Future<void>.delayed(
      const Duration(seconds: 30),
      () => web.URL.revokeObjectURL(url),
    );
  }
}
