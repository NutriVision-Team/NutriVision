import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/nebula_background.dart';
import 'package:sufradepi/features/home/presentation/widgets/home_recipe_section.dart';
import 'package:sufradepi/features/recipes/data/datasources/local_recipe_data_source.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'home_recipe_section_test.dart' show Source;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('recipe peek $lang $dark $scale', (t) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.reset);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final records = await t.runAsync(
            () => LocalRecipeDataSource().getAll(),
          );
          final source = Source(records!);
          final first = records.first;
          final key = GlobalKey();
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => Scaffold(
                  body: NebulaBackground(
                    child: SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: HomeRecipeSection(repository: source),
                      ),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: '/recipe/:id',
                builder: (_, s) =>
                    Scaffold(body: Text('details:${s.pathParameters['id']}')),
              ),
              GoRoute(
                path: '/recipes',
                builder: (_, _) => const Scaffold(body: Text('recipes')),
              ),
            ],
          );
          addTearDown(router.dispose);
          await t.pumpWidget(
            RepaintBoundary(
              key: key,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: router,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                locale: Locale(lang),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              ),
            ),
          );
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          await t.runAsync(() async {
            for (final name in ['shakshuka', 'ful', 'taameya', 'koshari']) {
              await precacheImage(
                AssetImage(
                  'assets/images/${name == 'shakshuka' ? 'generated_food' : 'reference_food'}/$name.png',
                ),
                key.currentContext!,
              );
            }
          });
          await t.pump();

          Future<void> snap(String state) async {
            expect(t.takeException(), isNull);
            await t.runAsync(() async {
              final image =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '/downloads/sufra-recovered/recipe1527_${lang}_${dark ? 'dark' : 'light'}_${scale}_$state.png',
              ).writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }

          final peek = find.byKey(ValueKey('recipe-peek-${first.id}'));
          await t.ensureVisible(peek);
          await t.pump(const Duration(milliseconds: 300));
          await snap('card');
          if (lang == 'ar' && scale == 1.0) {
            final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
            await mouse.addPointer(location: const Offset(2, 2));
            var frame = 0;
            for (var n = 0; n < 15; n++) {
              await t.pump(const Duration(milliseconds: 67));
              await snap('motion${(frame++).toString().padLeft(3, '0')}');
            }
            await mouse.moveTo(t.getCenter(peek));
            for (var n = 0; n < 15; n++) {
              await t.pump(const Duration(milliseconds: 67));
              await snap('motion${(frame++).toString().padLeft(3, '0')}');
            }
            await mouse.down(t.getCenter(peek));
            for (var n = 0; n < 20; n++) {
              await t.pump(const Duration(milliseconds: 67));
              await snap('motion${(frame++).toString().padLeft(3, '0')}');
            }
            await mouse.up();
            await mouse.removePointer();
          } else {
            await t.tap(peek);
          }
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          expect(find.text(first.ingredients.first.name), findsOneWidget);
          expect(find.text(first.ingredients.first.measure!), findsWidgets);
          expect(find.textContaining('details:'), findsNothing);
          await snap('peek');
          final open = find.text(
            lang == 'ar' ? 'افتح الوصفة والخطوات' : 'Open recipe and method',
          );
          await t.ensureVisible(open);
          await t.pump();
          await snap('bottom');
          await t.tap(open);
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          expect(find.text('details:${first.id}'), findsOneWidget);
          expect(source.calls, 1);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
}
