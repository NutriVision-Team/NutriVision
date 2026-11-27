import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/barcode/domain/off_product.dart';
import 'package:sufradepi/features/barcode/presentation/screens/product_result_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'barcode_domain_test.dart' show nutella;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    testWidgets('product $lang 320px 2x full nutrition and CTA', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(320, 640);
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
      final data = nutella();
      data['product']['product_quantity_unit'] = 'g';
      data['product']['quantity'] = '400 g';
      final p = OffProduct.fromV3('3017620422003', data)!;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: RepaintBoundary(
              key: const ValueKey('product-shot'),
              child: child!,
            ),
          ),
          home: ProductResultScreen(product: p),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
      final l = await AppLocalizations.delegate.load(Locale(lang));
      await t.ensureVisible(find.text(l.productNutritionPer100g));
      await t.pump();
      final np = Platform.environment['SUFRA_PRODUCT_PIXEL'];
      if (np != null) {
        final b = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('product-shot')),
        );
        await t.runAsync(() async {
          final image = await b.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '$np-nutrition-$lang.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await t.drag(find.byType(Scrollable).first, const Offset(0, -4000));
      await t.pump();
      expect(t.takeException(), isNull);
      final pixel = Platform.environment['SUFRA_PRODUCT_PIXEL'];
      if (pixel != null) {
        final b = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('product-shot')),
        );
        await t.runAsync(() async {
          final image = await b.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$pixel-$lang.png').writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
