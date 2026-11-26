import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/gamification/data/trusted_ledger_client.dart';

void main() {
  final enabled =
      Platform.environment['SUFRA_DEMO_LEDGER_HTTP'] == '127.0.0.1:8795';
  test(
    'real loopback HTTP trusted ledger durable request and account/failure isolation',
    () async {
      String uid = 'u', token = 'demo-u';
      final http = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      addTearDown(() => http.close(force: true));
      Future<LedgerResponse> transport(
        String method,
        String path,
        Map<String, Object?>? body,
      ) async {
        final request = await http.openUrl(
          method,
          Uri(scheme: 'http', host: '127.0.0.1', port: 8795, path: path),
        );
        request.headers.set('Authorization', 'Bearer $token');
        request.headers.contentType = ContentType.json;
        if (body != null) request.write(jsonEncode(body));
        final response = await request.close().timeout(
          const Duration(seconds: 8),
        );
        return LedgerResponse(
          response.statusCode,
          (jsonDecode(await utf8.decodeStream(response)) as Map)
              .cast<String, Object?>(),
        );
      }

      final client = TrustedLedgerClient(
        currentUid: () => uid,
        transport: transport,
      );
      expect((await client.load()).profile, isNull);
      await client.requestRecordedActivity('meal', 'httpmeal');
      await client.requestRecordedActivity('meal', 'httpmeal');
      final loaded = await client.load();
      expect(loaded.profile!['totalXp'], 10);
      expect((loaded.profile!['counts'] as Map)['meal'], 1);
      uid = 'other';
      token = 'demo-other';
      expect((await client.load()).profile, isNull);
      await expectLater(
        client.requestRecordedActivity('meal', 'httpmeal'),
        throwsA(isA<TrustedLedgerUnavailable>()),
      );
      expect((await client.load()).profile, isNull);
      token = 'invalid';
      await expectLater(
        client.load(),
        throwsA(isA<TrustedLedgerUnavailable>()),
      );
      uid = 'u';
      token = 'demo-u';
      final slow = TrustedLedgerClient(
        currentUid: () => uid,
        transport: (method, path, body) async {
          final result = await transport(method, path, body);
          uid = 'other';
          return result;
        },
      );
      await expectLater(slow.load(), throwsA(isA<TrustedLedgerUnavailable>()));
      uid = 'u';
      final failed = TrustedLedgerClient(
        currentUid: () => uid,
        transport: (_, _, _) async {
          throw const SocketException('simulated offline');
        },
      );
      await expectLater(failed.load(), throwsA(isA<SocketException>()));
      expect((await client.load()).profile!['totalXp'], 10);
    },
    skip: enabled
        ? false
        : 'Demo-only HTTP runner must start isolated loopback service.',
  );
}
