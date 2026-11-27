import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import '../../planning/coach_retry_test.dart' show AmbiguousCoachStore;
import '../../planning/screens_smoke_test.dart' show SmokeNutritionRepository;
import 'coach_integration_test.dart' show SyntheticContractProvider;

void main() {
  test(
    'actual Coach bounded summary has date units unknowns and no IDs; revoke removes it',
    () async {
      final spy = SyntheticContractProvider();
      final c = CoachCubit(
        userId: 'synthetic-owner',
        currentUid: () => 'synthetic-owner',
        store: AmbiguousCoachStore()..throwAfterAnswer = false,
        nutrition: SmokeNutritionRepository(),
        locale: 'en',
        healthOrchestrator: HealthCoachOrchestrator(provider: spy),
        healthConsent: const HealthCoachConsent(
          externalAi: true,
          recordContext: true,
          conversationContext: true,
        ),
        clock: () => DateTime(2026, 11, 25),
      );
      await c.load();
      await c.send('Explain labels');
      final facts = spy.request!.context['facts'] as List;
      expect(facts.length, 6);
      for (final fact in facts.cast<Map>()) {
        expect(fact['date'], '2026-11-25');
        expect(fact['value'], isNull);
        expect(fact['source'], anyOf('diary', 'water_log'));
        expect(fact.keys.toSet(), {'key', 'value', 'source', 'date', 'unit'});
      }
      expect(
        spy.request!.context.toString(),
        isNot(contains('synthetic-owner')),
      );
      await c.send('Another label question');
      expect(
        (spy.request!.context['recentConversation'] as List).length,
        lessThanOrEqualTo(8),
      );
      c.updateHealthChoices(
        const HealthCoachConsent(externalAi: true),
        const HealthCoachProfile(),
      );
      await c.send('Explain variety');
      expect(spy.request!.context, isEmpty);
      await c.close();
    },
  );
  test(
    'context builder rejects raw IDs unsupported facts and durable memory',
    () {
      final result = const CoachContextBuilder().build(
        consent: const HealthCoachConsent(
          externalAi: true,
          recordContext: true,
          durableMemory: true,
        ),
        profile: const HealthCoachProfile(),
        facts: const [
          CoachRecordFact(
            key: 'logged_energy',
            value: 100,
            source: 'meal:private',
            date: '2026-11-25',
            unit: 'kcal',
          ),
        ],
        approvedMemories: const ['private'],
      );
      expect(result['facts'], isEmpty);
      expect(result.containsKey('approvedMemories'), isFalse);
    },
  );
}
