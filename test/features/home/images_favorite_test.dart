import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/catalog_food_art.dart';
import 'package:sufradepi/core/widgets/dish_float.dart';
import 'package:sufradepi/features/home/presentation/cubit/home_cubit.dart';
import 'package:sufradepi/features/home/presentation/widgets/home_activity_story.dart';
import 'package:sufradepi/data/models/favorite_model.dart';
import '../../favorites/favorites_test.dart' show meal, item;
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      testWidgets('known saved meal art and unknown fallback $lang $dark', (
        t,
      ) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final h = await Harness.signedIn();
        final key = GlobalKey();
        final data = HomeLoaded(
          profile: null,
          nutritionProfile: null,
          dailyLog: null,
          streakDays: 0,
          todaysMeals: [
            meal('known', 'أرز · Rice', [item('usda_sr_168878', 'Rice')]),
          ],
          favorites: const [
            FavoriteModel(
              favoriteId: 'f',
              targetId: 'known',
              targetType: 'meal',
              title: 'أرز · Rice',
            ),
            FavoriteModel(
              favoriteId: 'u',
              targetId: 'unknown',
              targetType: 'meal',
              title: 'وجبة محفوظة · Saved meal',
            ),
          ],
        );
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: h.wrap(
              Scaffold(
                body: SingleChildScrollView(
                  child: HomeActivityStory(
                    data: data,
                    now: DateTime(2026, 11, 22),
                  ),
                ),
              ),
              locale: Locale(lang),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
        );
        await t.pump(const Duration(seconds: 1));
        expect(find.byType(CatalogFoodArt), findsOneWidget);
        expect(find.byType(DishFloat), findsOneWidget);
        await t.ensureVisible(find.byType(CatalogFoodArt));
        await t.pump(const Duration(seconds: 1));
        await t.runAsync(() async {
          for (final e in find.byType(Image).evaluate()) {
            await precacheImage((e.widget as Image).image, e);
          }
        });
        await t.pump();
        expect(t.takeException(), isNull);
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra-recovered/images1949_home_${lang}_${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(b!.buffer.asUint8List());
          im.dispose();
        });
        await t.pumpWidget(const SizedBox());
        await h.dispose();
      });
    }
  }
}
