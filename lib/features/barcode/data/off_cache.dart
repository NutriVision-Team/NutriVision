import '../domain/barcode_code.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/off_product.dart';

/// On-device cache of looked-up products. It holds only public product data
/// (name, nutrients), not who scanned it, and is never uploaded or bundled
/// (Open Food Facts data is ODbL: attribute, share-alike, review before any
/// redistribution). Production entries are account-scoped and cleared when the scanner route
/// closes, including sign-out: scanned products are personal history.
class OffCache {
  OffCache(
    this._prefs, {
    DateTime Function()? now,
    this.foundTtl = const Duration(days: 7),
    this.missTtl = const Duration(hours: 6),
    this.maxEntries = 100,
    this.ownerUid,
    this.activeUserId,
  }) : _now = now ?? DateTime.now;

  static const _basePrefix = 'off_cache_v1_';
  final String? ownerUid;
  final String? Function()? activeUserId;
  int _generation = 0;
  bool get isActive => ownerUid == null || activeUserId?.call() == ownerUid;
  String get _prefix => ownerUid == null
      ? _basePrefix
      : '${_basePrefix}account:${base64Url.encode(utf8.encode(ownerUid!))}:';
  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final Duration foundTtl;
  final Duration missTtl;
  final int maxEntries;

  /// null = no usable entry. [CachedMiss] = recently confirmed not found.
  CacheEntry? read(String canonicalCode) {
    if (!isActive) return null;
    final raw = _prefs.getString('$_prefix$canonicalCode');
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.fromMillisecondsSinceEpoch(j['at'] as int);
      final age = _now().difference(at);
      if (age.isNegative) return null;
      if (j['miss'] == true) {
        return age <= missTtl ? CachedMiss(at) : null;
      }
      if (age > foundTtl) return null;
      final p = OffProduct.fromJson(Map<String, dynamic>.from(j['p'] as Map));
      return p == null ||
              BarcodeCode.tryParse(p.barcode)?.canonical != canonicalCode
          ? null
          : CachedProduct(p, at);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeProduct(String canonicalCode, OffProduct p) =>
      _write(canonicalCode, {'p': p.toJson()});

  Future<void> writeMiss(String canonicalCode) =>
      _write(canonicalCode, {'miss': true});

  Future<void> _write(String code, Map<String, dynamic> body) async {
    if (!isActive) return;
    final generation = _generation;
    await _prefs.setString(
      '$_prefix$code',
      jsonEncode({'at': _now().millisecondsSinceEpoch, ...body}),
    );
    if (!isActive || generation != _generation) {
      await _prefs.remove('$_prefix$code');
      return;
    }
    await _trim();
  }

  Future<void> _trim() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    if (keys.length <= maxEntries) return;
    final stamped = <MapEntry<String, int>>[];
    for (final k in keys) {
      try {
        final j = jsonDecode(_prefs.getString(k)!) as Map<String, dynamic>;
        stamped.add(MapEntry(k, j['at'] as int));
      } catch (_) {
        stamped.add(MapEntry(k, 0));
      }
    }
    stamped.sort((a, b) => a.value.compareTo(b.value));
    for (final e in stamped.take(keys.length - maxEntries)) {
      await _prefs.remove(e.key);
    }
  }

  Future<void> clear() async {
    ++_generation;
    for (final k
        in _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await _prefs.remove(k);
    }
  }
}

sealed class CacheEntry {
  const CacheEntry(this.at);
  final DateTime at;
}

class CachedProduct extends CacheEntry {
  const CachedProduct(this.product, super.at);
  final OffProduct product;
}

class CachedMiss extends CacheEntry {
  const CachedMiss(super.at);
}
