import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/features/barcode/data/off_cache.dart';
import 'package:sufradepi/features/barcode/data/off_client.dart';
import 'package:sufradepi/features/barcode/domain/product_lookup_service.dart';
import 'package:sufradepi/features/barcode/presentation/cubit/barcode_cubit.dart';

import 'barcode_domain_test.dart' show FakeTransport, cfg, nutella, ok;

void main() {
  late FakeTransport transport;
  late BarcodeCubit cubit;
  Completer<OffHttpResponse>? gate;

  Future<void> build(
    FutureOr<OffHttpResponse> Function(Uri, Map<String, String>) h,
  ) async {
    SharedPreferences.setMockInitialValues({});
    transport = FakeTransport(h);
    cubit = BarcodeCubit(
      ProductLookupService(
        client: OffClient(config: cfg, transport: transport),
        cache: OffCache(await SharedPreferences.getInstance()),
      ),
    );
  }

  tearDown(() => cubit.close());

  test(
    'same code detected repeatedly while focused is submitted once',
    () async {
      await build((_, _) => ok(nutella()));
      for (var i = 0; i < 6; i++) {
        await cubit.onDetected('3017620422003');
      }
      expect(transport.calls.length, 1);
      expect(cubit.state.phase, BarcodePhase.found);
      expect(cubit.state.product!.name, 'نوتيلا');
    },
  );

  test('detections during an in-flight lookup are ignored', () async {
    gate = Completer<OffHttpResponse>();
    await build((_, _) => gate!.future);
    final first = cubit.onDetected('3017620422003');
    await cubit.onDetected('96385074');
    await cubit.onDetected('3017620422003');
    gate!.complete(ok(nutella()));
    await first;
    expect(transport.calls.length, 1);
  });

  test(
    'non-GTIN camera payload is ignored silently, manual shows invalid',
    () async {
      await build((_, _) => ok(nutella()));
      await cubit.onDetected('hello world');
      expect(cubit.state.phase, BarcodePhase.idle);
      await cubit.submitManual('3017620422004');
      expect(cubit.state.phase, BarcodePhase.invalidCode);
      expect(transport.calls, isEmpty);
    },
  );

  test('offline failure does not lock the code; retry succeeds', () async {
    var offline = true;
    await build((_, _) {
      if (offline) throw const SocketException('down');
      return ok(nutella());
    });
    await cubit.onDetected('3017620422003');
    expect(cubit.state.phase, BarcodePhase.failed);
    expect(cubit.state.failure, OffFailure.offline);
    await cubit.onDetected(
      '3017620422003',
    ); // camera still on same code: allowed
    expect(transport.calls.length, 2);
    offline = false;
    await cubit.retry();
    expect(cubit.state.phase, BarcodePhase.found);
  });

  test(
    'not found leaves scanner usable; same code rescannable after reset',
    () async {
      await build(
        (_, _) => ok({
          'status': 'failure',
          'result': {'id': 'product_not_found'},
        }),
      );
      await cubit.onDetected('3017620422003');
      expect(cubit.state.phase, BarcodePhase.notFound);
      await cubit.onDetected('3017620422003'); // still focused: ignored
      expect(transport.calls.length, 1);
      cubit.reset();
      await cubit.onDetected(
        '3017620422003',
      ); // cache says miss; no new request
      expect(cubit.state.phase, BarcodePhase.notFound);
      expect(transport.calls.length, 1);
    },
  );

  test('rate limited surfaces retryAfter and can retry later', () async {
    var limited = true;
    await build(
      (_, _) => limited
          ? const OffHttpResponse(429, '', retryAfter: Duration(seconds: 1))
          : ok(nutella()),
    );
    await cubit.submitManual('3017620422003');
    expect(cubit.state.phase, BarcodePhase.failed);
    expect(cubit.state.failure, OffFailure.rateLimited);
    limited = false;
    await cubit.retry(); // still blocked by backoff window
    expect(cubit.state.failure, OffFailure.rateLimited);
  });

  test('result for an old request is dropped after reset', () async {
    gate = Completer<OffHttpResponse>();
    await build((_, _) => gate!.future);
    final f = cubit.submitManual('3017620422003');
    cubit.reset();
    gate!.complete(ok(nutella()));
    await f;
    expect(cubit.state.phase, BarcodePhase.idle);
  });

  test('closing the cubit mid-lookup does not throw', () async {
    gate = Completer<OffHttpResponse>();
    await build((_, _) => gate!.future);
    final f = cubit.submitManual('3017620422003');
    await cubit.close();
    gate!.complete(ok(nutella()));
    await f;
  });
}
