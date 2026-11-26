import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/health_coach/domain/coach_output_safety.dart';

void main() {
  test('unexpected Vietnamese Latin fragment fails closed', () {
    const guard = CoachOutputSafety();
    expect(guard.accepts('استشارة chuyênي صحي'), isFalse);
    expect(guard.accepts('جرب وجبة خفيفة لو جعان'), isTrue);
    expect(guard.accepts('Choose a flexible meal time'), isTrue);
  });
}
