import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/data/repositories/food_repository.dart';
import 'package:sufradepi/features/meal_log/domain/meal_review_input.dart';
import 'package:sufradepi/features/voice_logging/data/dictation_service.dart';
import 'package:sufradepi/features/voice_logging/voice_food_suggestions.dart';
import 'package:sufradepi/features/voice_logging/voice_meal_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;

class VoiceFoods implements FoodRepository {
  static const beans = FoodCatalogModel(
    foodId: 'beans',
    name: 'فول',
    source: 'test fixture',
    nutritionPer100g: {'calories': 100},
  );
  static const bread = FoodCatalogModel(
    foodId: 'bread',
    name: 'عيش',
    source: 'test fixture',
    nutritionPer100g: {'calories': 200},
  );
  final queries = <String>[];
  @override
  Future<List<FoodCatalogModel>> searchFood(String query) async {
    queries.add(query);
    return [if (query.contains('فول')) beans, if (query.contains('عيش')) bread];
  }

  @override
  Future<FoodCatalogModel?> getFoodById(String id) async =>
      id == 'beans' ? beans : null;
}

class FixtureDictation extends DictationService {
  @override
  DictationStatus status = DictationStatus.idle;
  @override
  String text = '';
  int starts = 0, stops = 0, releases = 0;
  @override
  int acquire() => 1;
  @override
  Future<void> start(int lease, String language) async {
    starts++;
    status = DictationStatus.listening;
    notifyListeners();
  }

  @override
  Future<void> stop(int lease) async {
    stops++;
    status = DictationStatus.idle;
    notifyListeners();
  }

  @override
  void release(int lease) {
    releases++;
  }

  void result(String value) {
    text = value;
    notifyListeners();
  }
}

void main() {
  setUpAll(loadRealFonts);
  test(
    'voice suggestions deduplicate foods and do not search spoken amounts as measurements',
    () async {
      final foods = VoiceFoods();
      final result = await VoiceFoodSuggestions(
        foods,
      ).find('اكلت فول وعيش ٢٥٠ جم');
      expect(result.map((f) => f.foodId), ['beans', 'bread']);
      expect(foods.queries, isNot(contains('٢٥٠')));
      expect(foods.queries, isNot(contains('جم')));
    },
  );
  testWidgets(
    'dictation requires tap, preserves manual edits, and carries reviewed foods and notes',
    (tester) async {
      final device = FixtureDictation(), foods = VoiceFoods();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => VoiceMealScreen(dictation: device),
          ),
          GoRoute(
            path: '/meal-review',
            builder: (_, state) {
              final input = state.extra! as MealReviewInput;
              return Scaffold(
                body: Text(
                  '${input.draft.portions.length}|${input.mealType}|${input.notes}',
                ),
              );
            },
          ),
        ],
      );
      await tester.pumpWidget(
        RepositoryProvider<FoodRepository>.value(
          value: foods,
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.dark(),
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(device.starts, 0);
      await tester.tap(find.byTooltip('ابدأ وصف بالصوت'));
      await tester.pump();
      device.result('فول');
      await tester.pump();
      expect(find.text('فول'), findsOneWidget);
      await tester.tap(find.byTooltip('وقف التسجيل'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'فول وعيش');
      device.result('late different transcription');
      await tester.pump();
      expect(find.text('فول وعيش'), findsOneWidget);
      await tester.ensureVisible(find.text('دوّر على الأكل في القاعدة'));
      await tester.tap(find.text('دوّر على الأكل في القاعدة'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('فول'));
      await tester.tap(find.text('فول'));
      await tester.pump();
      await tester.ensureVisible(find.text('عيش'));
      await tester.tap(find.text('عيش'));
      await tester.pump();
      await tester.ensureVisible(find.text('راجع وجبتك'));
      await tester.tap(find.text('راجع وجبتك'));
      await tester.pumpAndSettle();
      expect(find.text('2|lunch|فول وعيش'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(device.releases, 1);
      router.dispose();
    },
  );
  testWidgets(
    'voice unavailable state has editable typing and truthful privacy copy',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final device = FixtureDictation()..status = DictationStatus.unavailable;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: VoiceMealScreen(dictation: device),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
      expect(device.starts, 0);
      await expectLater(
        find.byType(VoiceMealScreen),
        matchesGoldenFile(
          AppTheme.fontFamily == 'Thmanyah Sans'
              ? 'goldens/voice_unavailable.png'
              : 'goldens/voice_unavailable_bundled.png',
        ),
      );
    },
  );
}
