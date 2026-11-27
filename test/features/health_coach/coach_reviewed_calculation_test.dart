import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/health_coach/data/http_health_coach_provider.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import 'package:sufradepi/features/health_coach/domain/coach_catalog_tools.dart';
import 'package:sufradepi/features/health_coach/domain/coach_reviewed_explanation.dart';
import 'package:sufradepi/features/recipes/domain/recipe_catalog_repository.dart';
import '../../planning/coach_retry_test.dart' show AmbiguousCoachStore;
import '../../planning/screens_smoke_test.dart' show SmokeNutritionRepository;
import 'coach_catalog_calculator_test.dart' show Foods;

void main() {
  test(
    'reviewed calculation traverses actual HTTP adapter and cubit; unknown protein stays separate',
    () async {
      var calls = 0;
      final provider = HttpHealthCoachProvider(
        endpoint: Uri.parse('https://coach.invalid/chat'),
        allowedHosts: {'coach.invalid'},
        userId: 'a',
        currentUid: () => 'a',
        idToken: () async => 'synthetic',
        client: MockClient((r) async {
          calls++;
          final data = jsonDecode(r.body) as Map;
          expect(data['context']['reviewedCalculation'], [
            {'foodId': 'synthetic', 'grams': 150.0},
          ]);
          expect(data['question'], isNot(contains('150')));
          return http.Response(
            jsonEncode({
              'text':
                  'The source calculation describes the selected food, not an exact lab measurement of the prepared meal.',
              'origin': 'ai',
              'sourceIds': [],
              'navigation': [],
              'calculation': {
                'selection': [
                  {'foodId': 'synthetic', 'grams': 150.0},
                ],
                'energyKcal': 150,
                'proteinG': null,
                'catalogVersion': '1.0.0',
                'saved': false,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final c = CoachCubit(
        userId: 'a',
        currentUid: () => 'a',
        store: AmbiguousCoachStore()..throwAfterAnswer = false,
        nutrition: SmokeNutritionRepository(),
        locale: 'en',
        healthOrchestrator: HealthCoachOrchestrator(provider: provider),
        healthConsent: const HealthCoachConsent(externalAi: true),
      );
      await c.load();
      final d = await CoachCatalogTools(
        foods: Foods(),
        recipes: RecipeCatalogRepository(),
      ).calculate({'synthetic': 150});
      await c.send(
        reviewedCalculationQuestion(d, 'en'),
        reviewedCalculation: d,
      );
      expect(calls, 1);
      final e = c.state.entries.last;
      expect(e.origin, 'ai');
      expect(e.stats.any((s) => s.value == '150.0 kcal'), true);
      expect(e.stats.any((s) => s.value == 'Unknown'), true);
      await c.close();
    },
  );
}
