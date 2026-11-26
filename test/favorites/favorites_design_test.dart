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
import 'package:sufradepi/l10n/app_localizations.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'favorites_test.dart'
    show FakeNutrition, FakeBackend, now, meal, item, fav;

void main() {
  setUpAll(loadRealFonts);
  for (final light in [false, true]) {
    for (final scale in [1.0, 1.6]) {
      for (final lang in ['ar', 'en']) {
        testWidgets('Favorites design $lang $scale light=$light', (t) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final c = FavoritesCubit(
            uid: 'u1',
            currentUid: () => 'u1',
            backend: FakeBackend()
              ..docs = [
                fav('meal', 'm1', 'أرز وفراخ وخضار'),
                fav('meal', 'm2', 'بيض وجبنة'),
                fav('recipe', 'themealdb_52963', 'شكشوكة'),
              ],
            nutrition: FakeNutrition()
              ..meals = [
                meal('m1', 'أرز وفراخ وخضار', [
                  item('usda_sr_168878', 'أرز', kcal: 195),
                  item('usda_foundation_331960', 'فراخ', kcal: 199),
                  item('usda_foundation_2346406', 'خيار', kcal: 16),
                  item('usda_foundation_1999634', 'طماطم', kcal: 22),
                ], kcal: 432),
                meal('m2', 'بيض وجبنة', [
                  item('usda_foundation_748967', 'بيض'),
                  item('usda_foundation_2259796', 'جبنة فيتا'),
                ], kcal: 310),
              ],
            clock: () => now,
          );
          await c.load();
          final key = GlobalKey();
          await t.runAsync(() async {
            await t.pumpWidget(
              MaterialApp(
                theme: light ? AppTheme.light() : AppTheme.dark(),
                locale: Locale(lang),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: RepaintBoundary(
                  key: key,
                  child: NebulaBackground(
                    child: BlocProvider.value(
                      value: c,
                      child: const FavoritesScreen(),
                    ),
                  ),
                ),
              ),
            );
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await t.pump(const Duration(seconds: 1));
          expect(t.takeException(), isNull);
          await t.runAsync(() async {
            final im =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final b = await im.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '/downloads/sufra-recovered/fav1603_${lang}_${light ? 'light' : 'dark'}_$scale.png',
            ).writeAsBytes(b!.buffer.asUint8List());
            im.dispose();
          });
          final before = c.state.meals.length;
          await t.tap(find.byIcon(Icons.add_rounded).first);
          await t.pump();
          await t.pump(const Duration(milliseconds: 500));
          expect(find.byType(ListTile), findsNWidgets(4));
          // Opening the chooser must not copy a meal before a choice.
          expect(c.state.meals.length, before);
          expect(t.takeException(), isNull);
          Navigator.of(t.element(find.byType(ListTile).first)).pop();
          await t.pump();
          await t.pump(const Duration(milliseconds: 500));
          await t.tap(
            find.text(lang == 'ar' ? 'وصفات محفوظة' : 'Saved recipes'),
          );
          await t.pump(const Duration(milliseconds: 500));
          expect(find.text('شكشوكة'), findsOneWidget);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
          await c.close();
        });
      }
    }
  }
}
