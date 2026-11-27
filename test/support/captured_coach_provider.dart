import 'dart:convert';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';

/// Recorded synthetic provider output. Never calls a model or accepts user data.
class CapturedCoachProvider implements HealthCoachProvider {
  @override
  Future<HealthCoachReply> generate(HealthCoachRequest request) async {
    if (request.question !=
            'بشرح بسيط باللهجة المصرية، إزاي أنوع أكلي باستخدام العدس والخضار؟ لا تذكر أرقام تغذية ولا وصفات علاجية.' ||
        request.context.isNotEmpty) {
      throw StateError('Fixed synthetic replay only');
    }
    final value =
        jsonDecode(
              utf8.decode(
                base64Decode(
                  'eyJ0ZXh0IjogItmK2YXZg9mG2YMg2KPZhtmI2KfYuSDYo9mD2YTZiiDYqNin2LPYqtiu2K/Yp9mFINin2YTYudiv2LMg2YjYp9mE2K7Yttin2LEg2KjYt9ix2YIg2YXYrtiq2YTZgdip2Iwg2YXYq9mEINi52YXZhCDYtNmI2LHYqNipINi52K/YsyDYqNin2YTYrti22KfYsSDYo9mIINiq2K3YttmK2LEg2LfYqNmCINmF2YYg2KfZhNi52K/YsyDYp9mE2YXYs9mE2YjZgiDZhdi5INin2YTYrti22KfYsSDYp9mE2YXYtNmI2Yog2KPZiCDYp9mE2LPZhNmC2Iwg2YPZhdinINmK2YXZg9mG2YMg2KXYttin2YHYqSDYp9mE2LnYr9izINil2YTZiSDYp9mE2K3Ys9in2KEg2KPZiCDYp9mE2YrYrtmG2Kkg2YXYuSDYp9mE2K7Yttin2LEg2KfZhNmF2YHYttmE2Kkg2YTYr9mK2YPYjCDYo9mIINin2LPYqtiu2K/Yp9mFINin2YTYudiv2LMg2YHZiiDYudmF2YQg2KfZhNmD2KjYs9ipINij2Ygg2KfZhNmF2YLZhNmI2KjYqSDZhdi5INin2YTYrti22KfYsS4iLCAic291cmNlSWRzIjogW10sICJuYXZpZ2F0aW9uIjogW119',
                ),
              ),
            )
            as Map<String, dynamic>;
    return HealthCoachReply(
      text: value['text'] as String,
      origin: CoachReplyOrigin.ai,
    );
  }
}
