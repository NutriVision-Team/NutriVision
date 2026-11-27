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
import 'package:sufradepi/features/premium/presentation/screens/premium_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'favorites_test.dart'
    show FakeNutrition, FakeBackend, now, meal, item, fav;

void main() {
  setUpAll(loadRealFonts);
  for (final light in [false, true]) {
    for (final premium in [false, true]) {
      testWidgets('secondary states premium=$premium light=$light', (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
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
              locale: const Locale('ar'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: RepaintBoundary(
                key: key,
                child: NebulaBackground(
                  child: BlocProvider.value(
                    value: c,
                    child: premium
                        ? const PremiumScreen()
                        : const FavoritesScreen(),
                  ),
                ),
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await t.pump(const Duration(seconds: 1));
        if (premium) {
          final pos = t
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position;
          pos.jumpTo(pos.maxScrollExtent);
          await t.pump();
        }
        expect(t.takeException(), isNull);
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra/verification/secondary_${premium ? 'premium' : 'favorites'}_${light ? 'light' : 'dark'}.png',
          ).writeAsBytes(b!.buffer.asUint8List());
          im.dispose();
        });
        if (!premium &&
            !light &&
            Platform.environment['SUFRA_CAPTURE_MOTION'] == '1') {
          final dir = Directory(
            '/downloads/sufra/verification/favorites_motion0720',
          )..createSync(recursive: true);
          for (var i = 0; i < 48; i++) {
            await t.pump(const Duration(milliseconds: 80));
            await t.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final b = await im.toByteData(format: ui.ImageByteFormat.png);
              await File(
                '${dir.path}/frame_${i.toString().padLeft(3, '0')}.png',
              ).writeAsBytes(b!.buffer.asUint8List());
              im.dispose();
            });
          }
        }
        if (!premium) {
          await t.tap(find.text('وصفات محفوظة'));
          await t.pump(const Duration(milliseconds: 500));
          expect(find.text('شكشوكة'), findsOneWidget);
          await t.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 150));
          });
          await t.pump(const Duration(milliseconds: 200));
          expect(t.takeException(), isNull);
          await t.runAsync(() async {
            final im =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final b = await im.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '/downloads/sufra/verification/secondary_recipe_favorites_${light ? 'light' : 'dark'}.png',
            ).writeAsBytes(b!.buffer.asUint8List());
            im.dispose();
          });
        }
        await t.pumpWidget(const SizedBox());
        await c.close();
      });
    }
  }
}
