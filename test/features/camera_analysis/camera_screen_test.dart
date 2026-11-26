import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:sufradepi/features/camera_analysis/data/meal_image_preparer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/camera_analysis/presentation/camera_analysis_screen.dart';
import 'package:sufradepi/features/camera_analysis/presentation/capture_device.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;

class FixtureCaptureDevice extends CaptureDevice {
  FixtureCaptureDevice(this.status);
  @override
  CaptureStatus status;
  @override
  double get minZoom => 1;
  @override
  double get maxZoom => 2;
  int pauses = 0, starts = 0;
  bool closed = false;
  @override
  Future<void> initialize() async {
    starts++;
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    pauses++;
    status = CaptureStatus.paused;
    notifyListeners();
  }

  @override
  Widget preview() => const ColoredBox(
    color: Color(0xFF17263B),
    child: Center(
      child: Icon(Icons.restaurant, size: 120, color: Color(0xFF34546A)),
    ),
  );
  @override
  Future<String> capture() => throw UnimplementedError();
  @override
  Future<bool> flash(bool enabled) async => false;
  @override
  Future<void> zoom(double value) async {}
  @override
  void dispose() {
    closed = true;
    super.dispose();
  }
}

void main() {
  setUpAll(loadRealFonts);
  Future<void> mount(WidgetTester tester, FixtureCaptureDevice device) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: CameraAnalysisScreen(device: device),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'camera fixture preserves frame, actual supported zoom and no fake recognition',
    (tester) async {
      final device = FixtureCaptureDevice(CaptureStatus.ready);
      await mount(tester, device);
      expect(find.text('1×'), findsOneWidget);
      expect(find.text('2×'), findsOneWidget);
      expect(find.text('0.5×'), findsNothing);
      expect(find.text('كشري'), findsNothing);
      await expectLater(
        find.byType(CameraAnalysisScreen),
        matchesGoldenFile('goldens/camera_ready_fixture.png'),
      );
      await tester.ensureVisible(find.text('اختار الأكل من القاعدة'));
      await tester.pumpAndSettle();
      expect(find.text('اختار الأكل من القاعدة').hitTestable(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(device.closed, isTrue);
    },
  );
  testWidgets('denied camera has retry and manual fallback without capture', (
    tester,
  ) async {
    final device = FixtureCaptureDevice(CaptureStatus.denied);
    await mount(tester, device);
    expect(find.text('جرّب تاني'), findsOneWidget);
    expect(find.text('اختار الأكل من القاعدة'), findsOneWidget);
    final capture = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.camera),
    );
    expect(capture.onPressed, isNull);
    await expectLater(
      find.byType(CameraAnalysisScreen),
      matchesGoldenFile('goldens/camera_denied.png'),
    );
    await tester.ensureVisible(find.text('اختار الأكل من القاعدة'));
    await tester.pumpAndSettle();
    expect(find.text('اختار الأكل من القاعدة').hitTestable(), findsOneWidget);
    await expectLater(
      find.byType(CameraAnalysisScreen),
      matchesGoldenFile('goldens/camera_denied_bottom.png'),
    );
  });
  testWidgets(
    'manual food action is fully visible at standard Arabic capture viewport',
    (tester) async {
      final device = FixtureCaptureDevice(CaptureStatus.ready);
      await mount(tester, device);
      final button = find.text('اختار الأكل من القاعدة');
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(button).dy, lessThanOrEqualTo(844));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'gallery preparation never deletes the chosen original and never auto-uploads',
    (tester) async {
      final dir = await tester.runAsync(
        () => Directory.systemTemp.createTemp('sufra-gallery'),
      );
      final directory = dir!;
      addTearDown(() => directory.delete(recursive: true));
      final original = File('${directory.path}/chosen.png')
        ..writeAsBytesSync(img.encodePng(img.Image(width: 10, height: 10)));
      final device = FixtureCaptureDevice(CaptureStatus.denied);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CameraAnalysisScreen(
            device: device,
            preparer: MealImagePreparer(temporaryDirectory: directory),
            pickGallery: () async => original.path,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Choose image from gallery'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Choose image from gallery'));
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump(const Duration(milliseconds: 30));
      }
      expect(original.existsSync(), true);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      expect(device.pauses, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      expect(original.existsSync(), true);
    },
  );
}
