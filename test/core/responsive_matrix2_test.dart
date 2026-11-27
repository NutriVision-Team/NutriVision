import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/data/models/water_log_model.dart';
import 'package:sufradepi/data/models/weight_log_model.dart';
import 'package:sufradepi/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:sufradepi/features/barcode/data/off_cache.dart';
import 'package:sufradepi/features/barcode/data/off_client.dart';
import 'package:sufradepi/features/barcode/domain/off_product.dart';
import 'package:sufradepi/features/barcode/domain/product_lookup_service.dart';
import 'package:sufradepi/features/barcode/presentation/cubit/barcode_cubit.dart';
import 'package:sufradepi/features/barcode/presentation/screens/barcode_scanner_screen.dart';
import 'package:sufradepi/features/barcode/presentation/screens/product_result_screen.dart';
import 'package:sufradepi/features/camera_analysis/presentation/camera_analysis_screen.dart';
import 'package:sufradepi/features/camera_analysis/presentation/capture_device.dart';
import 'package:sufradepi/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:sufradepi/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:sufradepi/data/repositories/food_repository.dart';
import 'package:sufradepi/features/food_catalog/data/local_food_repository.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/food_detail_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/food_search_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_detail_screen.dart';
import 'package:sufradepi/features/meal_log/presentation/screens/meal_review_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/stats_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/water_screen.dart';
import 'package:sufradepi/features/progress/presentation/screens/weight_screen.dart';
import 'package:sufradepi/features/voice_logging/voice_meal_screen.dart';

import '../discovery/discovery_features_test.dart'
    show CaptureAchievements, StaticActivityLoader, activity;
import '../barcode/barcode_domain_test.dart'
    show nutella, FakeTransport, cfg, ok;
import '../favorites/favorites_test.dart'
    show FakeNutrition, FakeBackend, now, meal, item, fav;
import '../features/camera_analysis/camera_screen_test.dart'
    show FixtureCaptureDevice;
import '../features/progress/progress_test.dart' show FakeWaterWeightRepository;
import '../features/voice_logging/voice_flow_test.dart' show FixtureDictation;
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

const _sizes = <String, Size>{
  'phone360': Size(360, 800),
  'phone390': Size(390, 844),
  'tabletP': Size(800, 1280),
  'tabletL': Size(1280, 800),
  'desktop': Size(1440, 900),
};
const _variants = <String, (String, bool)>{
  'ar-dark': ('ar', false),
  'en-light': ('en', true),
};

void main() {
  setUpAll(loadRealFonts);
  final only = Platform.environment['ONLY'];
  bool want(String n) => only == null || only.split(',').contains(n);

  for (final n in ['stats', 'water', 'weight']) {
    if (!want(n)) continue;
    testWidgets('matrix2 $n', (t) async {
      final h = await Harness.signedIn();
      final repo = FakeWaterWeightRepository()
        ..weight = [
          WeightLogModel(
            weightId: 'a',
            weightKg: 88.2,
            recordedAt: DateTime(2026, 11, 22, 7),
            dateKey: '2026-11-22',
          ),
          WeightLogModel(
            weightId: 'b',
            weightKg: 89.4,
            recordedAt: DateTime(2026, 11, 15, 7),
            dateKey: '2026-11-15',
          ),
        ]
        ..water = [
          WaterLogModel(
            waterId: 'w1',
            amountMl: 250,
            consumedAt: DateTime(2026, 11, 22, 8),
            dateKey: '2026-11-22',
          ),
          WaterLogModel(
            waterId: 'w2',
            amountMl: 500,
            consumedAt: DateTime(2026, 11, 22, 11),
            dateKey: '2026-11-22',
          ),
        ];
      await _run(
        t,
        n,
        h,
        (_) => switch (n) {
          'stats' => StatsScreen(waterWeightRepository: repo),
          'water' => WaterScreen(waterWeightRepository: repo),
          _ => WeightScreen(waterWeightRepository: repo),
        },
      );
      await h.dispose();
    });
  }

  if (want('achievements')) {
    testWidgets('matrix2 achievements', (t) async {
      final h = await Harness.signedIn();
      await _run(
        t,
        'achievements',
        h,
        (_) => AchievementsScreen(
          userId: 'owner',
          todayKey: '2026-11-22',
          catalog: CaptureAchievements(),
          loader: StaticActivityLoader(
            activity(days: {'2026-11-21', '2026-11-22'}),
          ),
        ),
      );
      await h.dispose();
    });
  }

  if (want('favorites')) {
    testWidgets('matrix2 favorites', (t) async {
      final h = await Harness.signedIn();
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
            ], kcal: 432),
            meal('m2', 'بيض وجبنة', [
              item('usda_foundation_748967', 'بيض'),
            ], kcal: 310),
          ],
        clock: () => now,
      );
      await t.runAsync(c.load);
      await _run(
        t,
        'favorites',
        h,
        (_) => BlocProvider.value(value: c, child: const FavoritesScreen()),
      );
      await h.dispose();
    });
  }

  for (final n in ['barcode', 'product', 'camera', 'voice']) {
    if (!want(n)) continue;
    testWidgets('matrix2 $n', (t) async {
      final h = await Harness.signedIn();
      SharedPreferences.setMockInitialValues({});
      final data = nutella();
      data['product']['image_front_url'] = null;
      data['product']['image_url'] = null;
      final cubit = BarcodeCubit(
        ProductLookupService(
          client: OffClient(
            config: cfg,
            transport: FakeTransport((_, _) => ok(nutella())),
          ),
          cache: OffCache(await SharedPreferences.getInstance()),
        ),
      );
      await _run(
        t,
        n,
        h,
        (_) => switch (n) {
          'barcode' => BlocProvider.value(
            value: cubit,
            child: const BarcodeScannerScreen(),
          ),
          'product' => ProductResultScreen(
            product: OffProduct.fromV3('3017620422003', data)!,
          ),
          'camera' => CameraAnalysisScreen(
            device: FixtureCaptureDevice(CaptureStatus.ready),
          ),
          _ => VoiceMealScreen(dictation: FixtureDictation()),
        },
      );
      await h.dispose();
    });
  }

  for (final n in ['foodsearch', 'fooddetail', 'mealdetail', 'mealreview']) {
    if (!want(n)) continue;
    testWidgets('matrix2 $n', (t) async {
      final h = await Harness.signedIn();
      final repo = LocalFoodRepository();
      final food = await t.runAsync(() => repo.getFoodById('usda_sr_168878'));
      final portion = FoodPortion(food!, 150);
      final m = portion.toMeal(
        uid: 'u1',
        id: 'fixture',
        at: DateTime(2026, 11, 22, 14),
        mealType: 'lunch',
      );
      h.nutritionRepository.meals = [m];
      await _run(
        t,
        n,
        h,
        (_) => switch (n) {
          'foodsearch' => const FoodSearchScreen(),
          'fooddetail' => FoodDetailScreen(food: food),
          'mealdetail' => MealDetailScreen(
            mealId: m.mealId,
            dateKey: m.dateKey,
          ),
          _ => MealReviewScreen(portion: portion),
        },
        around: (w) =>
            RepositoryProvider<FoodRepository>.value(value: repo, child: w),
      );
      await h.dispose();
    });
  }
}

Future<void> _run(
  WidgetTester t,
  String name,
  Harness h,
  Widget Function(int) build, {
  Widget Function(Widget)? around,
}) async {
  addTearDown(t.view.reset);
  final problems = <String>[];
  final prevOnError = FlutterError.onError;
  FlutterError.onError = (d) {
    problems.add('ERR ${d.exceptionAsString().split('\n').first}');
    File(
      'build/matrix/err_${problems.length}.txt',
    ).writeAsStringSync(d.toString());
  };
  addTearDown(() => FlutterError.onError = prevOnError);
  for (final s in _sizes.entries) {
    for (final v in _variants.entries) {
      t.view.physicalSize = s.value;
      t.view.devicePixelRatio = 1;
      final key = GlobalKey();
      try {
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: (around ?? (w) => w)(
              h.wrap(
                build(0),
                appShell: true,
                locale: Locale(v.value.$1),
                themeMode: v.value.$2 ? ThemeMode.light : ThemeMode.dark,
              ),
            ),
          ),
        );
        await t.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          final ctx = t.element(find.byType(Scaffold).first);
          for (final a in const [
            'assets/images/art/neb.jpg',
            'assets/images/art/spA.webp',
          ]) {
            await precacheImage(AssetImage(a), ctx);
          }
        });
        await t.pump(const Duration(seconds: 1));
        await t.pump(const Duration(seconds: 1));
        t.takeException();
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/matrix').createSync(recursive: true);
          File(
            'build/matrix/${s.key}__${name}__${v.key}.png',
          ).writeAsBytesSync(b!.buffer.asUint8List());
          im.dispose();
        });
      } catch (err) {
        problems.add(
          '${s.key}/${v.key}: THROW ${err.toString().split('\n').first}',
        );
      }
    }
  }
  await t.pumpWidget(const SizedBox());
  File('build/matrix/problems.txt').writeAsStringSync(
    '$name: ${problems.isEmpty ? 'ok' : problems.join(' | ')}\n',
    mode: FileMode.append,
  );
}
