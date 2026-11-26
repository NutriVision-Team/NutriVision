import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_profile.dart';
import '../../support/captured_coach_provider.dart';

void main() {
  test(
    'captured provider output survives real safety pipeline without external data',
    () async {
      final o = HealthCoachOrchestrator(provider: CapturedCoachProvider());
      final r = await o.ask(
        question:
            'بشرح بسيط باللهجة المصرية، إزاي أنوع أكلي باستخدام العدس والخضار؟ لا تذكر أرقام تغذية ولا وصفات علاجية.',
        locale: 'ar',
        consent: const HealthCoachConsent(externalAi: true),
        profile: const HealthCoachProfile(),
        facts: const [],
        history: const [],
      );
      expect(r.origin, CoachReplyOrigin.ai);
      expect(r.text, isNotEmpty);
      final other = await o.ask(
        question: 'Different request',
        locale: 'en',
        consent: const HealthCoachConsent(externalAi: true),
        profile: const HealthCoachProfile(),
        facts: const [],
        history: const [],
      );
      expect(other.origin, CoachReplyOrigin.unavailable);
    },
  );
}
