import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sufradepi/features/barcode/data/off_client.dart';

class PendingClient extends http.BaseClient {
  bool closed = false, aborted = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final r = request as http.AbortableRequest;
    await r.abortTrigger;
    aborted = true;
    throw http.RequestAbortedException(request.url);
  }

  @override
  void close() {
    closed = true;
  }
}

void main() {
  test('transport timeout aborts actual request and closes client', () async {
    final c = PendingClient();
    final t = IoOffTransport(
      timeout: const Duration(milliseconds: 10),
      clientFactory: () => c,
    );
    await expectLater(
      t.get(Uri.parse('https://test.invalid'), headers: const {}),
      throwsA(isA<http.RequestAbortedException>()),
    );
    expect(c.closed, true);
    expect(c.aborted, true);
  });
}
