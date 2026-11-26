import '../data/off_cache.dart';
import '../data/off_client.dart';
import 'barcode_code.dart';
import 'off_product.dart';

sealed class LookupResult {
  const LookupResult();
}

class LookupFound extends LookupResult {
  const LookupFound(this.product, {required this.fromCache});
  final OffProduct product;
  final bool fromCache;
}

class LookupNotFound extends LookupResult {
  const LookupNotFound();
}

class LookupInvalidCode extends LookupResult {
  const LookupInvalidCode();
}

class LookupFailed extends LookupResult {
  const LookupFailed(this.reason, {this.retryAfter});
  final OffFailure reason;
  final Duration? retryAfter;
}

/// Cache-first, de-duplicated lookup. Concurrent calls for one product share
/// one network request. The account-scoped cache also gates late results.
class ProductLookupService {
  ProductLookupService({required this.client, required this.cache});
  final OffClient client;
  final OffCache cache;
  final Map<String, Future<LookupResult>> _inFlight = {};

  Future<LookupResult> lookup(String input) {
    final code = BarcodeCode.tryParse(input);
    if (code == null) return Future.value(const LookupInvalidCode());
    final key = code.canonical;
    final running = _inFlight[key];
    if (running != null) return running;
    final future = _run(code);
    _inFlight[key] = future;
    // Registered before any caller's await, so the entry is gone by the time
    // a caller continues (a later failure retry must hit the network again).
    future.then<void>(
      (_) => _inFlight.remove(key),
      onError: (_) {
        _inFlight.remove(key);
      },
    );
    return future;
  }

  Future<LookupResult> _run(BarcodeCode code) async {
    if (!cache.isActive) return const LookupFailed(OffFailure.unavailable);
    final hit = cache.read(code.canonical);
    if (hit is CachedProduct) return LookupFound(hit.product, fromCache: true);
    if (hit is CachedMiss) return const LookupNotFound();
    final r = await client.fetch(code);
    if (!cache.isActive) return const LookupFailed(OffFailure.unavailable);
    switch (r) {
      case OffFetched(:final product):
        await cache.writeProduct(code.canonical, product);
        return LookupFound(product, fromCache: false);
      case OffNotFound():
        await cache.writeMiss(code.canonical);
        return const LookupNotFound();
      case OffFailed(:final reason, :final retryAfter):
        return LookupFailed(reason, retryAfter: retryAfter);
    }
  }
}
