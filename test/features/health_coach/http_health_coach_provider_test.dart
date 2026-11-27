import 'dart:convert';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sufradepi/features/health_coach/data/http_health_coach_provider.dart';
import 'package:sufradepi/features/health_coach/domain/health_coach_orchestrator.dart';
import 'package:sufradepi/features/health_coach/domain/coach_output_safety.dart';

void main() {
  const request = HealthCoachRequest(
    question: 'Food labels',
    locale: 'en',
    context: {},
  );
  final valid = {
    'text': 'Read the ingredient list',
    'origin': 'ai',
    'sourceIds': [],
    'navigation': ['diary'],
  };
  HttpHealthCoachProvider provider(
    http.Client client, {
    String host = 'coach.invalid',
    String? Function()? currentUid,
  }) => HttpHealthCoachProvider(
    endpoint: Uri.parse('https://$host/chat'),
    allowedHosts: {'coach.invalid'},
    userId: 'a',
    currentUid: currentUid ?? () => 'a',
    idToken: () async => 'synthetic-token',
    client: client,
  );
  http.Response response(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
  test(
    'explicit backend and auth contract, no redirect or action execution',
    () async {
      var calls = 0;
      final p = provider(
        MockClient((r) async {
          calls++;
          expect(r.followRedirects, false);
          expect(r.headers['authorization'], 'Bearer synthetic-token');
          expect(
            (jsonDecode(r.body) as Map)['consentVersion'],
            'coach-external-v1',
          );
          expect((jsonDecode(r.body) as Map)['context'], isEmpty);
          return response(valid);
        }),
      );
      expect((await p.generate(request)).text, valid['text']);
      expect(calls, 1);
    },
  );
  test('unapproved destination and inactive account never send', () async {
    var calls = 0;
    final client = MockClient((r) async {
      calls++;
      return response(valid);
    });
    await expectLater(
      provider(client, host: 'other.invalid').generate(request),
      throwsStateError,
    );
    await expectLater(
      provider(client, currentUid: () => 'b').generate(request),
      throwsStateError,
    );
    expect(calls, 0);
  });
  test('account switch while awaiting response drops reply', () async {
    var uid = 'a';
    final p = provider(
      MockClient((r) async {
        uid = 'b';
        return response(valid);
      }),
      currentUid: () => uid,
    );
    await expectLater(p.generate(request), throwsStateError);
  });
  for (final item in [
    {'text': 'x', 'origin': 'rules', 'sourceIds': [], 'navigation': []},
    {
      ...valid,
      'sourceIds': ['invented'],
    },
    {
      ...valid,
      'navigation': ['delete'],
    },
    {...valid, 'tool': 'write'},
  ]) {
    test('invalid response rejected: $item', () async {
      await expectLater(
        provider(MockClient((r) async => response(item))).generate(request),
        throwsStateError,
      );
    });
  }
  for (final status in [302, 401, 429, 503]) {
    test('HTTP $status is unavailable, never fallback AI', () async {
      await expectLater(
        provider(
          MockClient((r) async => response(valid, status)),
        ).generate(request),
        throwsStateError,
      );
    });
  }
  test('oversized stream rejected', () async {
    await expectLater(
      provider(
        MockClient((r) async => response({...valid, 'text': 'x' * 25000})),
      ).generate(request),
      throwsStateError,
    );
  });
  test('independent output policy Arabic digits and unsafe claims', () {
    const policy = CoachOutputSafety();
    for (final s in [
      'Eat 200 kcal',
      'كل ٢٠٠ سعر',
      'خذ ۲ جرعة',
      'https://bad.invalid',
      'Stop your medication',
      'زود الجرعة',
      'guaranteed safe',
    ]) {
      expect(policy.accepts(s), false, reason: s);
    }
    expect(
      policy.accepts(
        'Read the ingredient list and ask a qualified clinician about your personal needs.',
      ),
      true,
    );
  });
  test(
    'explicit cancel aborts transport and late response cannot render',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      late http.AbortableRequest captured;
      final p = provider(
        MockClient.streaming((r, body) async {
          captured = r as http.AbortableRequest;
          entered.complete();
          await release.future;
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(valid))),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final pending = p.generate(request);
      final rejected = expectLater(pending, throwsStateError);
      await entered.future;
      p.cancelPending();
      await captured.abortTrigger;
      release.complete();
      await rejected;
    },
  );
  test('parallel requests rejected instead of queued or duplicated', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    var calls = 0;
    final p = provider(
      MockClient((r) async {
        calls++;
        entered.complete();
        await release.future;
        return response(valid);
      }),
    );
    final first = p.generate(request);
    await entered.future;
    await expectLater(p.generate(request), throwsStateError);
    release.complete();
    await first;
    expect(calls, 1);
  });
  test(
    'deadline aborts transport, bounds await and permits a later request',
    () async {
      final observedAbort = Completer<void>();
      var calls = 0;
      final client = MockClient.streaming((r, body) async {
        calls++;
        if (calls > 1) {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(valid))),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        await (r as http.AbortableRequest).abortTrigger;
        observedAbort.complete();
        throw http.RequestAbortedException(r.url);
      });
      final p = HttpHealthCoachProvider(
        endpoint: Uri.parse('https://coach.invalid/chat'),
        allowedHosts: {'coach.invalid'},
        userId: 'a',
        currentUid: () => 'a',
        idToken: () async => 'synthetic-token',
        client: client,
        timeout: const Duration(milliseconds: 30),
      );
      await expectLater(
        p.generate(request),
        throwsA(
          anyOf(isA<TimeoutException>(), isA<http.RequestAbortedException>()),
        ),
      );
      await observedAbort.future;
      expect((await p.generate(request)).text, valid['text']);
      expect(calls, 2);
    },
  );
}
