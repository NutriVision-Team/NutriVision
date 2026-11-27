import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/camera_analysis/domain/food_recognition_provider.dart';
import 'package:sufradepi/features/camera_analysis/domain/photo_meal_resolver.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/features/meal_log/domain/catalog_meal_draft.dart';
import 'package:sufradepi/features/meal_log/domain/edit_logged_meal.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_review_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_detail_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final kind in ['review', 'saved', 'saved-2x']) {
    testWidgets('photo uncertainty survives $kind and scrolls at large text', (
      t,
    ) async {
      rootBundle.evict('assets/data/foods.json');
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final foods = (await t.runAsync(() => LocalFoodDataSource().getAll()))!;
      final portions = const PhotoMealResolver()
          .resolve(
            const FoodRecognitionResult(
              items: [
                RecognitionCandidate(
                  name: 'cooked rice',
                  foodState: 'cooked',
                  suggestedPortionGrams: 150,
                ),
              ],
            ),
            foods,
          )
          .values;
      final draft = CatalogMealDraft(portions);
      final h = (await t.runAsync(Harness.signedIn))!;
      addTearDown(h.dispose);
      final meal = draft.toMeal(
        uid: 'u1',
        id: 'photo-estimate',
        at: DateTime(2026, 11, 24, 12),
        mealType: 'lunch',
        inputMethod: 'photo',
      );
      h.nutritionRepository.meals = [
        editLoggedMeal(
          meal,
          title: 'أرز مطبوخ',
          mealType: 'lunch',
          notes: '',
          weightsInGrams: [200],
        ),
      ];
      final screen = kind == 'review'
          ? MealReviewScreen(draft: draft, inputMethod: 'photo')
          : const MealDetailScreen(
              mealId: 'photo-estimate',
              dateKey: '2026-11-24',
            );
      final key = GlobalKey();
      await t.pumpWidget(
        h.wrap(
          Builder(
            builder: (c) => MediaQuery(
              data: MediaQuery.of(c).copyWith(
                disableAnimations: true,
                textScaler: TextScaler.linear(kind.endsWith('2x') ? 2 : 1),
              ),
              child: RepaintBoundary(key: key, child: screen),
            ),
          ),
        ),
      );
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 500));
      final warning = find.textContaining('تقدير من صورة، مش قياس.');
      await t.scrollUntilVisible(
        warning,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(warning, findsOneWidget);
      expect(t.takeException(), isNull);
      await t.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '/downloads/sufra/photo_${kind}_uncertainty_ar.png',
        ).writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
      await t.drag(find.byType(Scrollable).first, const Offset(0, -4000));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(t.takeException(), isNull);
      if (kind == 'review') {
        final l = await AppLocalizations.delegate.load(const Locale('ar'));
        expect(h.nutritionRepository.meals.length, 1);
        await t.tap(find.text(l.mealSave));
        await t.pump(const Duration(milliseconds: 500));
        expect(h.nutritionRepository.meals.length, 2);
        final saved = h.nutritionRepository.meals.last;
        expect(saved.inputMethod, 'photo');
        expect(saved.totalCalories, 195);
        expect(saved.items.single.weightInGrams, 150);
      }
      await t.pumpWidget(const SizedBox());
    });
  }
}
