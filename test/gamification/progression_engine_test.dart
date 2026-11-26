import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/gamification/domain/progression_engine.dart';

void main() {
  late ProgressionEngine engine;
  ProgressionEvent e(
    String id, {
    String kind = 'meal',
    String day = '2026-11-24',
    String uid = 'u',
  }) => ProgressionEvent(uid: uid, sourceId: id, kind: kind, dayKey: day);
  setUp(
    () => engine = ProgressionEngine(
      ProgressionConfig.fromJson(
        jsonDecode(File('assets/data/progression.json').readAsStringSync()),
      ),
    ),
  );
  test('empty starts at zero, no fictional awards', () {
    final p = engine.project('u', '2026-11-24', []);
    expect(p.xp, 0);
    expect(p.badges, isEmpty);
    expect(p.level.id, 'beginner');
  });
  test('duplicate meal and edits cannot mint extra XP', () {
    final p = engine.project('u', '2026-11-24', [e('m1'), e('m1'), e('m2')]);
    expect(p.xp, 10);
    expect(p.counts['meal'], 2);
    expect(p.badges, {'first_meal'});
  });
  test('future days are not eligible', () {
    expect(
      engine.project('u', '2026-11-24', [e('m', day: '2026-11-25')]).xp,
      0,
    );
  });
  test('mismatched account fails closed', () {
    expect(
      () => engine.project('u', '2026-11-24', [e('m', uid: 'other')]),
      throwsStateError,
    );
  });
  test('conflicting identity fails instead of double reward', () {
    expect(
      () => engine.project('u', '2026-11-24', [
        e('m'),
        e('m', day: '2026-11-23'),
      ]),
      throwsStateError,
    );
  });
  test('invalid date normalization rejected', () {
    expect(() => engine.project('u', '2026-02-30', []), throwsFormatException);
  });
  test('yesterday grace and durable best streak', () {
    final p = engine.project('u', '2026-11-24', [
      e('a', day: '2026-11-21'),
      e('b', day: '2026-11-22'),
      e('c', day: '2026-11-23'),
    ]);
    expect(p.currentStreak, 3);
    expect(p.bestStreak, 3);
    final missed = engine.project('u', '2026-11-26', [
      e('a', day: '2026-11-21'),
      e('b', day: '2026-11-22'),
      e('c', day: '2026-11-23'),
    ]);
    expect(missed.currentStreak, 0);
    expect(missed.bestStreak, 3);
    expect(missed.xp, p.xp);
    expect(missed.badges, p.badges);
  });
  test('active days badge does not require consecutive days', () {
    final p = engine.project('u', '2026-11-24', [
      for (var i = 0; i < 7; i++)
        e('m$i', day: '2026-11-${(i * 2 + 1).toString().padLeft(2, '0')}'),
    ]);
    expect(p.badges, contains('active7'));
    expect(p.bestStreak, 1);
  });
  test('no food quantity, weight or calorie restriction reward', () {
    expect(
      () => engine.project('u', '2026-11-24', [e('x', kind: 'weightLoss')]),
      throwsFormatException,
    );
    expect(
      () => engine.project('u', '2026-11-24', [e('x', kind: 'activeDay')]),
      throwsFormatException,
    );
  });
  test('level threshold and capped XP per activity per day', () {
    final p = engine.project('u', '2026-11-24', [
      for (var i = 1; i <= 10; i++)
        e('$i', day: '2026-11-${i.toString().padLeft(2, '0')}'),
    ]);
    expect(p.xp, 100);
    expect(p.level.id, 'explorer');
    expect(p.levelProgress, 0);
    expect(p.badges, contains('aware'));
  });
  test('profile reward once, not every source ID', () {
    final p = engine.project('u', '2026-11-24', [
      e('a', kind: 'profile'),
      e('b', kind: 'profile'),
    ]);
    expect(p.xp, 20);
    expect(p.counts['profile'], 1);
  });
  test('projection unaffected by event ordering', () {
    final a = [e('a'), e('b', kind: 'plan'), e('c', day: '2026-11-23')];
    final p = engine.project('u', '2026-11-24', a),
        q = engine.project('u', '2026-11-24', a.reversed);
    expect(p.xp, q.xp);
    expect(p.badges, q.badges);
    expect(p.counts, q.counts);
  });
  test('config must be ordered, known and bounded', () {
    expect(
      () => ProgressionConfig(
        version: 'bad',
        levels: [LevelRule('a', 0, 'a', 'a'), LevelRule('b', 0, 'b', 'b')],
        badges: [],
        dailyXp: {},
      ),
      throwsFormatException,
    );
    expect(
      () => ProgressionConfig(
        version: 'bad',
        levels: [LevelRule('a', 0, 'a', 'a')],
        badges: [],
        dailyXp: {'meal': 1000},
      ),
      throwsFormatException,
    );
  });
}
