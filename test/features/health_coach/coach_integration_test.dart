import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import '../../planning/coach_retry_test.dart' show AmbiguousCoachStore;
import '../../planning/screens_smoke_test.dart' show SmokeNutritionRepository;

class SyntheticContractProvider implements HealthCoachProvider {
  int calls = 0;
  HealthCoachRequest? request;
  @override
  Future<HealthCoachReply> generate(HealthCoachRequest r) async {
    calls++;
    request = r;
    return const HealthCoachReply(
      text: 'Read the ingredient list',
      origin: CoachReplyOrigin.ai,
    );
  }
}

void main() {
  test(
    'existing Coach routes stay rules-based without explicit provider and consent',
    () async {
      final spy = SyntheticContractProvider();
      final c = CoachCubit(
        userId: 'u',
        store: AmbiguousCoachStore()..throwAfterAnswer = false,
        nutrition: SmokeNutritionRepository(),
        locale: 'en',
        healthOrchestrator: HealthCoachOrchestrator(provider: spy),
      );
      await c.load();
      await c.send('hello');
      expect(spy.calls, 0);
      expect(c.state.entries.last.origin, 'rules');
      await c.close();
    },
  );
  test(
    'consented adapter reaches orchestrator and preserves origin across reload',
    () async {
      final spy = SyntheticContractProvider();
      final store = AmbiguousCoachStore()..throwAfterAnswer = false;
      final c = CoachCubit(
        userId: 'u',
        store: store,
        nutrition: SmokeNutritionRepository(),
        locale: 'en',
        healthOrchestrator: HealthCoachOrchestrator(provider: spy),
        healthConsent: const HealthCoachConsent(externalAi: true),
      );
      await c.load();
      await c.send('Explain labels');
      expect(spy.calls, 1);
      expect(spy.request!.context, isEmpty);
      expect(c.state.entries.last.origin, 'ai');
      await c.load();
      expect(c.state.entries.last.origin, 'ai');
      await c.close();
    },
  );
  test(
    'safety response is not mislabeled AI and quick numeric tools stay deterministic',
    () async {
      final spy = SyntheticContractProvider();
      final c = CoachCubit(
        userId: 'u',
        store: AmbiguousCoachStore()..throwAfterAnswer = false,
        nutrition: SmokeNutritionRepository(),
        locale: 'en',
        healthOrchestrator: HealthCoachOrchestrator(provider: spy),
        healthConsent: const HealthCoachConsent(externalAi: true),
      );
      await c.load();
      await c.send('I have chest pain');
      expect(spy.calls, 0);
      expect(c.state.entries.last.origin, 'safety');
      await c.send('', quickId: 'water');
      expect(spy.calls, 0);
      expect(c.state.entries.last.origin, 'rules');
      await c.close();
    },
  );
  test(
    'profile edit changes permitted context and revoke stops later inference',
    () async {
      final spy = SyntheticContractProvider();
      final c = CoachCubit(
        userId: 'u',
        store: AmbiguousCoachStore()..throwAfterAnswer = false,
        nutrition: SmokeNutritionRepository(),
        locale: 'en',
        healthOrchestrator: HealthCoachOrchestrator(provider: spy),
      );
      await c.load();
      c.updateHealthChoices(
        const HealthCoachConsent(externalAi: true, profileContext: true),
        const HealthCoachProfile(age: 26, preferredFoods: ['lentils']),
      );
      await c.send('Suggest variety');
      expect((spy.request!.context['profile'] as Map)['preferredFoods'], [
        'lentils',
      ]);
      c.updateHealthChoices(
        const HealthCoachConsent(externalAi: true),
        const HealthCoachProfile(age: 26),
      );
      await c.send('Explain labels');
      expect(spy.request!.context, isEmpty);
      final count = spy.calls;
      c.updateHealthChoices(
        const HealthCoachConsent(),
        const HealthCoachProfile(),
      );
      await c.send('hello');
      expect(spy.calls, count);
      expect(c.state.entries.last.origin, 'rules');
      await c.close();
    },
  );
}
