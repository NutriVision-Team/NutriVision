import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/nebula_background.dart';
import 'package:sufradepi/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:sufradepi/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:sufradepi/features/favorites/domain/favorites_logic.dart';
import 'package:sufradepi/features/alternatives/domain/alternatives_repository.dart';
import 'package:sufradepi/features/camera_analysis/domain/photo_meal_resolver.dart';
import 'package:sufradepi/features/camera_analysis/domain/food_recognition_provider.dart';
import 'package:sufradepi/features/meal_log/domain/catalog_meal_draft.dart';
import 'package:sufradepi/features/meal_log/presentation/widgets/meal_portion_alternatives.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../favorites/favorites_test.dart'
    show FakeBackend, FakeNutrition, fav;
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  testWidgets(
    'persistent favorite screen and calorie-fitting real food swap return to review without saving',
    (t) async {
      t.view.physicalSize = const Size(430, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      Future<void> mount(Widget screen) async {
        await t.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: false),
              child: child!,
            ),
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: RepaintBoundary(
              key: const ValueKey('shot2087'),
              child: NebulaBackground(child: screen),
            ),
          ),
        );
        await t.pump(const Duration(seconds: 1));
      }

      Future<void> shot(String name) async {
        final boundary = t.renderObject<RenderRepaintBoundary>(
          find.byKey(
            ValueKey(name == 'photo2087-food-swap' ? 'swap2087' : 'shot2087'),
          ),
        );
        await t.runAsync(() async {
          final im = await boundary.toImage();
          final data = await im.toByteData(format: ui.ImageByteFormat.png);
          File(
            '/downloads/sufra-recovered/$name.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          im.dispose();
        });
      }

      final b = FakeBackend()
        ..docs = [fav('food', 'usda_sr_168878', 'أرز مطبوخ')];
      final c = FavoritesCubit(
        uid: 'u1',
        currentUid: () => 'u1',
        backend: b,
        nutrition: FakeNutrition(),
      );
      await c.load();
      c.setTab(FavoritesTab.frequent);
      await mount(BlocProvider.value(value: c, child: const FavoritesScreen()));
      expect(find.text('أطعمة مفضلة من تكرار التسجيل'), findsOneWidget);
      await t.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/images/generated_food/168878.png'),
          t.element(find.byType(FavoritesScreen)),
        );
      });
      await t.pump(const Duration(milliseconds: 100));
      await shot('photo2087-favorite');
      if (Platform.environment['SUFRA_CAPTURE_FAVORITE_MOTION'] == '1') {
        final frames = Directory(
          '/downloads/sufra-recovered/favorite2096-frames',
        )..createSync(recursive: true);
        for (var i = 0; i < 30; i++) {
          await t.pump(const Duration(milliseconds: 200));
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('shot2087')),
          );
          await t.runAsync(() async {
            final im = await boundary.toImage();
            final d = await im.toByteData(format: ui.ImageByteFormat.png);
            File(
              '${frames.path}/frame_${i.toString().padLeft(3, '0')}.png',
            ).writeAsBytesSync(d!.buffer.asUint8List());
            im.dispose();
          });
        }
      }

      await t.tap(find.byIcon(Icons.favorite));
      await t.pump(const Duration(seconds: 1));
      expect(c.state.foods, isEmpty);
      expect(b.docs, isEmpty);
      await t.pumpWidget(const SizedBox());
      await c.close();
      final alternatives = (await t.runAsync(
        () => AlternativesRepository().getAll(),
      ))!;
      final chosen = alternatives.firstWhere(
        (a) => a.original.id == 'usda_foundation_746782',
      );
      final f = chosen.original;
      final portion = const PhotoMealResolver()
          .resolve(
            FoodRecognitionResult(
              items: [
                RecognitionCandidate(
                  name: f.nameEn,
                  matchedFoodId: f.id,
                  foodState: f.foodState,
                  suggestedPortionGrams: 100,
                ),
              ],
            ),
            [f],
          )
          .values
          .single;
      final draft = CatalogMealDraft([portion]);
      CatalogMealDraft? selected;
      await mount(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showModalBottomSheet<CatalogMealDraft>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SizedBox(
                    height: 900,
                    child: RepaintBoundary(
                      key: const ValueKey('swap2087'),
                      child: NebulaBackground(
                        child: MealPortionAlternatives(
                          draft: draft,
                          remaining: 40,
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await t.pump(const Duration(seconds: 1));
      expect(find.text('استخدم البديل وراجع'), findsWidgets);
      await shot('photo2087-food-swap');
      await t.ensureVisible(find.text('استخدم البديل وراجع').first);
      await t.tap(find.text('استخدم البديل وراجع').first);
      await t.pump(const Duration(seconds: 1));
      expect(selected, isNotNull);
      expect(selected!.totals!.energyKcal, lessThanOrEqualTo(40));
      expect(selected!.portions.single.food.foodId, isNot(f.id));
      expect(selected!.portions.single.grams, 100);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
