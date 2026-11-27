import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException, HandshakeException;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sufradepi/features/barcode/data/off_client.dart';
import 'package:sufradepi/features/barcode/domain/barcode_code.dart';

/// Scripted client: records closes/aborts and lets a test control the body.
class ScriptClient extends http.BaseClient {
  ScriptClient(this.onSend);
  final Future<http.StreamedResponse> Function(http.AbortableRequest r) onSend;
  bool closed = false;
  http.AbortableRequest? seen;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    seen = request as http.AbortableRequest;
    return onSend(seen!);
  }

  @override
  void close() => closed = true;
}

final code = BarcodeCode.tryParse('3017620422003')!;
const fast = Duration(milliseconds: 80);

OffClient clientWith(
  List<ScriptClient> made,
  ScriptClient Function() make, {
  Duration timeout = fast,
}) => OffClient(
  config: OffConfig(contact: 'team@sufra-app.test', timeout: timeout),
  transport: IoOffTransport(
    timeout: timeout,
    clientFactory: () {
      final c = make();
      made.add(c);
      return c;
    },
  ),
);

http.StreamedResponse ok(
  Stream<List<int>> body, {
  int status = 200,
  Map<String, String> h = const {},
}) => http.StreamedResponse(body, status, headers: h);

void main() {
  test('headers: User-Agent and Accept reach the request', () async {
    final made = <ScriptClient>[];
    final c = clientWith(
      made,
      () => ScriptClient(
        (r) async => ok(
          Stream.value(
            utf8.encode(
              '{"status":"failure","result":{"id":"product_not_found"}}',
            ),
          ),
          status: 404,
        ),
      ),
    );
    expect(await c.fetch(code), isA<OffNotFound>());
    expect(
      made.single.seen!.headers['User-Agent'],
      'Sufra/1.0.0 (team@sufra-app.test)',
    );
    expect(made.single.closed, isTrue);
  });

  test(
    'stall AFTER headers: body stream is aborted, client closed, offline',
    () async {
      final made = <ScriptClient>[];
      final c = clientWith(
        made,
        () => ScriptClient((r) async {
          final ctl = StreamController<List<int>>();
          ctl.add(utf8.encode('{"status":'));
          // body never completes; abort must error the stream
          r.abortTrigger!.then(
            (_) => ctl.addError(http.RequestAbortedException(r.url)),
          );
          return ok(ctl.stream);
        }),
      );
      final sw = Stopwatch()..start();
      final r = await c.fetch(code);
      expect(r, isA<OffFailed>());
      expect((r as OffFailed).reason, OffFailure.unavailable);
      expect(sw.elapsedMilliseconds, lessThan(1500));
      expect(made.single.closed, isTrue);
    },
  );

  test(
    'stall after headers when client ignores abort: fetch still returns at timeout',
    () async {
      final made = <ScriptClient>[];
      final ctl = StreamController<List<int>>();
      final c = clientWith(
        made,
        () => ScriptClient((r) async => ok(ctl.stream)),
      );
      final r = await c.fetch(code).timeout(const Duration(seconds: 2));
      expect((r as OffFailed).reason, OffFailure.unavailable);
      expect(
        made.single.closed,
        isTrue,
        reason: 'socket/fetch must be released',
      );
      await ctl.close();
    },
  );

  test('oversize body: aborted early, badResponse, client closed', () async {
    final made = <ScriptClient>[];
    var emitted = 0;
    final c = clientWith(
      made,
      () => ScriptClient((r) async {
        Stream<List<int>> gen() async* {
          for (var i = 0; i < 100; i++) {
            emitted++;
            yield List.filled(256 * 1024, 0x20);
          }
        }

        return ok(gen());
      }),
      timeout: const Duration(seconds: 5),
    );
    final r = await c.fetch(code);
    expect((r as OffFailed).reason, OffFailure.badResponse);
    expect(emitted, lessThan(12), reason: 'stops reading near the 2 MB cap');
    expect(made.single.closed, isTrue);
    expect(made.single.seen!.headers.containsKey('User-Agent'), isTrue);
  });

  test('invalid UTF-8 is badResponse, not an exception', () async {
    final made = <ScriptClient>[];
    final c = clientWith(
      made,
      () => ScriptClient((r) async => ok(Stream.value([0xff, 0xfe, 0xfd]))),
    );
    expect(((await c.fetch(code)) as OffFailed).reason, OffFailure.badResponse);
    expect(made.single.closed, isTrue);
  });

  test('error mapping: socket, tls, http ClientException, other', () async {
    Future<OffFailure> reasonFor(Object e) async {
      final made = <ScriptClient>[];
      final c = clientWith(made, () => ScriptClient((r) async => throw e));
      final res = await c.fetch(code);
      expect(made.single.closed, isTrue);
      return (res as OffFailed).reason;
    }

    expect(await reasonFor(const SocketException('x')), OffFailure.offline);
    expect(
      await reasonFor(const HandshakeException('x')),
      OffFailure.unavailable,
    );
    // package:http wraps browser fetch failure (offline OR CORS OR dns) like this:
    final browserFailure = await reasonFor(
      http.ClientException('Failed to fetch'),
    );
    // ignore: avoid_print
    print(
      'FINDING: ClientException("Failed to fetch") maps to $browserFailure',
    );
    expect(browserFailure, isNotNull);
  });

  test('unexpected exception types do not escape fetch', () async {
    final made = <ScriptClient>[];
    final c = clientWith(
      made,
      () => ScriptClient((r) async => throw StateError('boom')),
    );
    Object? escaped;
    try {
      await c.fetch(code);
    } catch (e) {
      escaped = e;
    }
    // ignore: avoid_print
    print(
      'FINDING: unexpected exception escapes fetch: ${escaped.runtimeType}',
    );
    expect(
      escaped,
      isNull,
      reason: 'fetch must always return an OffFetchResult',
    );
  });

  test(
    'every call uses a fresh client and closes it (no leak across calls)',
    () async {
      final made = <ScriptClient>[];
      final c = OffClient(
        config: const OffConfig(contact: 'team@sufra-app.test', timeout: fast),
        throttle: RequestThrottle(maxPerWindow: 100),
        transport: IoOffTransport(
          timeout: fast,
          clientFactory: () {
            final k = ScriptClient(
              (r) async => ok(Stream.value(utf8.encode('{}')), status: 200),
            );
            made.add(k);
            return k;
          },
        ),
      );
      for (var i = 0; i < 5; i++) {
        await c.fetch(code);
      }
      expect(made.length, 5);
      expect(made.every((k) => k.closed), isTrue);
    },
  );

  test('429 with Retry-After backs off and sends no further request', () async {
    final made = <ScriptClient>[];
    final c = clientWith(
      made,
      () => ScriptClient(
        (r) async => ok(
          Stream.value(utf8.encode('x')),
          status: 429,
          h: {'retry-after': '30'},
        ),
      ),
      timeout: const Duration(seconds: 2),
    );
    final a = await c.fetch(code) as OffFailed;
    expect(a.reason, OffFailure.rateLimited);
    expect(a.retryAfter, const Duration(seconds: 30));
    final b = await c.fetch(code) as OffFailed;
    expect(b.reason, OffFailure.rateLimited);
    expect(made.length, 1, reason: 'second call must not reach the network');
  });
}
