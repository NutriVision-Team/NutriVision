import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import 'package:sufradepi/features/health_coach/domain/coach_conversation_tools.dart';
import 'package:sufradepi/features/health_coach/domain/coach_catalog_tools.dart';
import 'package:sufradepi/features/recipes/domain/recipe_catalog_repository.dart';
import '../../planning/coach_retry_test.dart' show AmbiguousCoachStore;
import '../../planning/screens_smoke_test.dart' show SmokeNutritionRepository;
import 'coach_catalog_calculator_test.dart' show Foods;

class DelayedCancelableProvider
    implements HealthCoachProvider, CancellableCoachProvider {
  final entered = Completer<void>();
  final result = Completer<HealthCoachReply>();
  int cancelled = 0;
  @override
  void cancelPending() {
    cancelled++;
  }

  @override
  Future<HealthCoachReply> generate(HealthCoachRequest request) {
    entered.complete();
    return result.future;
  }
}

class DelayedPlanner implements HealthCoachProvider, CoachToolPlanner {
  final entered = Completer<void>();
  final result = Completer<CoachCalculationRequest?>();
  int generated = 0;
  @override
  Future<CoachCalculationRequest?> selectCalculation(String question) {
    entered.complete();
    return result.future;
  }

  @override
  Future<HealthCoachReply> generate(HealthCoachRequest request) async {
    generated++;
    return const HealthCoachReply(
      text: 'A late answer',
      origin: CoachReplyOrigin.ai,
    );
  }
}

void main() {
  for (final invalidation in ['close', 'revoke', 'switch']) {
    test(
      'pending provider after $invalidation never saves or renders late reply',
      () async {
        var uid = 'owner';
        final p = DelayedCancelableProvider();
        final store = AmbiguousCoachStore()..throwAfterAnswer = false;
        final c = CoachCubit(
          userId: 'owner',
          currentUid: () => uid,
          store: store,
          nutrition: SmokeNutritionRepository(),
          locale: 'en',
          healthOrchestrator: HealthCoachOrchestrator(provider: p),
          healthConsent: const HealthCoachConsent(externalAi: true),
        );
        await c.load();
        final pending = c.send('Explain food labels');
        await p.entered.future;
        if (invalidation == 'close') await c.close();
        if (invalidation == 'revoke') {
          c.updateHealthChoices(
            const HealthCoachConsent(),
            const HealthCoachProfile(),
          );
        }
        if (invalidation == 'switch') {
          uid = 'other';
          await c.close();
        }
        expect(p.cancelled, 1);
        p.result.complete(
          const HealthCoachReply(
            text: 'Read the ingredient list',
            origin: CoachReplyOrigin.ai,
          ),
        );
        await pending;
        expect(store.saved.values.where((v) => v.role == 'assistant'), isEmpty);
        if (!c.isClosed) {
          expect(c.state.thinking, false);
          expect(c.externalQuestionEnabled, false);
          await c.close();
        }
      },
    );
  }
  test('cancel during tool planning cannot start later generation', () async {
    final p = DelayedPlanner();
    final o = HealthCoachOrchestrator(
      provider: p,
      conversationTools: CoachConversationTools(
        catalog: CoachCatalogTools(
          foods: Foods(),
          recipes: RecipeCatalogRepository(),
        ),
        reviewedPortions: const {'synthetic': 150},
      ),
    );
    final pending = o.ask(
      question: 'Calculate reviewed meal',
      locale: 'en',
      consent: const HealthCoachConsent(externalAi: true),
      profile: const HealthCoachProfile(),
    );
    await p.entered.future;
    o.cancelPending();
    p.result.complete(CoachCalculationRequest({'synthetic': 150}));
    expect((await pending).origin, CoachReplyOrigin.unavailable);
    expect(p.generated, 0);
  });
}
