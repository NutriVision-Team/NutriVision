import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/app_states.dart';
import '../../data/off_cache.dart';
import '../../data/off_client.dart';
import '../../domain/off_product.dart';
import '../../domain/product_lookup_service.dart';
import '../cubit/barcode_cubit.dart';
import 'barcode_scanner_screen.dart';

class OwnedOffProduct {
  const OwnedOffProduct(this.ownerUid, this.product);
  final String ownerUid;
  final OffProduct product;
}

/// Keeps the scan history inside one authenticated route lifetime. Product
/// requests are globally rate-limited, while private scan history is not shared.
class BarcodeAccountScope extends StatefulWidget {
  const BarcodeAccountScope({
    super.key,
    required this.userId,
    required this.activeUserId,
    required this.onOpenProduct,
    required this.onPhotoFallback,
    required this.onSearchFallback,
  });
  final String userId;
  final String? Function() activeUserId;
  final Future<void> Function(OffProduct) onOpenProduct;
  final VoidCallback? onPhotoFallback;
  final VoidCallback? onSearchFallback;
  @override
  State<BarcodeAccountScope> createState() => _BarcodeAccountScopeState();
}

class _BarcodeAccountScopeState extends State<BarcodeAccountScope> {
  static final OffClient _client = OffClient();
  late Future<ProductLookupService?> _load;
  OffCache? _cache;
  @override
  void initState() {
    super.initState();
    _load = _initialize();
  }

  Future<ProductLookupService?> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || widget.activeUserId() != widget.userId) return null;
    final cache = OffCache(
      prefs,
      ownerUid: widget.userId,
      activeUserId: widget.activeUserId,
    );
    _cache = cache;
    return ProductLookupService(client: _client, cache: cache);
  }

  @override
  void dispose() {
    // This includes account switches. In-flight writes also check generation.
    final cache = _cache;
    if (cache != null) unawaited(cache.clear().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ProductLookupService?>(
    future: _load,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: AppErrorView(
            onRetry: () => setState(() {
              _load = _initialize();
            }),
          ),
        );
      }
      final service = snapshot.data;
      if (service == null) return const Scaffold(body: AppLoadingView());
      return BlocProvider(
        create: (_) => BarcodeCubit(service),
        child: BarcodeScannerScreen(
          onOpenProduct: widget.onOpenProduct,
          onPhotoFallback: widget.onPhotoFallback,
          onSearchFallback: widget.onSearchFallback,
        ),
      );
    },
  );
}
