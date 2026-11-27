import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'package:flutter/rendering.dart';
// Visual baselines for the four planning screens: AR empty/setup states at
// phone size. Generate with: flutter test test/planning/visual_baselines_test.dart --update
import 'dart:io';
import 'package:sufradepi/data/models/shopping_list_model.dart';
import 'package:sufradepi/features/ramadan/domain/ramadan_logic.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/features/planner/data/planner_repository.dart';
import 'package:sufradepi/features/planner/domain/weekly_plan_generator.dart';
import 'package:sufradepi/features/planner/presentation/cubit/planner_cubit.dart';
import 'package:sufradepi/features/planner/presentation/screens/planner_screen.dart';
import 'package:sufradepi/features/ramadan/data/ramadan_settings_store.dart';
import 'package:sufradepi/features/ramadan/presentation/cubit/ramadan_cubit.dart';
import 'package:sufradepi/features/ramadan/presentation/screens/ramadan_screen.dart';
import 'package:sufradepi/features/shopping/data/shopping_repository.dart';
import 'package:sufradepi/features/shopping/presentation/cubit/shopping_cubit.dart';
import 'package:sufradepi/features/shopping/presentation/screens/shopping_screen.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

import 'screens_smoke_test.dart' show SmokeNutritionRepository;
import 'support/planning_memory_firestore.dart';

class VisualPlannerCubit extends PlannerCubit {
  VisualPlannerCubit({
    required super.userId,
    required super.repository,
    required super.nutrition,
    required super.generator,
    required super.today,
  });
  void show(PlannerState value) => emit(value);
  @override
  Future<void> load() async {}
}

class VisualShoppingCubit extends ShoppingCubit {
  VisualShoppingCubit({
    required super.userId,
    required super.repository,
    required super.foods,
  });
  void show(ShoppingState value) => emit(value);
  @override
  Future<void> load() async {}
}

class VisualCoachCubit extends CoachCubit {
  VisualCoachCubit({
    required super.userId,
    required super.store,
    required super.nutrition,
    required super.locale,
    super.clock,
  });
  void show(CoachState value) => emit(value);
  @override
  Future<void> load() async {}
}

class VisualRamadanCubit extends RamadanCubit {
  VisualRamadanCubit({
    super.clock,
    required super.userId,
    required super.settings,
    required super.nutrition,
    required super.foods,
  });
  void show(RamadanState value) => emit(value);
  @override
  Future<void> load() async {}
}

void main() {
  setUpAll(() async {
    await loadRealFonts();
  });
  for (final lang in ['ar', 'en']) {
    for (final light in [true, false]) {
      for (final scale in [1.0, 1.6]) {
        for (final feature in ['planner', 'shopping', 'ramadan']) {
          testWidgets('planning design $feature $lang $light $scale', (
            tester,
          ) async {
            SharedPreferences.setMockInitialValues({});
            final store = PlanningMemoryFirestore();
            const mode = 'loaded';
            final nutrition = SmokeNutritionRepository();
            final foods = LocalFoodDataSource();
            final realCatalog = await tester.runAsync(() => foods.getAll());
            final prefs = await SharedPreferences.getInstance();
            final plan = WeeklyPlanGenerator(catalog: realCatalog!).generate(
              weekStart: DateTime(2026, 11, 21),
              dailyCalorieTarget: 2000,
              seed: 7,
            );
            late Widget screen;
            switch (feature) {
              case 'planner':
                final cubit = VisualPlannerCubit(
                  userId: 'u1',
                  repository: FirestorePlannerRepository(store),
                  nutrition: nutrition,
                  generator: WeeklyPlanGenerator(catalog: realCatalog),
                  today: DateTime(2026, 11, 22),
                );
                cubit.show(
                  PlannerState(
                    status: mode == 'error'
                        ? PlannerStatus.error
                        : mode == 'loading'
                        ? PlannerStatus.loading
                        : PlannerStatus.ready,
                    weekStart: DateTime(2026, 11, 21),
                    plan: mode == 'loaded' ? plan : null,
                  ),
                );
                screen = PlannerScreen(cubit: cubit);
                addTearDown(cubit.close);
              case 'shopping':
                final cubit = VisualShoppingCubit(
                  userId: 'u1',
                  repository: FirestoreShoppingRepository(store),
                  foods: foods,
                );
                cubit.show(
                  ShoppingState(
                    list: const ShoppingListModel(
                      listId: 'current',
                      title: 'Fixture',
                      planId: null,
                      status: 'active',
                    ),
                    status: mode == 'error'
                        ? ShoppingStatus.error
                        : mode == 'loading'
                        ? ShoppingStatus.loading
                        : ShoppingStatus.ready,
                    items: mode == 'loaded'
                        ? const [
                            ShoppingListItemModel(
                              itemId: 'a',
                              name: 'طماطم',
                              quantity: 500,
                              unit: 'g',
                              category: 'produce',
                              isPurchased: true,
                            ),
                            ShoppingListItemModel(
                              itemId: 'b',
                              name: 'حليب',
                              quantity: 1000,
                              unit: 'g',
                              category: 'dairy',
                              isPurchased: false,
                            ),
                          ]
                        : const [],
                  ),
                );
                screen = ShoppingScreen(cubit: cubit, currentPlan: plan);
                addTearDown(cubit.close);
              case 'ramadan':
                final cubit = VisualRamadanCubit(
                  clock: () => DateTime(2026, 3, 1, 12),
                  userId: 'u1',
                  settings: PrefsRamadanSettingsStore(
                    preferences: prefs,
                    userId: 'u1',
                  ),
                  nutrition: nutrition,
                  foods: foods,
                );
                cubit.show(
                  RamadanState(
                    status: mode == 'error'
                        ? RamadanStatus.error
                        : mode == 'loading'
                        ? RamadanStatus.loading
                        : RamadanStatus.ready,
                    times: mode == 'empty'
                        ? null
                        : const RamadanTimes(
                            iftarMinutes: 1050,
                            suhoorEndMinutes: 240,
                            taraweehMinutes: 1200,
                          ),
                    suggestions: mode == 'loaded'
                        ? RamadanSuggester(
                            catalog: realCatalog,
                          ).suggest(dailyCalorieTarget: 2000)
                        : const [],
                    waterMl: 750,
                    cupsFromUser: true,
                  ),
                );
                screen = RamadanScreen(cubit: cubit);
                addTearDown(cubit.close);
            }

            tester.view.physicalSize = const Size(390, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final key = GlobalKey();
            final router = GoRouter(
              routes: [GoRoute(path: '/', builder: (_, __) => screen)],
            );
            addTearDown(router.dispose);
            await tester.pumpWidget(
              RepaintBoundary(
                key: key,
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  routerConfig: router,
                  theme: light ? AppTheme.light() : AppTheme.dark(),
                  locale: Locale(lang),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (c, ch) => MediaQuery(
                    data: MediaQuery.of(c).copyWith(
                      disableAnimations: true,
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: ch!,
                  ),
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(seconds: 1));
            Future<void> shot(String part) async {
              expect(tester.takeException(), isNull);
              await tester.runAsync(() async {
                for (final e in find.byType(Image).evaluate()) {
                  await precacheImage((e.widget as Image).image, e);
                }
                final im =
                    await (key.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage();
                final b = await im.toByteData(format: ui.ImageByteFormat.png);
                await File(
                  '/downloads/sufra-recovered/planning1810_${feature}_${lang}_${light ? 'light' : 'dark'}_${scale}_$part.png',
                ).writeAsBytes(b!.buffer.asUint8List());
                im.dispose();
              });
            }

            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 100)),
            );
            await tester.pump();
            await shot('top');
            if (feature == 'shopping' && lang == 'ar' && scale == 1) {
              final row = find.text('حليب').last;
              await tester.ensureVisible(row);
              await tester.pump();
              final mouse = await tester.createGesture(
                kind: PointerDeviceKind.mouse,
              );
              await mouse.addPointer(location: const Offset(2, 2));
              for (var n = 0; n < 30; n++) {
                if (n == 5) await mouse.moveTo(tester.getCenter(row));
                if (n == 10) await mouse.down(tester.getCenter(row));
                if (n == 20) await mouse.up();
                await tester.pump(const Duration(milliseconds: 90));
                await shot('motion${n.toString().padLeft(3, '0')}');
              }
              expect(find.text('2 / 2'), findsOneWidget);
              await mouse.removePointer();
            }

            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -650),
            );
            await tester.pump(const Duration(milliseconds: 400));
            await shot('scroll');
            await tester.pumpWidget(const SizedBox());
          });
        }
      }
    }
  }
}
