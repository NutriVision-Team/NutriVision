import 'package:go_router/go_router.dart';
import 'package:sufradepi/data/models/food_catalog_model.dart';
import 'package:sufradepi/features/meal_log/domain/catalog_meal_draft.dart';
import 'package:sufradepi/features/meal_log/domain/food_portion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_screen.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../planning/coach_retry_test.dart' show AmbiguousCoachStore;
import '../../planning/screens_smoke_test.dart'
    show SmokeNutritionRepository, FakeCoachDictation;
import 'coach_integration_test.dart' show SyntheticContractProvider;

void main() {
  testWidgets(
    'Coach photo-return bridge previews corrected foods and shares no image only after approval',
    (t) async {
      t.view.physicalSize = const Size(430, 1100);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final p = SyntheticContractProvider();
      final c = CoachCubit(
        userId: 'synthetic',
        currentUid: () => 'synthetic',
        store: AmbiguousCoachStore()..throwAfterAnswer = false,
        nutrition: SmokeNutritionRepository(),
        locale: 'en',
        healthOrchestrator: HealthCoachOrchestrator(provider: p),
        healthConsent: const HealthCoachConsent(externalAi: true),
      );
      await c.load();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => Scaffold(
              body: CoachScreen(cubit: c, dictation: FakeCoachDictation()),
            ),
          ),
          GoRoute(
            path: '/camera',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => context.pop(
                  CatalogMealDraft([
                    FoodPortion(
                      FoodCatalogModel(
                        foodId: 'usda_sr_172184',
                        name: 'Egg white',
                        source: 'USDA',
                        foodState: 'raw',
                        nutritionPer100g: const {
                          'calories': 55,
                          'protein': 10.7,
                        },
                      ),
                      150,
                    ),
                  ]),
                ),
                child: const Text('Return corrected draft'),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await t.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await t.pump(const Duration(seconds: 1));
      Future<void> open() async {
        await t.ensureVisible(find.byKey(const ValueKey('coach_review_photo')));
        await t.tap(find.byKey(const ValueKey('coach_review_photo')));
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        await t.tap(find.text('Return corrected draft'));
        await t.pump(const Duration(seconds: 1));
      }

      await open();
      expect(find.text('Review these foods with Coach?'), findsOneWidget);
      expect(p.request, isNull);
      await t.tap(find.text('Back'));
      await t.pump(const Duration(seconds: 1));
      expect(p.request, isNull);
      await open();
      await t.tap(find.text('Share and review'));
      await t.pump(const Duration(seconds: 1));
      expect(p.request!.context['reviewedCalculation'], isA<List>());
      expect(
        p.request!.context.keys.any((k) => k.toLowerCase().contains('image')),
        false,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await c.close();
    },
  );
  testWidgets(
    'reviewed meal Coach handoff previews and sends only after explicit approval',
    (t) async {
      final p = SyntheticContractProvider();
      final c = CoachCubit(
        userId: 'synthetic',
        currentUid: () => 'synthetic',
        store: AmbiguousCoachStore()..throwAfterAnswer = false,
        nutrition: SmokeNutritionRepository(),
        locale: 'en',
        healthOrchestrator: HealthCoachOrchestrator(provider: p),
        healthConsent: const HealthCoachConsent(externalAi: true),
      );
      await c.load();
      final draft = CatalogMealDraft([
        FoodPortion(
          FoodCatalogModel(
            foodId: 'fixture',
            name: 'Reviewed rice',
            source: 'Synthetic',
            foodState: 'cooked',
            nutritionPer100g: const {'calories': 130},
          ),
          150,
        ),
      ]);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CoachScreen(
              cubit: c,
              dictation: FakeCoachDictation(),
              initialReviewedDraft: draft,
            ),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      final action = find.byKey(const ValueKey('coach_explain_reviewed_meal'));
      await t.ensureVisible(action);
      await t.tap(action);
      await t.pump(const Duration(seconds: 1));
      expect(p.request, isNull);
      expect(find.textContaining('Reviewed rice'), findsWidgets);
      await t.tap(find.text('Back'));
      await t.pump(const Duration(seconds: 1));
      expect(p.request, isNull);
      await t.ensureVisible(action);
      await t.tap(action);
      await t.pump(const Duration(seconds: 1));
      await t.tap(find.text('Share and explain'));
      await t.pump(const Duration(seconds: 1));
      expect(p.request!.context['reviewedCalculation'], isA<List>());
      expect(
        p.request!.context.keys.any((k) => k.toLowerCase().contains('image')),
        false,
      );
      await t.pumpWidget(const SizedBox());
      await c.close();
    },
  );
}
