import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// pdf3.11.3 exposes PdfTtfFont but not its CMap implementation. Kept isolated
// here and covered by extracted-text/embedded-font acceptance checks on upgrade.
// ignore: implementation_imports
import 'package:pdf/src/pdf/obj/unicode_cmap.dart';
import 'arabic_unicode_map.dart';

/// Shapes visual glyphs normally while mapping presentation-form glyphs back
/// to logical Unicode for ordinary viewer search/copy, including lam-alif.
class SearchableArabicFont extends pw.TtfFont {
  SearchableArabicFont(super.data);
  @override
  PdfFont buildFont(PdfDocument pdfDocument) {
    final font = PdfTtfFont(pdfDocument, data);
    font.unicodeCMap.inUse = false;
    font.unicodeCMap = _LogicalCmap(pdfDocument);
    return font;
  }
}

class _LogicalCmap extends PdfUnicodeCmap {
  _LogicalCmap(PdfDocument document) : super(document, false);
  @override
  // Base emits presentation-form mappings; this override writes logical Unicode instead.
  // ignore: must_call_super
  void prepare() {
    // Deliberately replaces the base CMap stream, not its glyph-ID list.
    buf.putString(
      '/CIDInit/ProcSet findresource begin 12 dict begin begincmap\n'
      '/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def\n'
      '/CMapName /Sufra-Logical-Unicode def /CMapType 2 def\n'
      '1 begincodespacerange <0000> <FFFF> endcodespacerange\n',
    );
    for (var offset = 0; offset < cmap.length; offset += 100) {
      final end = offset + 100 < cmap.length ? offset + 100 : cmap.length;
      buf.putString('${end - offset} beginbfchar\n');
      for (var i = offset; i < end; i++) {
        final value =
            arabicLogicalUnicode[cmap[i]] ?? String.fromCharCode(cmap[i]);
        final utf16 = ByteData(value.length * 2);
        for (var j = 0; j < value.length; j++) {
          utf16.setUint16(j * 2, value.codeUnitAt(j));
        }
        final hex = utf16.buffer
            .asUint8List()
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        buf.putString('<${i.toRadixString(16).padLeft(4, '0')}> <$hex>\n');
      }
      buf.putString('endbfchar\n');
    }
    buf.putString(
      'endcmap CMapName currentdict /CMap defineresource pop end end',
    );
  }
}
