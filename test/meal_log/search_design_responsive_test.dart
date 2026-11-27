import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/repositories/food_repository.dart';
import 'package:sufradepi/features/food_catalog/data/local_food_repository.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/food_search_screen.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final lang in ['ar', 'en']) {
    for (final large in [false, true]) {
      testWidgets('food search $lang large=$large real bundled records', (
        t,
      ) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = large
            ? const Size(320, 640)
            : const Size(390, 844);
        addTearDown(t.view.reset);
        final h = await Harness.signedIn();
        final repository = LocalFoodRepository();
        await t.runAsync(() => repository.browseFoods());
        await t.pumpWidget(
          h.wrap(
            Builder(
              builder: (c) => Localizations.override(
                context: c,
                locale: Locale(lang),
                child: MediaQuery(
                  data: MediaQuery.of(
                    c,
                  ).copyWith(textScaler: TextScaler.linear(large ? 2 : 1)),
                  child: RepositoryProvider<FoodRepository>(
                    create: (_) => repository,
                    child: const RepaintBoundary(
                      key: ValueKey('food-search-shot'),
                      child: FoodSearchScreen(),
                    ),
                  ),
                ),
              ),
            ),
            locale: Locale(lang),
          ),
        );
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)),
        );
        await t.pump();
        expect(t.takeException(), isNull);
        expect(find.byType(ListView), findsOneWidget);
        final horizontal = find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection != AxisDirection.down,
            )
            .first;
        await t.drag(horizontal, Offset(lang == 'ar' ? 160 : -160, 0));
        await t.pump(const Duration(seconds: 1));
        final egypt = find.byKey(const ValueKey('food-category-egyptian'));
        // Align the target within its own strip only; the page stays still.
        final strip = t.state<ScrollableState>(horizontal);
        strip.position.jumpTo(0);
        await t.pump();
        await t.drag(horizontal, Offset(lang == 'ar' ? 180 : -180, 0));
        await t.pump(const Duration(seconds: 1));
        await Scrollable.ensureVisible(
          t.element(egypt),
          alignment: .5,
          duration: Duration.zero,
        );
        await t.pump(const Duration(milliseconds: 300));
        expect(egypt.hitTestable(), findsOneWidget);
        await t.tap(egypt);
        await t.pump(const Duration(seconds: 1));
        expect(t.widget<ChoiceChip>(egypt).selected, isTrue);
        strip.position.jumpTo(0);
        await t.pump();
        final all = find.byKey(const ValueKey('food-category-all'));
        await Scrollable.ensureVisible(
          t.element(all),
          alignment: .5,
          duration: Duration.zero,
        );
        await t.pump();
        await t.tap(all);
        await t.pump(const Duration(seconds: 1));
        final prefix = Platform.environment['SUFRA_SEARCH_PIXEL'];
        if (prefix != null) {
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('food-search-shot')),
          );
          await t.runAsync(() async {
            final image = await boundary.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            File(
              '$prefix-$lang-$large.png',
            ).writeAsBytesSync(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        if (prefix != null && !large && lang == 'ar') {
          for (final category in ['grains', 'vegetables', 'poultry', 'dairy']) {
            final dynamic body = t.state(
              find.byWidgetPredicate(
                (w) => w.runtimeType.toString() == '_FoodSearchBody',
              ),
            );
            body.browse(selectedCategory: category);
            await t.pump();
            await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 30)),
            );
            await t.pump(const Duration(milliseconds: 400));
            final selectedChip = find.byKey(
              ValueKey('food-category-$category'),
            );
            await Scrollable.ensureVisible(
              t.element(selectedChip),
              alignment: .5,
              duration: Duration.zero,
            );
            await t.pump(const Duration(milliseconds: 400));
            expect(t.widget<ChoiceChip>(selectedChip).selected, isTrue);
            final boundary = t.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('food-search-shot')),
            );
            await t.runAsync(() async {
              final image = await boundary.toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File(
                '$prefix-$category.png',
              ).writeAsBytesSync(data!.buffer.asUint8List());
              image.dispose();
            });
          }
          strip.position.jumpTo(0);
          await t.pump();
          t
              .widget<ChoiceChip>(
                find.byKey(const ValueKey('food-category-all')),
              )
              .onSelected!(true);
          await t.pump();
        }
        final vertical = find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first;
        final page = t.state<ScrollableState>(vertical);
        page.position.jumpTo(large ? 320 : 120);
        await t.pump();
        expect(find.byIcon(Icons.add), findsWidgets);
        expect(find.byIcon(Icons.add).first.hitTestable(), findsOneWidget);
        final row = find
            .ancestor(
              of: find.byIcon(Icons.add).first,
              matching: find.byType(InkWell),
            )
            .first;
        final bounds = t.getRect(row);
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.bottom, lessThanOrEqualTo(large ? 640 : 844));
        if (prefix != null) {
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('food-search-shot')),
          );
          await t.runAsync(() async {
            final image = await boundary.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            File(
              '$prefix-$lang-$large-scrolled.png',
            ).writeAsBytesSync(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        page.position.jumpTo(0);
        await t.pump();
        await t.enterText(find.byType(TextField), 'not-existing-food-xyz');
        await t.pump(const Duration(milliseconds: 300));
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pump();
        expect(find.byIcon(Icons.add), findsNothing);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await h.dispose();
      });
    }
  }
}
