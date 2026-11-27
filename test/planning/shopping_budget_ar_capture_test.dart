import '../features/progress/progress_test.dart' show FakeNutritionRepository;
import 'package:sufradepi/data/models/nutrition_profile_model.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/shopping/data/shopping_repository.dart';
import 'package:sufradepi/features/shopping/presentation/cubit/shopping_cubit.dart';
import 'package:sufradepi/features/shopping/presentation/screens/shopping_screen.dart';
import 'package:sufradepi/features/food_catalog/data/datasources/local_food_data_source.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'support/planning_memory_firestore.dart';

void main() {
  setUpAll(loadRealFonts);
  testWidgets(
    'choose source food then persist shopping identity without meal save',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final c = ShoppingCubit(
        userId: 'u',
        nutrition: FakeNutritionRepository()
          ..activeProfile = NutritionProfileModel(
            profileId: 'fixture',
            gender: 'male',
            dateOfBirth: DateTime(2000),
            heightCm: 180,
            currentWeightKg: 80,
            targetWeightKg: 75,
            activityLevel: 'sedentary',
            nutritionGoal: 'maintain',
            dailyCalorieTarget: 197,
            proteinTarget: 100,
            carbsTarget: 100,
            fatTarget: 50,
          ),
        currentUid: () => 'u',
        repository: FirestoreShoppingRepository(PlanningMemoryFirestore()),
        foods: LocalFoodDataSource(),
      );
      await c.load();
      final key = GlobalKey();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => ShoppingScreen(cubit: c),
          ),
        ],
      );
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      await t.tap(find.text('اختار الصنف اللي محتاجه'));
      await t.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.enterText(
        find.widgetWithText(TextField, 'ابحث عن الصنف'),
        'صدر دجاج',
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('166 سعرة لكل 100 جم'), findsOneWidget);
      Future<void> shot(String name) async {
        await t.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await t.pump();
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/downloads/sufra/verification/shopping_selection_ar_$name.png',
          ).writeAsBytes(b!.buffer.asUint8List());
          im.dispose();
        });
      }

      await shot('picker');
      await t.tap(find.text('صدر دجاج مطهو'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await shot('amount');
      expect(find.textContaining('داخل المتبقي المسجل'), findsOneWidget);
      await t.enterText(find.byType(TextFormField), '120');
      await t.pump();
      expect(find.textContaining('أعلى من المتبقي المسجل'), findsOneWidget);
      await shot('amount_over');
      await t.tap(find.text('احفظ كمية التسوق'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(c.state.items.single.quantity, 120);
      expect(c.state.items.single.linkedFoodId, 'usda_foundation_331960');
      await c.load();
      expect(c.state.items.single.linkedFoodId, 'usda_foundation_331960');
      await t.pump();
      await shot('saved');
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await c.close();
      router.dispose();
    },
  );
}
