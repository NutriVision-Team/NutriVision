import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/off_client.dart';
import '../../domain/barcode_code.dart';
import '../../domain/off_product.dart';
import '../../domain/product_lookup_service.dart';

enum BarcodePhase {
  /// Waiting for a barcode.
  idle,

  /// A valid code was accepted and the lookup is running.
  looking,

  /// Product returned by the source.
  found,

  /// Source answered: no such product (or no usable name).
  notFound,

  /// Text was not a valid GTIN (bad length or check digit).
  invalidCode,

  /// The lookup could not complete. See [BarcodeState.failure].
  failed,
}

class BarcodeState {
  const BarcodeState({
    this.phase = BarcodePhase.idle,
    this.code,
    this.product,
    this.fromCache = false,
    this.failure,
    this.retryAfter,
  });
  final BarcodePhase phase;
  final String? code;
  final OffProduct? product;
  final bool fromCache;
  final OffFailure? failure;
  final Duration? retryAfter;
}

class BarcodeCubit extends Cubit<BarcodeState> {
  BarcodeCubit(this._service) : super(const BarcodeState());
  final ProductLookupService _service;

  /// Code currently being handled or just handled. A scanner that stays
  /// pointed at the same bars fires many detections; they are ignored until
  /// [reset] or a different code arrives.
  String? _focused;
  int _generation = 0;

  /// From the camera. Non-GTIN payloads (e.g. a text Code 128) are ignored
  /// silently so the camera keeps scanning instead of showing errors.
  Future<void> onDetected(String? raw) async {
    if (raw == null || state.phase == BarcodePhase.looking) return;
    final code = BarcodeCode.tryParse(raw);
    if (code == null) return;
    if (_focused == code.canonical) return;
    await _lookup(code.value, code.canonical);
  }

  /// From the manual field. Shows an explicit error for invalid numbers.
  Future<void> submitManual(String text) async {
    if (state.phase == BarcodePhase.looking) return;
    final code = BarcodeCode.tryParse(text);
    if (code == null) {
      emit(
        BarcodeState(
          phase: BarcodePhase.invalidCode,
          code: BarcodeCode.normalize(text),
        ),
      );
      return;
    }
    await _lookup(code.value, code.canonical);
  }

  Future<void> retry() async {
    final c = state.code;
    if (c == null || state.phase == BarcodePhase.looking) return;
    final code = BarcodeCode.tryParse(c);
    if (code == null) return;
    await _lookup(code.value, code.canonical);
  }

  Future<void> _lookup(String value, String canonical) async {
    _focused = canonical;
    final gen = ++_generation;
    emit(BarcodeState(phase: BarcodePhase.looking, code: value));
    LookupResult result;
    try {
      result = await _service.lookup(value);
    } catch (_) {
      // Persistence/plugin errors are not successful lookups. Never strand the spinner.
      result = const LookupFailed(OffFailure.unavailable);
    }
    if (isClosed || gen != _generation) return;
    switch (result) {
      case LookupFound(:final product, :final fromCache):
        emit(
          BarcodeState(
            phase: BarcodePhase.found,
            code: value,
            product: product,
            fromCache: fromCache,
          ),
        );
      case LookupNotFound():
        emit(BarcodeState(phase: BarcodePhase.notFound, code: value));
      case LookupInvalidCode():
        emit(BarcodeState(phase: BarcodePhase.invalidCode, code: value));
      case LookupFailed(:final reason, :final retryAfter):
        // Failures must not lock the scanner on this code: allow rescanning.
        _focused = null;
        emit(
          BarcodeState(
            phase: BarcodePhase.failed,
            code: value,
            failure: reason,
            retryAfter: retryAfter,
          ),
        );
    }
  }

  /// Back to scanning (user dismissed a result). Allows the same code again.
  void reset() {
    _generation++;
    _focused = null;
    emit(const BarcodeState());
  }
}
