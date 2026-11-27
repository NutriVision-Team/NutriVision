import 'package:sufradepi/features/meal_log/domain/meal_review_input.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/barcode/data/off_cache.dart';
import 'package:sufradepi/features/barcode/data/off_client.dart';
import 'package:sufradepi/features/barcode/domain/off_product.dart';
import 'package:sufradepi/features/barcode/domain/product_lookup_service.dart';
import 'package:sufradepi/features/barcode/presentation/cubit/barcode_cubit.dart';
import 'package:sufradepi/features/barcode/presentation/screens/barcode_scanner_screen.dart';
import 'package:sufradepi/features/barcode/presentation/screens/product_result_screen.dart';
import 'package:sufradepi/features/barcode/presentation/widgets/barcode_camera_view.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_review_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'barcode_domain_test.dart' show FakeTransport, cfg, nutella, ok;

class FakeCam implements BarcodeCameraController {
  @override
  Future<bool> toggleTorch() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  ValueChanged<String>? emit;
  ValueChanged<CameraIssue>? issue;
  Widget fakeCamera(
    BuildContext context, {
    required ValueChanged<String> onCode,
    required ValueChanged<CameraIssue> onIssue,
    required ValueChanged<BarcodeCameraController> onReady,
  }) {
    emit = onCode;
    issue = onIssue;
    WidgetsBinding.instance.addPostFrameCallback((_) => onReady(FakeCam()));
    return const ColoredBox(color: Color(0xFF222B45));
  }

  Object? reviewExtra;
  late FakeTransport transport;

  Future<Widget> app(
    FutureOr<OffHttpResponse> Function(Uri, Map<String, String>) h, {
    Locale locale = const Locale('ar'),
    double textScale = 1,
    ThemeData? theme,
    VoidCallback? photo,
  }) async {
    SharedPreferences.setMockInitialValues({});
    transport = FakeTransport(h);
    final service = ProductLookupService(
      client: OffClient(config: cfg, transport: transport),
      cache: OffCache(await SharedPreferences.getInstance()),
    );
    reviewExtra = null;
    final router = GoRouter(
      initialLocation: '/barcode',
      routes: [
        GoRoute(
          path: '/barcode',
          builder: (_, _) => BlocProvider(
            create: (_) => BarcodeCubit(service),
            child: BarcodeScannerScreen(
              cameraBuilder: fakeCamera,
              onPhotoFallback: photo,
            ),
          ),
        ),
        GoRoute(
          path: ProductResultScreen.routePath,
          builder: (_, s) =>
              ProductResultScreen(product: s.extra! as OffProduct),
        ),
        GoRoute(
          path: MealReviewScreen.routePath,
          builder: (_, s) {
            reviewExtra = s.extra;
            return const Scaffold(body: Text('REVIEW'));
          },
        ),
      ],
    );
    return MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme ?? AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  Future<void> settle(WidgetTester t) async {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
  }

  Future<void> show(WidgetTester t, Widget w) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    t.view.devicePixelRatio = 1;
    await t.runAsync(() async {
      await t.pumpWidget(w);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await t.pump(const Duration(milliseconds: 400));
  }

  Future<void> manual(WidgetTester t, String text) async {
    await t.enterText(find.byKey(const ValueKey('barcode-field')), text);
    await t.pump();
    await t.tap(find.text('دوّر'));
    await settle(t);
  }

  String messageText(WidgetTester t) =>
      (t.widget(find.byKey(const ValueKey('barcode-message'))) as Text).data!;

  testWidgets('invalid manual number: explicit error, no request', (t) async {
    await show(t, await app((_, _) => ok(nutella())));
    await manual(t, '3017620422004');
    expect(messageText(t), contains('الرقم غلط'));
    expect(transport.calls, isEmpty);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/scanner_invalid_ar.png'),
    );
  });

  testWidgets('idle scanner design state', (t) async {
    await show(t, await app((_, _) => ok(nutella()), photo: () {}));
    expect(find.text('شغّل الكاميرا'), findsOneWidget);
    expect(find.text('صوّر الجدول الغذائي'), findsOneWidget);
    expect(find.textContaining('تجريبي'), findsNothing); // no demo product
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/scanner_idle_ar.png'),
    );
  });

  testWidgets('not found is truthful and offers retry-free fallback text', (
    t,
  ) async {
    await show(
      t,
      await app(
        (_, _) => ok({
          'status': 'failure',
          'result': {'id': 'product_not_found'},
        }),
      ),
    );
    await manual(t, '3017620422003');
    expect(messageText(t), contains('ملقيناش المنتج'));
    expect(find.textContaining('مش هنسجّل أرقام من عندنا'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/scanner_notfound_ar.png'),
    );
  });

  testWidgets('offline shows retry; retry succeeds and opens product', (
    t,
  ) async {
    var offline = true;
    await show(
      t,
      await app((_, _) {
        if (offline) throw const SocketException('x');
        return ok(nutella());
      }),
    );
    await manual(t, '3017620422003');
    expect(messageText(t), contains('مفيش اتصال'));
    expect(find.text('حاول تاني'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/scanner_offline_ar.png'),
    );
    offline = false;
    await t.tap(find.text('حاول تاني'));
    await settle(t);
    expect(find.byType(ProductResultScreen), findsOneWidget);
  });

  testWidgets('camera denied keeps manual entry working', (t) async {
    await show(t, await app((_, _) => ok(nutella())));
    await t.tap(find.text('شغّل الكاميرا'));
    await t.pump();
    issue!(CameraIssue.permissionDenied);
    await t.pump();
    expect(messageText(t), contains('الكاميرا مش مسموحة'));
    await manual(t, '3017620422003');
    expect(find.byType(ProductResultScreen), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/product_nutella_ar.png'),
    );
  });

  testWidgets(
    'sodium displays full milligram unit and other nutrients retain gram units',
    (t) async {
      await show(t, await app((_, _) => ok(nutella())));
      await manual(t, '3017620422003');
      expect(find.text('٤٢٫٨ ملليجرام'), findsOneWidget);
      expect(find.text('٦٫٣ جم'), findsOneWidget);
      expect(find.text('٥٧٫٥ جم'), findsOneWidget);
      expect(find.text('٣٠٫٩ جم'), findsOneWidget);
      expect(find.text('٥٦٫٣ جم'), findsOneWidget);
      expect(find.text('٥٣٩ سعرة'), findsOneWidget);
    },
  );

  testWidgets('camera repeats same code: one request only', (t) async {
    await show(t, await app((_, _) async => ok(nutella())));
    await t.tap(find.text('شغّل الكاميرا'));
    await t.pump();
    for (var i = 0; i < 8; i++) {
      emit!('3017620422003');
    }
    await settle(t);
    expect(transport.calls.length, 1);
    expect(find.byType(ProductResultScreen), findsOneWidget);
  });

  testWidgets('product: unknowns labelled, grams add pushes FoodPortion', (
    t,
  ) async {
    await show(
      t,
      await app(
        (_, _) => ok({
          'status': 'success',
          'product': {
            'code': '3017620422003',
            'product_name': 'Plain Cracker',
            'brands': 'Acme',
            'quantity': '200 g',
            'product_quantity_unit': 'g',
            'serving_size': '30 g',
            'serving_quantity': 30,
            'nutriments': {'energy-kcal_100g': 430, 'proteins_100g': 9.5},
          },
        }),
      ),
    );
    await manual(t, '3017620422003');
    expect(
      find.text('غير مذكور'),
      findsNWidgets(5),
    ); // carbs fat fiber sugar sodium
    expect(find.text('٤٣٠ سعرة'), findsOneWidget);
    expect(find.text('نوتري سكور'), findsNothing); // no invented grade
    expect(
      find.textContaining('المصدر ملوش بيانات عن مسببات الحساسية'),
      findsOneWidget,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/product_partial_ar.png'),
    );
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('add-to-diary')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.pump();
    expect(find.byKey(const ValueKey('off-attribution')), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/product_partial_bottom_ar.png'),
    );
    // 30 g serving prefilled from declared grams
    expect(find.widgetWithText(TextField, '30'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('add-to-diary')));
    await settle(t);
    final input = reviewExtra as MealReviewInput;
    expect(input.inputMethod, 'barcode');
    final portion = input.draft.portions.single;
    expect(portion.grams, 30);
    expect(portion.food.source, 'Open Food Facts');
    expect(portion.amount('calories'), closeTo(129, .01));
    expect(portion.amount('fat'), isNull);
  });

  testWidgets('product: invalid grams blocks add', (t) async {
    await show(t, await app((_, _) => ok(nutella())));
    await manual(t, '3017620422003');
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('grams-field')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.enterText(find.byKey(const ValueKey('grams-field')), '0');
    await t.pump();
    await t.tap(find.byKey(const ValueKey('add-to-diary')));
    await t.pump();
    expect(reviewExtra, isNull);
    expect(find.textContaining('أكبر من صفر'), findsOneWidget);
  });

  testWidgets('liquid product: per 100 ml, logging blocked', (t) async {
    await show(t, await app((_, _) => ok(drinkJson())));
    await manual(t, '5449000000996');
    expect(find.text('القيم الغذائية لكل ١٠٠ مل'), findsOneWidget);
    expect(find.byKey(const ValueKey('log-blocked')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-to-diary')), findsNothing);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/product_liquid_ar.png'),
    );
  });

  testWidgets('English LTR product + scanner', (t) async {
    await show(
      t,
      await app((_, _) => ok(nutella()), locale: const Locale('en')),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/scanner_idle_en.png'),
    );
    await t.enterText(
      find.byKey(const ValueKey('barcode-field')),
      '3017620422003',
    );
    await t.pump();
    await t.tap(find.text('Look up'));
    await settle(t);
    expect(find.byType(ProductResultScreen), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/product_nutella_en.png'),
    );
  });

  testWidgets('large text scale: no overflow on scanner and product', (
    t,
  ) async {
    await show(t, await app((_, _) => ok(nutella()), textScale: 1.6));
    expect(t.takeException(), isNull);
    await manual(t, '3017620422003');
    expect(t.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/product_nutella_large_ar.png'),
    );
  });
}

Map<String, dynamic> drinkJson() => {
  'status': 'success',
  'product': {
    'code': '5449000000996',
    'product_name': 'Cola',
    'quantity': '330 ml',
    'nutriments': {'energy-kcal_100g': 42, 'sugars_100g': 10.6},
  },
};
