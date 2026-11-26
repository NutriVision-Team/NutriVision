import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/camera_analysis/presentation/photo_meal_result_card.dart';
import 'package:sufradepi/features/camera_analysis/domain/food_recognition_provider.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final testCase in ['ar', 'en', 'ar-2x', 'en-2x']) {
    testWidgets(
      'optional clarification $testCase skips without measuring or saving',
      (t) async {
        final lang = testCase.split('-').first;
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(() {
          t.view.resetPhysicalSize();
          t.view.resetDevicePixelRatio();
        });
        final pending = {0};
        var oil = 0;
        var selected = 0;
        var skippedClarification = false;
        await t.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            theme: AppTheme.dark(),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(
                textScaler: TextScaler.linear(testCase.endsWith('2x') ? 2 : 1),
              ),
              child: child!,
            ),
            home: StatefulBuilder(
              builder: (c, set) => Scaffold(
                body: RepaintBoundary(
                  key: const ValueKey('shot'),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: PhotoMealResultCard(
                      result: const FoodRecognitionResult(
                        items: [
                          RecognitionCandidate(
                            name: 'Rice',
                            foodState: 'cooked',
                            suggestedPortionGrams: 150,
                          ),
                        ],
                      ),
                      chosen: {
                        0: FoodPortion(
                          FoodCatalogModel(
                            foodId: 'fixture',
                            name: lang == 'ar' ? 'أرز مطبوخ' : 'Cooked rice',
                            foodState: 'cooked',
                            source: 'hidden provider',
                            nutritionPer100g: const {
                              'calories': 130,
                              'protein': 2.5,
                            },
                          ),
                          150,
                        ),
                      },
                      skipped: const {},
                      unconfirmed: pending,
                      onChoose: (_) => selected++,
                      onConfirm: (i) => set(() => pending.remove(i)),
                      onPortion: (_) {},
                      onSkip: (_) {},
                      clarificationSkipped: skippedClarification,
                      onSkipClarification: () =>
                          set(() => skippedClarification = true),
                      onClarifyOil: () => oil++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pump();
        expect(t.takeException(), isNull);
        expect(find.text('hidden provider'), findsNothing);
        final skip = find.text(
          lang == 'ar'
              ? 'تخطّي التوضيح وكمل بالتقدير'
              : 'Skip clarification and use estimates',
        );
        expect(skip, findsOneWidget);
        final boundary = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('shot')),
        );
        await t.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '/downloads/sufra/photo_optional_$testCase.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
        await t.ensureVisible(skip);
        await t.pump();
        await t.tap(skip);
        await t.pump();
        expect(pending, {0});
        expect(skippedClarification, true);
        expect(selected, 0);
        expect(oil, 0);
        expect(
          find.textContaining(
            lang == 'ar' ? 'تقدير مش قياس' : 'estimates, not measurements',
          ),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
}
