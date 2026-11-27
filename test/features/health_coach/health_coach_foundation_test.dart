import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';

class SpyProvider implements HealthCoachProvider {
  int calls = 0;
  bool fail = false;
  HealthCoachRequest? last;
  @override
  Future<HealthCoachReply> generate(HealthCoachRequest request) async {
    calls++;
    last = request;
    if (fail) throw StateError('quota');
    return const HealthCoachReply(
      text: 'Synthetic provider contract, not live AI',
      origin: CoachReplyOrigin.ai,
    );
  }
}

void main() {
  const profile = HealthCoachProfile(
    preferredFoods: ['lentils'],
    allergens: ['sesame'],
    disclosedConditions: ['kidney disease'],
  );
  test('external consent is fail closed', () async {
    final spy = SpyProvider();
    final result = await HealthCoachOrchestrator(provider: spy).ask(
      question: 'Hello',
      locale: 'en',
      consent: const HealthCoachConsent(),
      profile: profile,
    );
    expect(spy.calls, 0);
    expect(result.origin, CoachReplyOrigin.unavailable);
  });
  test('context choices independent and no identity fields', () {
    final context = const CoachContextBuilder().build(
      consent: const HealthCoachConsent(externalAi: true),
      profile: profile,
      recentConversation: ['private'],
      approvedMemories: ['private'],
    );
    expect(context, isEmpty);
    final shared = const CoachContextBuilder().build(
      consent: const HealthCoachConsent(externalAi: true, profileContext: true),
      profile: profile,
    );
    expect((shared['profile'] as Map)['allergens'], ['sesame']);
    expect(shared.keys, ['profile']);
    expect(shared.toString(), isNot(contains('uid')));
  });
  test('missing nutrition stays null with source', () {
    final context = const CoachContextBuilder().build(
      consent: const HealthCoachConsent(externalAi: true, recordContext: true),
      profile: profile,
      facts: [
        const CoachRecordFact(
          key: 'logged_protein',
          value: null,
          source: 'diary',
          date: '2026-11-25',
          unit: 'g',
        ),
      ],
    );
    final fact = (context['facts'] as List).single as Map;
    expect(fact['value'], isNull);
    expect(fact['source'], 'diary');
    expect(fact['date'], '2026-11-25');
    expect(fact['unit'], 'g');
  });
  for (final q in [
    'I have chest pain',
    'مش قادر اتنفس',
    'change my dose',
    'عايز جرعة انسولين',
    '500 calorie diet',
    'Is my meal safe for my severe peanut allergy?',
    'هل وجبتي آمنة لحساسية الفول السوداني الشديدة؟',
  ]) {
    test('preflight stops provider for $q', () async {
      final spy = SpyProvider();
      final result = await HealthCoachOrchestrator(provider: spy).ask(
        question: q,
        locale: 'ar',
        consent: const HealthCoachConsent(externalAi: true),
        profile: const HealthCoachProfile(),
      );
      expect(result.origin, CoachReplyOrigin.safety);
      expect(spy.calls, 0);
    });
  }
  test(
    'known conditions prevent independent clinical planning even if not shared',
    () async {
      final spy = SpyProvider();
      final result = await HealthCoachOrchestrator(provider: spy).ask(
        question: 'make a diet plan',
        locale: 'en',
        consent: const HealthCoachConsent(externalAi: true),
        profile: profile,
      );
      expect(result.origin, CoachReplyOrigin.safety);
      expect(spy.calls, 0);
    },
  );
  test(
    'consented benign request reaches replaceable provider without profile',
    () async {
      final spy = SpyProvider();
      final result = await HealthCoachOrchestrator(provider: spy).ask(
        question: 'Explain food labels',
        locale: 'en',
        consent: const HealthCoachConsent(externalAi: true),
        profile: profile,
      );
      expect(result.origin, CoachReplyOrigin.ai);
      expect(spy.calls, 1);
      expect(spy.last!.context, isEmpty);
    },
  );
  test('provider failure is unavailable not canned AI', () async {
    final spy = SpyProvider()..fail = true;
    final result = await HealthCoachOrchestrator(provider: spy).ask(
      question: 'Hello',
      locale: 'ar',
      consent: const HealthCoachConsent(externalAi: true),
      profile: const HealthCoachProfile(),
    );
    expect(result.origin, CoachReplyOrigin.unavailable);
    expect(result.proposals, isEmpty);
  });
  test('bounded recent context retains chronological order', () {
    final result = const CoachContextBuilder().build(
      consent: const HealthCoachConsent(
        externalAi: true,
        conversationContext: true,
      ),
      profile: profile,
      recentConversation: List.generate(20, (i) => '$i'),
    );
    expect(result['recentConversation'], List.generate(8, (i) => '${i + 12}'));
  });
}
