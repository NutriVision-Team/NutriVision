import 'dart:async';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/features/meal_log/domain/catalog_meal_draft.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/app_buttons.dart';
import 'package:sufradepi/features/camera_analysis/domain/food_recognition_provider.dart';
import 'package:sufradepi/features/camera_analysis/data/meal_image_preparer.dart';
import 'package:sufradepi/features/camera_analysis/presentation/camera_analysis_screen.dart';
import 'package:sufradepi/features/camera_analysis/presentation/capture_device.dart';
import 'package:sufradepi/features/meal_log/domain/meal_review_input.dart';
import 'package:sufradepi/features/meal_log/presentation/cubit/meal_save_cubit.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../support/memory_firestore.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'camera_screen_test.dart' show FixtureCaptureDevice;
import 'qualification_consent_contract_test.dart' show FakeQualifiedRecognition;

class MatchedFixture extends FakeQualifiedRecognition {
  MatchedFixture({this.unresolved = false, this.mixed = false, this.gate});
  final Completer<void>? gate;
  final bool unresolved, mixed;
  @override
  Future<FoodRecognitionResult> recognize(FoodRecognitionInput input) async {
    calls++;
    if (gate != null) await gate!.future;
    return FoodRecognitionResult(
      items: [
        const RecognitionCandidate(
          name: 'cooked rice',
          matchedFoodId: 'usda_sr_168878',
          foodState: 'cooked',
          suggestedPortionGrams: 150,
        ),
        if (mixed) ...[
          const RecognitionCandidate(
            name: 'braised chicken breast',
            matchedFoodId: 'usda_foundation_331960',
            foodState: 'cooked',
            suggestedPortionGrams: 120,
          ),
          const RecognitionCandidate(
            name: 'raw cucumber',
            matchedFoodId: 'usda_foundation_2346406',
            foodState: 'raw',
            suggestedPortionGrams: 100,
          ),
          const RecognitionCandidate(
            name: 'raw tomato',
            matchedFoodId: 'usda_foundation_1999634',
            foodState: 'raw',
            suggestedPortionGrams: 100,
          ),
        ],
        if (unresolved)
          const RecognitionCandidate(
            name: 'unknown mixed dish',
            foodState: 'unknown',
            suggestedPortionGrams: 250,
          ),
      ],
    );
  }
}

void main() {
  setUpAll(loadRealFonts);
  for (final scenario in [
    'skip',
    'scan-ar',
    'coach',
    'coach-ar',
    'add-missing',
    'add-missing-ar',
    'delete-added-ar',
    'change-ar',
    'mixed',
    'quantity',
    'oil',
    'oil-ar',
    'oil-ar-2x',
    'unresolved',
  ]) {
    testWidgets(
      'actual camera route $scenario calculates and saves only on final review',
      (t) async {
        final ar = scenario.contains('-ar');
        final oilScenario = scenario.startsWith('oil');
        String tr(String en, String arabic) => ar ? arabic : en;
        rootBundle.evict('assets/data/foods.json');
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final dir = (await t.runAsync(
          () => Directory.systemTemp.createTemp('sufra-optional'),
        ))!;
        addTearDown(() => dir.delete(recursive: true));
        final file = scenario == 'scan-ar'
            ? File('/downloads/sufra-recovered/photo2115-natural/natural_0.jpg')
            : (File('${dir.path}/synthetic.png')..writeAsBytesSync(
                img.encodePng(img.Image(width: 20, height: 20)),
              ));
        final scanGate = scenario == 'scan-ar' ? Completer<void>() : null;
        final provider = MatchedFixture(
          gate: scanGate,
          unresolved: scenario == 'unresolved',
          mixed: scenario == 'mixed',
        );
        final store = MemoryFirestore();
        final repo = FirestoreNutritionRepository(store);
        MealReviewInput? input;
        CatalogMealDraft? returned;
        final router = GoRouter(
          routes: [
            if (scenario.startsWith('coach'))
              GoRoute(
                path: '/',
                builder: (context, _) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      returned = await context.push<CatalogMealDraft>(
                        '/capture',
                      );
                    },
                    child: const Text('Start photo'),
                  ),
                ),
              ),
            GoRoute(
              path: scenario.startsWith('coach') ? '/capture' : '/',
              builder: (_, _) => CameraAnalysisScreen(
                returnReviewedDraft: scenario.startsWith('coach'),
                device: FixtureCaptureDevice(CaptureStatus.denied),
                preparer: MealImagePreparer(temporaryDirectory: dir),
                pickGallery: () async => file.path,
                provider: provider,
              ),
            ),
            GoRoute(
              path: '/food-pick',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => context.pop(
                    FoodCatalogModel(
                      foodId: 'added-egg',
                      name: 'Added egg',
                      foodState: 'cooked',
                      source: 'Synthetic',
                      nutritionPer100g: const {'calories': 150},
                    ),
                  ),
                  child: const Text('Pick missing egg'),
                ),
              ),
            ),
            GoRoute(
              path: '/meal-review',
              builder: (_, s) {
                input = s.extra as MealReviewInput;
                return const Text('final review');
              },
            ),
          ],
        );
        addTearDown(router.dispose);
        await t.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.dark(),
            routerConfig: router,
            locale: Locale(ar ? 'ar' : 'en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(
                disableAnimations: scenario != 'scan-ar',
                textScaler: TextScaler.linear(scenario.endsWith('2x') ? 2 : 1),
              ),
              child: RepaintBoundary(
                key: const ValueKey('camera-shot'),
                child: child!,
              ),
            ),
          ),
        );
        if (scenario == 'scan-ar') {
          await t.pump(const Duration(milliseconds: 400));
        } else {
          await t.pumpAndSettle();
        }
        if (scenario.startsWith('coach')) {
          await t.tap(find.text('Start photo'));
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
        }
        await t.ensureVisible(find.byIcon(Icons.photo_library_outlined));
        if (scenario == 'scan-ar') {
          await t.pump(const Duration(milliseconds: 400));
        } else {
          await t.pumpAndSettle();
        }
        await t.tap(find.byIcon(Icons.photo_library_outlined));
        final l = await AppLocalizations.delegate.load(
          Locale(ar ? 'ar' : 'en'),
        );
        for (
          var i = 0;
          i < 100 && find.text(l.cameraRetake).evaluate().isEmpty;
          i++
        ) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)),
          );
          await t.pump(const Duration(milliseconds: 30));
        }
        await t.scrollUntilVisible(
          find.text(l.cameraAnalyze),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        if (scenario == 'scan-ar') {
          await t.pump(const Duration(milliseconds: 400));
        } else {
          await t.pumpAndSettle();
        }
        await t.tap(find.text(l.cameraAnalyze));
        if (scenario == 'scan-ar') {
          await t.pump(const Duration(milliseconds: 400));
        } else {
          await t.pumpAndSettle();
        }
        await t.tap(find.text(l.cameraConsentSend));
        if (scanGate != null) {
          await t.pump(const Duration(milliseconds: 100));
          final scanDir = Directory('/downloads/sufra/scan2148');
          scanDir.createSync(recursive: true);
          for (var f = 0; f < 24; f++) {
            await t.pump(const Duration(milliseconds: 100));
            final boundary = t.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('camera-shot')),
            );
            await t.runAsync(() async {
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File(
                '${scanDir.path}/frame_${f.toString().padLeft(3, '0')}.png',
              ).writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          scanGate.complete();
        }

        for (
          var i = 0;
          i < 100 &&
              find
                  .text(tr('Suggested meal', 'اقتراح لطبقك'))
                  .evaluate()
                  .isEmpty;
          i++
        ) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await t.pump(const Duration(milliseconds: 20));
        }
        await t.pump(const Duration(milliseconds: 500));
        expect(provider.calls, 1);
        expect(input, isNull);
        expect(store.documents, isEmpty);
        if (scenario == 'quantity') {
          await t.scrollUntilVisible(
            find.text('Edit amount'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
          await t.tap(find.text('Edit amount'));
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
          await t.enterText(find.byType(TextField).last, '200');
          await t.tap(find.text('Confirm amount'));
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
        }
        Future<void> shot(String name) async {
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('camera-shot')),
          );
          await t.runAsync(() async {
            final im = await boundary.toImage();
            final d = await im.toByteData(format: ui.ImageByteFormat.png);
            File(
              '/downloads/sufra/$name.png',
            ).writeAsBytesSync(d!.buffer.asUint8List());
            im.dispose();
          });
        }

        if (oilScenario) {
          if (ar) {
            await t.scrollUntilVisible(
              find.text(
                tr(
                  'Skip clarification and use estimates',
                  'تخطّي التوضيح وكمل بالتقدير',
                ),
              ),
              150,
              scrollable: find.byType(Scrollable).first,
            );
            await t.pump(const Duration(milliseconds: 300));
            await t.drag(find.byType(Scrollable).first, const Offset(0, 220));
            await t.pump(const Duration(milliseconds: 300));
            await shot(
              'photo_optional_actual_${scenario.endsWith('2x') ? 'ar-2x' : 'ar'}',
            );
          }
          await t.scrollUntilVisible(
            find.text(
              tr('Clarify olive oil in grams', 'وضّح زيت الزيتون بالجرام'),
            ),
            150,
            scrollable: find.byType(Scrollable).first,
          );
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
          await t.tap(
            find.text(
              tr('Clarify olive oil in grams', 'وضّح زيت الزيتون بالجرام'),
            ),
          );
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
          if (ar) {
            await shot(
              'photo_oil_dialog_${scenario.endsWith('2x') ? 'ar-2x' : 'ar'}',
            );
          }
          final add = find.text(tr('Add to calculation', 'أضف للحساب'));
          expect(
            t
                .widget<TextButton>(
                  find.ancestor(of: add, matching: find.byType(TextButton)),
                )
                .onPressed,
            isNull,
          );
          await t.enterText(find.byType(TextField).last, '10');
          await t.pump();
          expect(
            t
                .widget<TextButton>(
                  find.ancestor(of: add, matching: find.byType(TextButton)),
                )
                .onPressed,
            isNull,
          );
          await t.ensureVisible(find.byType(CheckboxListTile));
          await t.pump();
          if (ar && scenario.endsWith('2x')) {
            await shot('photo_oil_dialog_lower_ar-2x');
          }
          await t.tap(find.byType(CheckboxListTile));
          await t.pump();
          await t.ensureVisible(add);
          await t.pump();
          await t.tap(add);
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
        }
        if ((scenario.startsWith('add-missing') ||
            scenario.startsWith('delete-added'))) {
          await t.scrollUntilVisible(
            find.text(
              tr('Add a missing food to this meal', 'ضيف صنف ناقص للطبق'),
            ),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await t.tap(
            find.text(
              tr('Add a missing food to this meal', 'ضيف صنف ناقص للطبق'),
            ),
          );
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
          await t.tap(find.text('Pick missing egg'));
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
          expect(find.text('Added egg'), findsOneWidget);
          expect(store.documents, isEmpty);
        }
        if (scenario.startsWith('change')) {
          final change = find.text(tr('Change food', 'غيّر الصنف'));
          await t.scrollUntilVisible(
            change,
            150,
            scrollable: find.byType(Scrollable).first,
          );
          await t.ensureVisible(change);
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
          await t.tap(change);
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
          await t.tap(find.text('Pick missing egg'));
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
          expect(find.text('Added egg'), findsOneWidget);
        }
        if (scenario != 'quantity') {
          await t.ensureVisible(
            find.text(
              tr(
                'Skip clarification and use estimates',
                'تخطّي التوضيح وكمل بالتقدير',
              ),
            ),
          );
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
          await t.tap(
            find.text(
              tr(
                'Skip clarification and use estimates',
                'تخطّي التوضيح وكمل بالتقدير',
              ),
            ),
          );
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
        }
        if (scenario.startsWith('delete-added')) {
          final remove = find.byTooltip(tr('Skip', 'استبعاد')).last;
          await t.ensureVisible(remove);
          await t.tap(remove);
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
          expect(
            find.text(tr('Excluded from calculation', 'مستبعد من الحساب')),
            findsOneWidget,
          );
        }
        expect(input, isNull);
        expect(store.documents, isEmpty);
        final reviewLabel = scenario.startsWith('coach')
            ? tr('Use reviewed foods with Coach', 'رجّع الاختيارات للمدرّب')
            : l.mealReviewTitle;
        // Skipping quantity refinement or editing grams cannot confirm identity.
        await t.scrollUntilVisible(
          find.text(reviewLabel),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        if (scenario == 'scan-ar') {
          await t.pump(const Duration(milliseconds: 400));
        } else {
          await t.pumpAndSettle();
        }
        expect(
          t
              .widget<GradientButton>(
                find.ancestor(
                  of: find.text(reviewLabel),
                  matching: find.byType(GradientButton),
                ),
              )
              .onPressed,
          isNull,
        );
        await t.scrollUntilVisible(
          find
              .text(
                tr(
                  'I reviewed food, preparation and portion',
                  'راجعت الصنف والتحضير والكمية',
                ),
              )
              .first,
          -180,
          scrollable: find.byType(Scrollable).first,
        );
        if (scenario == 'scan-ar') {
          await t.pump(const Duration(milliseconds: 400));
        } else {
          await t.pumpAndSettle();
        }
        for (
          var item = 0;
          item <
              (scenario == 'mixed'
                  ? 4
                  : (scenario.startsWith('add-missing'))
                  ? 2
                  : 1);
          item++
        ) {
          final confirm = find
              .text(
                tr(
                  'I reviewed food, preparation and portion',
                  'راجعت الصنف والتحضير والكمية',
                ),
              )
              .first;
          await t.ensureVisible(confirm);
          await t.tap(confirm);
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
        }
        if (scenario == 'scan-ar') {
          await t.pump(const Duration(milliseconds: 400));
        } else {
          await t.pumpAndSettle();
        }
        if (scenario == 'unresolved') {
          await t.scrollUntilVisible(
            find.text(reviewLabel),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await t.pump();
          final button = t.widget<GradientButton>(
            find.ancestor(
              of: find.text(reviewLabel),
              matching: find.byType(GradientButton),
            ),
          );
          expect(button.onPressed, isNull);
          expect(input, isNull);
          expect(store.documents, isEmpty);
          expect(
            find.text('Partial total of matched foods only'),
            findsOneWidget,
          );
          await t.pumpWidget(const SizedBox());
          return;
        }
        if (oilScenario) {
          await t.scrollUntilVisible(
            find.text(tr('Estimated total', 'الإجمالي تقديري')),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          if (scenario == 'scan-ar') {
            await t.pump(const Duration(milliseconds: 400));
          } else {
            await t.pumpAndSettle();
          }
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('camera-shot')),
          );
          await t.runAsync(() async {
            final im = await boundary.toImage();
            final d = await im.toByteData(format: ui.ImageByteFormat.png);
            File(
              '/downloads/sufra/photo_oil_actual_fixture_${scenario.endsWith('2x')
                  ? 'ar-2x'
                  : ar
                  ? 'ar'
                  : 'en'}.png',
            ).writeAsBytesSync(d!.buffer.asUint8List());
            im.dispose();
          });
          await t.scrollUntilVisible(
            find.text(tr('About 283 kcal', 'حوالي 283 سعرة')),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(
            find.text(tr('About 283 kcal', 'حوالي 283 سعرة')),
            findsOneWidget,
          );
        }
        await t.scrollUntilVisible(
          find.text(reviewLabel),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        if (scenario == 'scan-ar') {
          await t.pump(const Duration(milliseconds: 400));
        } else {
          await t.pumpAndSettle();
        }
        if (scenario == 'skip') {
          expect(find.text('About 195 kcal'), findsOneWidget);
        }
        if (scenario.startsWith('coach')) {
          await shot(
            ar ? 'photo_coach_reviewed2094_ar' : 'photo_coach_reviewed2087',
          );
        }
        if ((scenario.startsWith('add-missing') ||
            scenario.startsWith('delete-added'))) {
          await shot(ar ? 'photo_added2121_ar' : 'photo_added2121_en');
        }
        await t.tap(find.text(reviewLabel));
        if (scenario == 'scan-ar') {
          await t.pump(const Duration(milliseconds: 400));
        } else {
          await t.pumpAndSettle();
        }
        if (scenario.startsWith('coach')) {
          expect(returned, isNotNull);
          expect(returned!.totals!.energyKcal, 195);
          expect(input, isNull);
          expect(store.documents, isEmpty);
          expect(find.text('Start photo'), findsOneWidget);
          await t.pumpWidget(const SizedBox());
          return;
        }
        expect(input, isNotNull);
        expect(input!.inputMethod, 'photo');
        expect(
          input!.draft.totals!.energyKcal,
          closeTo(
            scenario.startsWith('change')
                ? 150
                : scenario.startsWith('add-missing')
                ? 345
                : scenario == 'mixed'
                ? 195 + 120 / 100 * 166 + 100 / 100 * 15.9 + 100 / 100 * 22
                : oilScenario
                ? 283.4
                : scenario == 'quantity'
                ? 260
                : 195,
            .001,
          ),
        );
        expect(
          input!.draft.portions.length,
          scenario == 'mixed'
              ? 4
              : scenario.startsWith('add-missing')
              ? 2
              : oilScenario
              ? 2
              : 1,
        );
        expect(store.documents, isEmpty);
        final save = MealSaveCubit(
          draft: input!.draft,
          repository: repo,
          uid: 'fixture-user',
          currentUid: () => 'fixture-user',
          mealType: 'lunch',
          inputMethod: 'photo',
        );
        await save.save();
        await save.save();
        final meals = await repo.getMealEntries('fixture-user');
        expect(meals.length, 1);
        expect(meals.single.totalCalories, input!.draft.totals!.energyKcal);
        expect(meals.single.inputMethod, 'photo');
        await save.close();
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}
