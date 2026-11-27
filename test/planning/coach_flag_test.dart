import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'screens_smoke_test.dart' show SmokeNutritionRepository;

void main() {
  test(
    'only actual replies, valid reason, session hide and undo, no store write',
    () async {
      var owner = 'u1';
      final store = SessionCoachStore(ownerUid: 'u1', currentUid: () => owner);
      final c = CoachCubit(
        userId: 'u1',
        currentUid: () => owner,
        store: store,
        nutrition: SmokeNutritionRepository(),
        locale: 'en',
      );
      await c.load();
      await c.send('hello');
      final e = c.state.entries.last;
      final before = (await store.loadMessages('u1')).length;
      expect(() => c.flagReply('missing', 'unsafe'), throwsStateError);
      expect(() => c.flagReply(e.id, 'unknown'), throwsArgumentError);
      expect(
        () => c.flagReply(c.state.entries.first.id, 'unsafe'),
        throwsStateError,
      );
      c.flagReply(e.id, 'unsafe');
      expect(c.replyFlagged(e.id), true);
      expect((await store.loadMessages('u1')).length, before);
      c.restoreReply(e.id);
      expect(c.replyFlagged(e.id), false);
      c.flagReply(e.id, 'incorrect');
      owner = 'u2';
      expect(c.replyFlagged(e.id), false);
      expect(() => c.restoreReply(e.id), throwsStateError);
      await c.close();
    },
  );
}
