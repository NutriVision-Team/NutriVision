import 'package:sufradepi/core/theme/app_theme.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/features/camera_analysis/domain/food_recognition_provider.dart';
import 'package:sufradepi/features/camera_analysis/data/meal_image_preparer.dart';
import 'package:sufradepi/features/camera_analysis/presentation/camera_analysis_screen.dart';
import 'package:sufradepi/features/camera_analysis/presentation/capture_device.dart';
import 'package:sufradepi/features/meal_log/domain/meal_review_input.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'camera_screen_test.dart' show FixtureCaptureDevice;

class FakeQualifiedRecognition
    implements
        NonpersonalQualificationProvider,
        LocalizedRecognitionDisclosure {
  int calls = 0;
  @override
  bool get isAvailable => true;
  @override
  bool permitsImage(List<int> bytes) => bytes.isNotEmpty;
  @override
  String disclosureFor(String languageCode) => languageCode == 'ar'
      ? 'صورة تجريبية غير شخصية فقط'
      : 'Nonpersonal offline test only.';
  @override
  String get providerName => 'Offline test fixture';
  @override
  String get processingDisclosure => 'This test double does not transmit data.';
  @override
  Uri get privacyPolicy => Uri.parse('https://example.invalid/fixture-privacy');
  @override
  Future<FoodRecognitionResult> recognize(FoodRecognitionInput input) async {
    calls++;
    return const FoodRecognitionResult(
      items: [
        RecognitionCandidate(
          name: 'fixture food',
          confidence: .7,
          uncertaintyNotes: ['not measured'],
        ),
      ],
    );
  }
}

void main() {
  testWidgets(
    'qualified exact-image consent declines/lifecycle block; explicit agree calls local spy once',
    (t) async {
      final dir = await t.runAsync(
        () => Directory.systemTemp.createTemp('sufra-consent'),
      );
      final directory = dir!;
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/fixture.png')
        ..writeAsBytesSync(img.encodePng(img.Image(width: 10, height: 10)));
      final provider = FakeQualifiedRecognition();
      MealReviewInput? reviewed;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => CameraAnalysisScreen(
              device: FixtureCaptureDevice(CaptureStatus.denied),
              preparer: MealImagePreparer(temporaryDirectory: directory),
              pickGallery: () async => file.path,
              provider: provider,
            ),
          ),
          GoRoute(
            path: '/food-pick',
            builder: (context, _) => TextButton(
              onPressed: () => context.pop(
                FoodCatalogModel(
                  foodId: 'f',
                  name: 'rice',
                  source: 'Synthetic fixture',
                  foodState: 'cooked',
                  category: 'grains',
                  nutritionPer100g: const {
                    'calories': 100,
                    'protein': 2,
                    'carbohydrates': 20,
                    'fat': 1,
                  },
                ),
              ),
              child: const Text('choose fixture'),
            ),
          ),
          GoRoute(
            path: '/meal-review',
            builder: (_, state) {
              reviewed = state.extra as MealReviewInput;
              return const Text('review reached');
            },
          ),
        ],
      );
      await t.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.dark(),
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.ensureVisible(find.byTooltip('Choose image from gallery'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Choose image from gallery'));
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      // Image preparation uses real asynchronous file I/O. Wait for its UI
      // outcome, not a fixed delay that races the runner under concurrent load.
      for (
        var i = 0;
        i < 100 && find.text(l.cameraRetake).evaluate().isEmpty;
        i++
      ) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pump(const Duration(milliseconds: 20));
      }
      expect(
        find.text(l.cameraRetake),
        findsOneWidget,
        reason: 'Prepared-image UI must exist before testing consent.',
      );
      await t.scrollUntilVisible(
        find.text(l.cameraAnalyze),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.text(l.cameraAnalyze));
      await t.pumpAndSettle();
      expect(provider.calls, 0);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.tap(find.text(l.cameraConsentSend));
      await t.pumpAndSettle();
      expect(provider.calls, 0);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.tap(find.text(l.cameraAnalyze));
      await t.pumpAndSettle();
      await t.tap(find.text(l.actionCancel));
      await t.pumpAndSettle();
      expect(provider.calls, 0);
      await t.tap(find.text(l.cameraAnalyze));
      await t.pumpAndSettle();
      await t.tap(find.text(l.cameraConsentSend));
      await t.pumpAndSettle();
      expect(provider.calls, 1);
      expect(find.text('fixture food'), findsOneWidget);
      expect(find.textContaining('70%'), findsNothing);
      expect(reviewed, isNull);
      await t.scrollUntilVisible(
        find.text('fixture food'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(find.text('Choose match'));
      await t.pumpAndSettle();
      await t.tap(find.text('Choose match'));
      await t.pump(const Duration(milliseconds: 400));
      await t.pumpAndSettle();
      await t.tap(find.text('choose fixture'));
      await t.pumpAndSettle();
      expect(reviewed, isNull);
      await t.scrollUntilVisible(
        find.text('I reviewed food, preparation and portion'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(
        find.text('I reviewed food, preparation and portion'),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('I reviewed food, preparation and portion'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text(l.mealReviewTitle),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(find.text(l.mealReviewTitle));
      await t.pumpAndSettle();
      await t.tap(find.text(l.mealReviewTitle));
      await t.pumpAndSettle();
      expect(reviewed, isNotNull);
      expect(reviewed!.draft.portions.single.food.foodId, 'f');
      expect(reviewed!.inputMethod, 'photo');
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      router.dispose();
    },
  );
}
