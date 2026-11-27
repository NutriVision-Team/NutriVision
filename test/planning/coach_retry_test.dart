import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/data/models/conversation_model.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import 'screens_smoke_test.dart' show SmokeNutritionRepository;

class AmbiguousCoachStore implements CoachStore {
  final saved = <String, ChatMessageModel>{};
  bool throwAfterAnswer = true;
  @override
  Future<List<ChatMessageModel>> loadMessages(String uid) async =>
      saved.values.toList();
  @override
  Future<void> appendMessage(String uid, ChatMessageModel message) async {
    saved[message.messageId] = message;
    if (message.role == 'assistant' && throwAfterAnswer) {
      throwAfterAnswer = false;
      throw StateError('Commit reply lost');
    }
  }
}

void main() {
  test('retry after ambiguous answer commit reuses both message IDs', () async {
    final store = AmbiguousCoachStore();
    final c = CoachCubit(
      userId: 'u1',
      store: store,
      nutrition: SmokeNutritionRepository(),
      locale: 'en',
      idSeed: () => 123,
      clock: () => DateTime(2026, 11, 22),
    );
    await c.load();
    await c.send('hello');
    expect(c.state.sendFailure, true);
    expect(store.saved.length, 2);
    await c.retryPending();
    expect(c.state.sendFailure, false);
    expect(store.saved.length, 2);
    expect(c.state.entries.length, 2);
    expect(c.state.entries.every((e) => e.persisted), true);
    await c.close();
  });
  test(
    'pending failed request cannot be replaced by a different implicit send',
    () async {
      final store = AmbiguousCoachStore();
      final c = CoachCubit(
        userId: 'u1',
        store: store,
        nutrition: SmokeNutritionRepository(),
        locale: 'en',
      );
      await c.load();
      await c.send('hello');
      await c.send('different');
      expect(store.saved.length, 2);
      expect(c.state.sendFailure, true);
      await c.close();
    },
  );
}
