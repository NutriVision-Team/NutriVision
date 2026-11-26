import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/nebula_background.dart';
import 'package:sufradepi/data/models/favorite_model.dart';
import 'package:sufradepi/data/models/meal_entry_model.dart';
import 'package:sufradepi/data/repositories/nutrition_repository.dart';
import 'package:sufradepi/features/favorites/data/favorites_repository.dart';
import 'package:sufradepi/features/favorites/domain/favorites_logic.dart';
import 'package:sufradepi/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:sufradepi/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:sufradepi/features/premium/presentation/screens/premium_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

import '../goldens/milestone1_screens_test.dart' show loadRealFonts;

final now = DateTime(2026, 11, 22, 12);

MealItemModel item(
  String id,
  String name, {
  double? protein,
  double kcal = 100,
}) => MealItemModel(
  foodId: id,
  foodName: name,
  quantity: 1,
  unit: 'g',
  weightInGrams: 100,
  calories: kcal,
  protein: protein,
  carbohydrates: null,
  fat: null,
  fiber: null,
  sugar: null,
  sodium: null,
  dataSource: 'catalog',
  confidence: null,
);

MealEntryModel meal(
  String id,
  String title,
  List<MealItemModel> items, {
  String uid = 'u1',
  DateTime? at,
  double? kcal,
  double? protein,
}) => MealEntryModel(
  mealId: id,
  userId: uid,
  dateKey: '2026-11-22',
  consumedAt: at ?? now.subtract(const Duration(days: 1)),
  mealType: 'lunch',
  inputMethod: 'catalog',
  title: title,
  items: items,
  totalCalories:
      kcal ?? items.fold<double>(0, (sum, item) => sum + item.calories),
  totalProtein: protein,
  totalCarbs: null,
  totalFat: null,
  totalFiber: null,
  totalSugar: null,
  totalSodium: null,
  analysisStatus: 'confirmed',
);

class FakeNutrition implements NutritionRepository {
  List<MealEntryModel> meals = [];
  bool failSave = false;
  int saves = 0;
  @override
  Future<void> saveMealEntry(String uid, MealEntryModel m) async {
    saves++;
    if (failSave) throw StateError('x');
    meals = [...meals.where((e) => e.mealId != m.mealId), m];
  }

  @override
  Future<List<MealEntryModel>> getMealEntries(
    String uid, {
    String? dateKey,
  }) async => meals;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeBackend implements FavoritesBackend {
  List<FavoriteModel> docs = [];
  bool fail = false;
  @override
  Future<List<FavoriteModel>> loadAll(String uid) async {
    if (fail) throw StateError('x');
    return docs;
  }

  @override
  Future<void> saveIfAbsent(String uid, FavoriteModel m) async {
    if (docs.any((d) => d.favoriteId == m.favoriteId)) return;
    docs = [...docs, m];
  }

  @override
  Future<void> remove(
    String uid,
    String id, {
    required String expectedType,
  }) async {
    if (fail) throw StateError('x');
    docs = docs.where((d) => d.favoriteId != id).toList();
  }
}

FavoriteModel fav(String type, String target, String title, {int day = 1}) =>
    FavoriteModel(
      favoriteId: type == 'meal' ? mealFavoriteId(target) : '${type}_$target',
      targetId: target,
      targetType: type,
      title: title,
      createdAt: DateTime(2026, 11, day),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  test(
    'persistent food favorite loads and removes without touching counters',
    () async {
      final b = FakeBackend()
        ..docs = [
          fav('food', 'rice', 'Rice'),
          fav('internal_food_repeat', 'rice', ''),
        ];
      final c = FavoritesCubit(
        uid: 'u1',
        currentUid: () => 'u1',
        backend: b,
        nutrition: FakeNutrition(),
      );
      await c.load();
      expect(c.state.foods, hasLength(1));
      await c.remove(c.state.foods.single);
      expect(c.state.foods, isEmpty);
      expect(b.docs.single.targetType, 'internal_food_repeat');
      await c.close();
    },
  );
  group('logic', () {
    test('frequent foods: window, owner, once per meal, skips blanks', () {
      final ms = [
        meal('a', 'A', [item('rice', 'رز'), item('rice', 'رز'), item('', 'x')]),
        meal('b', 'B', [item('rice', 'رز'), item('egg', 'بيض')]),
        meal('c', 'C', [
          item('egg', 'بيض'),
        ], at: now.subtract(const Duration(days: 40))),
        meal('d', 'D', [item('egg', 'بيض')], uid: 'other'),
        meal('e', 'E', [
          item('egg', 'بيض'),
        ], at: now.add(const Duration(days: 2))),
      ];
      final f = frequentFoods(ms, uid: 'u1', now: now);
      expect(f.map((e) => (e.foodId, e.count)), [('rice', 2), ('egg', 1)]);
    });
    test('most logged meal', () {
      final ms = [
        meal('a', 'فول', []),
        meal('b', 'فول', []),
        meal('c', 'عدس', []),
      ];
      expect(mostLoggedMeal(ms, uid: 'u1', now: now)!.count, 2);
      expect(mostLoggedMeal([], uid: 'u1', now: now), isNull);
    });
    test('calorie sort puts unavailable last, never zero', () {
      final v = [
        FavoriteMealView(fav('meal', 'x', 'gone'), null),
        FavoriteMealView(
          fav('meal', 'a', 'low'),
          meal('a', 'low', [], kcal: 100),
        ),
        FavoriteMealView(
          fav('meal', 'b', 'high'),
          meal('b', 'high', [], kcal: 500),
        ),
      ];
      expect(
        sortMeals(v, FavoritesSort.calories).map((e) => e.favorite.title),
        ['high', 'low', 'gone'],
      );
      expect(sortMeals(v, FavoritesSort.recent).length, 3);
    });
    test('copy keeps nulls, items and source; new id and date', () {
      final m = meal('a', 'فول', [item('f', 'فول')], protein: null);
      final c = mealCopyForDiary(
        m,
        uid: 'u1',
        id: 'n',
        at: DateTime(2026, 11, 22, 9),
        mealType: 'breakfast',
      );
      expect(c.totalProtein, isNull);
      expect(c.mealId, 'n');
      expect(c.mealType, 'breakfast');
      expect(c.dateKey, '2026-11-22');
      expect(c.items.single.protein, isNull);
      expect(c.analysisStatus, 'confirmed');
    });
  });

  group('cubit', () {
    late FakeNutrition nut;
    late FakeBackend be;
    String? current;
    FavoritesCubit make() => FavoritesCubit(
      uid: 'u1',
      currentUid: () => current,
      backend: be,
      nutrition: nut,
      clock: () => now,
    );
    setUp(() {
      nut = FakeNutrition();
      be = FakeBackend();
      current = 'u1';
    });

    test(
      'load resolves meals, hides foreign meals, keeps other types out',
      () async {
        nut.meals = [
          meal('a', 'فول', [item('f', 'فول')]),
          meal('z', 'سري', [], uid: 'other'),
        ];
        be.docs = [
          fav('meal', 'a', 'فول'),
          fav('meal', 'z', 'سري'),
          fav('meal', 'gone', 'محذوفة'),
          fav('recipe', 'r1', 'وصفة'),
          fav('food', 'f1', 'ignored'),
        ];
        final c = make();
        await c.load();
        expect(c.state.status, FavoritesStatus.ready);
        expect(c.state.meals.length, 3);
        expect(
          c.state.meals
              .where((m) => m.available)
              .map((m) => m.favorite.targetId),
          ['a'],
        );
        expect(c.state.recipes.single.targetId, 'r1');
        await c.close();
      },
    );

    test('remove success and failure keep list truthful', () async {
      be.docs = [fav('meal', 'a', 'فول'), fav('recipe', 'r1', 'وصفة')];
      final c = make();
      await c.load();
      be.fail = true;
      await c.remove(c.state.recipes.single);
      expect(c.state.notice, FavoritesNotice.removeFailed);
      expect(c.state.recipes.length, 1);
      be.fail = false;
      await c.remove(c.state.recipes.single);
      expect(c.state.recipes, isEmpty);
      expect(be.docs.length, 1);
      await c.close();
    });

    test('add to diary: retry reuses same id, no double log', () async {
      nut.meals = [
        meal('a', 'فول', [item('f', 'فول')]),
      ];
      be.docs = [fav('meal', 'a', 'فول')];
      final c = make();
      await c.load();
      nut.failSave = true;
      await c.addToDiary(c.state.meals.single, 'dinner');
      expect(c.state.notice, FavoritesNotice.addFailed);
      nut.failSave = false;
      await c.addToDiary(c.state.meals.single, 'dinner');
      expect(c.state.notice, FavoritesNotice.added);
      expect(nut.meals.where((m) => m.inputMethod == 'relog').length, 1);
      await c.close();
    });

    test('unavailable meal cannot be added', () async {
      be.docs = [fav('meal', 'gone', 'x')];
      final c = make();
      await c.load();
      await c.addToDiary(c.state.meals.single, 'lunch');
      expect(nut.saves, 0);
      await c.close();
    });

    test('account switch: late results are dropped, nothing written', () async {
      nut.meals = [
        meal('a', 'فول', [item('f', 'فول')]),
      ];
      be.docs = [fav('meal', 'a', 'فول')];
      final c = make();
      await c.load();
      current = 'u2';
      await c.addToDiary(c.state.meals.single, 'lunch');
      await c.remove(c.state.meals.single.favorite);
      expect(nut.saves, 0);
      expect(be.docs.length, 1);
      await c.close();
    });

    test('load failure then retry; favoriteMeal is idempotent', () async {
      nut.meals = [
        meal('a', 'فول', [item('f', 'فول')]),
      ];
      be.fail = true;
      final c = make();
      await c.load();
      expect(c.state.status, FavoritesStatus.failure);
      be.fail = false;
      await c.favoriteMeal(nut.meals.single);
      await c.favoriteMeal(nut.meals.single);
      expect(be.docs.length, 1);
      expect(c.state.meals.single.available, isTrue);
      await c.close();
    });
  });

  group('screens', () {
    Widget wrap(Widget child, {Locale locale = const Locale('ar')}) =>
        MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: MaterialApp(
            theme: AppTheme.dark(),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            home: NebulaBackground(child: child),
          ),
        );
    Future<void> show(WidgetTester t, Widget w) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      t.view.devicePixelRatio = 1;
      await t.runAsync(() async {
        await t.pumpWidget(w);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await t.pump(const Duration(milliseconds: 400));
    }

    Future<FavoritesCubit> cubit(FakeNutrition n, FakeBackend b) async {
      final c = FavoritesCubit(
        uid: 'u1',
        currentUid: () => 'u1',
        backend: b,
        nutrition: n,
        clock: () => now,
      );
      await c.load();
      return c;
    }

    Widget screen(FavoritesCubit c) =>
        wrap(BlocProvider.value(value: c, child: const FavoritesScreen()));

    testWidgets('meals tab golden, remove and add flows', (t) async {
      final n = FakeNutrition()
        ..meals = [
          meal(
            'a',
            'فول وطعمية',
            [item('f', 'فول', kcal: 320, protein: 12)],
            kcal: 320,
            protein: 12,
          ),
          meal(
            'a2',
            'فول وطعمية',
            [item('f', 'فول', kcal: 320, protein: 12)],
            kcal: 320,
            protein: 12,
          ),
          meal('b', 'سلطة', [item('s', 'سلطة', kcal: 90)], kcal: 90),
        ];
      final b = FakeBackend()
        ..docs = [
          fav('meal', 'a', 'فول وطعمية'),
          fav('meal', 'b', 'سلطة', day: 2),
          fav('meal', 'gone', 'كشري', day: 3),
        ];
      final c = await cubit(n, b);
      await show(t, screen(c));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/fav_meals.png'),
      );
      expect(find.text('الوجبة الأصلية اتمسحت'), findsOneWidget);
      // add to diary through meal type sheet
      await t.tap(find.byIcon(Icons.add_rounded).first);
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 900));
      expect(find.text('عشا'), findsOneWidget);
      await t.tap(find.text('عشا'));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump(const Duration(milliseconds: 400));
      expect(
        n.meals.where((m) => m.inputMethod == 'relog').single.mealType,
        'dinner',
      );
      // remove
      await t.tap(find.byTooltip('شيل من المفضلة').first);
      await t.pump(const Duration(milliseconds: 400));
      expect(b.docs.length, 2);
      await t.pumpWidget(const SizedBox.shrink());
      await c.close();
    });

    testWidgets('recipes, frequent, empty and error states', (t) async {
      final n = FakeNutrition()
        ..meals = [
          meal('a', 'غدا', [item('rice', 'رز أبيض')]),
          meal('b', 'عشا', [item('rice', 'رز أبيض')]),
        ];
      final b = FakeBackend()
        ..docs = [
          fav('recipe', 'r1', 'شوربة عدس'),
          fav('recipe', 'r2', 'ملوخية'),
        ];
      var c = await cubit(n, b);
      await show(t, screen(c));
      await t.tap(find.text('وصفات محفوظة'));
      await t.pump(const Duration(milliseconds: 100));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 600));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/fav_recipes.png'),
      );
      await t.tap(find.text('الأكتر تسجيلًا').last);
      await t.pump(const Duration(milliseconds: 100));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('رز أبيض'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/fav_frequent.png'),
      );
      await t.pumpWidget(const SizedBox.shrink());
      await c.close();

      c = await cubit(FakeNutrition(), FakeBackend());
      await show(t, screen(c));
      expect(find.text('لسه مفيش وجبات مفضلة'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/fav_empty.png'),
      );
      await t.pumpWidget(const SizedBox.shrink());
      await c.close();

      c = await cubit(FakeNutrition(), FakeBackend()..fail = true);
      await show(t, screen(c));
      expect(find.text('معرفناش نحمّل المفضلة.'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
      await c.close();
    });

    testWidgets('hero hearts animate, and stop with reduced motion', (t) async {
      final n = FakeNutrition()
        ..meals = [
          meal('a', 'فول', [item('f', 'فول')]),
        ];
      final c = await cubit(n, FakeBackend());
      await show(t, screen(c));
      expect(t.hasRunningAnimations, isTrue);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          child: MaterialApp(
            theme: AppTheme.dark(),
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider.value(value: c, child: const FavoritesScreen()),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
      expect(t.hasRunningAnimations, isFalse);
      await t.pumpWidget(const SizedBox.shrink());
      await c.close();
    });

    testWidgets('premium: no price, trial or purchase; disabled CTA; en too', (
      t,
    ) async {
      await show(t, wrap(const PremiumScreen()));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/premium_ar.png'),
      );
      expect(find.textContaining('٩٩'), findsNothing);
      expect(find.textContaining('٧٢٩'), findsNothing);
      expect(find.textContaining('تجربة'), findsNothing);
      expect(find.textContaining('مجان'), findsNothing);
      expect(find.textContaining('دفع'), findsNothing);
      expect(find.text('ابدأ تجربة مجانية'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      await show(t, wrap(const PremiumScreen(), locale: const Locale('en')));
      expect(find.text('Sufra Premium'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
    });
  });
}
