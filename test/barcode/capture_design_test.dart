import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/barcode/data/off_client.dart';
import 'package:sufradepi/features/barcode/data/off_cache.dart';
import 'package:sufradepi/features/barcode/domain/product_lookup_service.dart';
import 'package:sufradepi/features/barcode/domain/off_product.dart';
import 'package:sufradepi/features/barcode/presentation/cubit/barcode_cubit.dart';
import 'package:sufradepi/features/barcode/presentation/screens/barcode_scanner_screen.dart';
import 'package:sufradepi/features/barcode/presentation/screens/product_result_screen.dart';
import 'package:sufradepi/features/camera_analysis/presentation/camera_analysis_screen.dart';
import 'package:sufradepi/features/camera_analysis/presentation/capture_device.dart';
import 'package:sufradepi/features/voice_logging/voice_meal_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../features/camera_analysis/camera_screen_test.dart'
    show FixtureCaptureDevice;
import '../features/voice_logging/voice_flow_test.dart' show FixtureDictation;
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'barcode_domain_test.dart' show nutella, FakeTransport, cfg, ok;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('capture design $lang $dark $scale', (t) async {
          t.view.physicalSize = scale > 1
              ? const Size(320, 640)
              : const Size(390, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          for (final name in ['barcode', 'product', 'camera', 'voice']) {
            SharedPreferences.setMockInitialValues({});
            final service = ProductLookupService(
              client: OffClient(
                config: cfg,
                transport: FakeTransport((_, _) => ok(nutella())),
              ),
              cache: OffCache(await SharedPreferences.getInstance()),
            );
            final cubit = BarcodeCubit(service);
            final device = FixtureCaptureDevice(CaptureStatus.ready);
            final voice = FixtureDictation();
            final key = GlobalKey();
            final data = nutella();
            data['product']['image_front_url'] = null;
            data['product']['image_url'] = null;
            await t.pumpWidget(
              RepaintBoundary(
                key: key,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                  locale: Locale(lang),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (c, ch) => MediaQuery(
                    data: MediaQuery.of(c).copyWith(
                      disableAnimations: true,
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: ch!,
                  ),
                  home: switch (name) {
                    'barcode' => BlocProvider.value(
                      value: cubit,
                      child: const BarcodeScannerScreen(),
                    ),
                    'product' => ProductResultScreen(
                      product: OffProduct.fromV3('3017620422003', data)!,
                    ),
                    'camera' => CameraAnalysisScreen(device: device),
                    _ => VoiceMealScreen(dictation: voice),
                  },
                ),
              ),
            );
            await t.pump();
            await t.pump(const Duration(seconds: 1));
            Future<void> shot(String part) async {
              expect(t.takeException(), isNull);
              await t.runAsync(() async {
                final im =
                    await (key.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage();
                final b = await im.toByteData(format: ui.ImageByteFormat.png);
                await File(
                  '/downloads/sufra-recovered/capture1750_${name}_${lang}_${dark ? 'dark' : 'light'}_${scale}_$part.png',
                ).writeAsBytes(b!.buffer.asUint8List());
                im.dispose();
              });
            }

            await shot('top');
            if (find.byType(Scrollable).evaluate().isNotEmpty) {
              await t.drag(
                find.byType(Scrollable).first,
                const Offset(0, -650),
              );
              await t.pump(const Duration(milliseconds: 400));
              await shot('scroll');
            }
            if (name == 'barcode') {
              await t.ensureVisible(
                find.byKey(const ValueKey('barcode-field')),
              );
              await t.pump();
              await t.enterText(
                find.byKey(const ValueKey('barcode-field')),
                '3017620422004',
              );
              final l = await AppLocalizations.delegate.load(Locale(lang));
              await t.ensureVisible(find.text(l.barcodeLookup));
              await t.pump();
              await t.tap(find.text(l.barcodeLookup));
              await t.pump();
              expect(cubit.state.phase, BarcodePhase.invalidCode);
            }
            await t.pumpWidget(const SizedBox());
            await cubit.close();
          }
        });
      }
    }
  }
}
