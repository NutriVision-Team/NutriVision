import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'native_nutrition_pdf.dart';

/// User-controlled sharing of the selected-range native, embedded-text PDF.
/// The legacy raster helper remains for visual regression captures only.
/// Sharing never selects a recipient or sends automatically.
class ReportPdfExporter {
  ReportPdfExporter._();

  /// Captures [boundaryKey]'s widget and returns the written PDF file.
  static Future<File> export(
    GlobalKey boundaryKey, {
    Directory? directory,
  }) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Report preview is not rendered yet');
    }
    final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
    final ByteData? bytes;
    try {
      bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    } finally {
      image.dispose();
    }
    if (bytes == null) {
      throw StateError('Could not encode the report preview');
    }

    final doc = pw.Document();
    final png = pw.MemoryImage(bytes.buffer.asUint8List());
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) =>
            pw.Center(child: pw.Image(png, fit: pw.BoxFit.contain)),
      ),
    );

    final dir = directory ?? await getTemporaryDirectory();
    final file = File(
      '${dir.path}/sufra_nutrition_report_'
      '${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static Future<void> shareNative(
    NutritionReportData data, {
    required bool Function() canShare,
    Directory? directory,
  }) async {
    if (!canShare()) throw StateError('Report account is no longer active');
    final file = await NativeNutritionPdf.write(
      data,
      directory ?? await getTemporaryDirectory(),
    );
    if (!canShare()) {
      await file.delete();
      throw StateError('Report account changed before sharing');
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: data.l10n.exportTitle),
    );
  }

  /// Exports and opens the OS share sheet (user chooses the recipient).
  static Future<void> exportAndShare(
    GlobalKey boundaryKey, {
    required bool Function() canShare,
  }) async {
    if (!canShare()) throw StateError('Report account is no longer active');
    final file = await export(boundaryKey);
    if (!canShare()) {
      await file.delete();
      throw StateError('Report account changed before sharing');
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Sufra nutrition report'),
    );
  }
}
