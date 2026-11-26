import '../../domain/off_product.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/off_client.dart';
import '../../domain/barcode_code.dart';
import '../cubit/barcode_cubit.dart';
import '../widgets/barcode_camera_view.dart';
import 'product_result_screen.dart';

/// Design screen 15. Provide a [BarcodeCubit] above this widget, created
/// INSIDE the signed-in boundary so a different account gets a new one.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({
    super.key,
    this.cameraBuilder = mobileScannerCameraView,
    this.onPhotoFallback,
    this.onSearchFallback,
    this.onOpenProduct,
  });
  static const routePath = '/barcode';

  final CameraViewBuilder cameraBuilder;

  /// Optional: opens the label-photo flow (owned elsewhere). Hidden when null.
  final VoidCallback? onPhotoFallback;

  /// Optional: opens name search. Offered on not-found.
  final VoidCallback? onSearchFallback;
  final Future<void> Function(OffProduct product)? onOpenProduct;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  final _field = TextEditingController();
  late final AnimationController _laser = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );
  bool _cameraOn = false;
  CameraIssue? _issue;
  BarcodeCameraController? _camera;
  bool _torch = false;
  String? _torchNote;
  bool _navigating = false;

  @override
  void dispose() {
    _field.dispose();
    _laser.dispose();
    super.dispose();
  }

  void _startCamera() => setState(() {
    _cameraOn = true;
    _issue = null;
  });

  Future<void> _toggleTorch(AppLocalizations l) async {
    final cam = _camera;
    if (cam == null) {
      setState(() => _torchNote = l.barcodeFlashUnavailable);
      return;
    }
    try {
      final on = await cam.toggleTorch();
      if (mounted) {
        setState(() {
          _torch = on;
          _torchNote = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _torchNote = l.barcodeFlashUnavailable);
    }
  }

  Future<void> _showProduct(BarcodeState s) async {
    if (_navigating || s.product == null) return;
    _navigating = true;
    final cubit = context.read<BarcodeCubit>();
    // Stop the camera while the result is open, then allow rescanning.
    setState(() => _cameraOn = false);
    if (widget.onOpenProduct != null) {
      await widget.onOpenProduct!(s.product!);
    } else {
      await context.push(ProductResultScreen.routePath, extra: s.product);
    }
    _navigating = false;
    if (mounted) {
      _field.clear();
      cubit.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reduce = MediaQuery.of(context).disableAnimations;
    return BlocConsumer<BarcodeCubit, BarcodeState>(
      listenWhen: (a, b) => a.phase != b.phase,
      listener: (context, s) {
        if (s.phase == BarcodePhase.found) _showProduct(s);
      },
      builder: (context, s) {
        final looking = s.phase == BarcodePhase.looking;
        final live = _cameraOn && _issue == null;
        if (live && !reduce && !_laser.isAnimating) {
          _laser.repeat(reverse: true);
        } else if ((!live || reduce) && _laser.isAnimating) {
          _laser.stop();
        }
        final msg = _message(l, s, live);
        final kc = _frameColor(s);
        final digits = BarcodeCode.normalize(_field.text);
        final okLen = digits.length >= 8;
        final valid = BarcodeCode.hasValidLengthAndCheckDigit(digits);
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: NebulaBackground(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, c) {
                  final height = math.max(
                    c.maxHeight,
                    MediaQuery.textScalerOf(context).scale(13) > 18
                        ? 900.0
                        : 740.0,
                  );
                  return SingleChildScrollView(
                    child: SizedBox(
                      height: height,
                      child: Stack(
                        children: [
                          if (live)
                            Positioned.fill(
                              child: widget.cameraBuilder(
                                context,
                                onCode: (v) =>
                                    context.read<BarcodeCubit>().onDetected(v),
                                onIssue: (i) => setState(() => _issue = i),
                                onReady: (cam) => _camera = cam,
                              ),
                            ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _MaskPainter(
                                  frame: _frameRect(c.maxWidth),
                                  dim: live
                                      ? .55
                                      : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? .35
                                            : .06),
                                ),
                              ),
                            ),
                          ),
                          _frame(c.maxWidth, kc, live, s, l),
                          _topBar(l),
                          Positioned(
                            top: 328,
                            left: 16,
                            right: 16,
                            child: Column(
                              children: [
                                _pill(msg, kc, looking),
                                const SizedBox(height: 10),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    runSpacing: 4,
                                    children: [
                                      for (final f in const [
                                        'EAN-13',
                                        'EAN-8',
                                        'UPC',
                                        'Code 128',
                                      ])
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                            color: Colors.white.withValues(
                                              alpha: .1,
                                            ),
                                          ),
                                          child: Text(
                                            f,
                                            style: context.mutedStyle(size: 11),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 14,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: height * .48,
                              ),
                              child: SingleChildScrollView(
                                child: _sheet(
                                  context,
                                  l,
                                  s,
                                  okLen,
                                  valid,
                                  looking,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Rect _frameRect(double w) => Rect.fromLTWH((w - 310) / 2, 108, 310, 196);

  Color _frameColor(BarcodeState s) => switch (s.phase) {
    BarcodePhase.found || BarcodePhase.looking => AppColors.greenLight,
    BarcodePhase.notFound ||
    BarcodePhase.invalidCode ||
    BarcodePhase.failed => AppColors.orangeLight,
    _ => AppColors.cyanLight,
  };

  String _message(AppLocalizations l, BarcodeState s, bool live) {
    switch (s.phase) {
      case BarcodePhase.looking:
        return l.barcodeLooking(s.code ?? '');
      case BarcodePhase.invalidCode:
        return l.barcodeInvalid;
      case BarcodePhase.notFound:
        return l.barcodeNotFound(s.code ?? '');
      case BarcodePhase.failed:
        return _failureText(l, s);
      default:
        break;
    }
    return switch (_issue) {
      CameraIssue.permissionDenied => l.barcodeCameraDenied,
      CameraIssue.unsupported => l.barcodeCameraUnsupported,
      CameraIssue.other => l.barcodeCameraError,
      null => live ? l.barcodeSearching : l.barcodeAim,
    };
  }

  String _failureText(AppLocalizations l, BarcodeState s) =>
      switch (s.failure) {
        OffFailure.notConfigured => l.barcodeNotConfigured,
        OffFailure.offline => l.barcodeOffline,
        OffFailure.rateLimited => l.barcodeRateLimited(
          math.max(1, (s.retryAfter ?? const Duration(seconds: 30)).inSeconds),
        ),
        OffFailure.badResponse => l.barcodeBadResponse,
        _ => l.barcodeUnavailable,
      };

  Widget _frame(
    double w,
    Color kc,
    bool live,
    BarcodeState s,
    AppLocalizations l,
  ) {
    final r = _frameRect(w);
    Widget corner(Alignment a) => Align(
      alignment: a,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          border: Border(
            top: a.y < 0 ? BorderSide(color: kc, width: 4) : BorderSide.none,
            bottom: a.y > 0 ? BorderSide(color: kc, width: 4) : BorderSide.none,
            left: a.x < 0 ? BorderSide(color: kc, width: 4) : BorderSide.none,
            right: a.x > 0 ? BorderSide(color: kc, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(a.x < 0 && a.y < 0 ? 26 : 0),
            topRight: Radius.circular(a.x > 0 && a.y < 0 ? 26 : 0),
            bottomLeft: Radius.circular(a.x < 0 && a.y > 0 ? 26 : 0),
            bottomRight: Radius.circular(a.x > 0 && a.y > 0 ? 26 : 0),
          ),
        ),
      ),
    );
    return Positioned.fromRect(
      rect: r,
      child: Stack(
        children: [
          corner(Alignment.topLeft),
          corner(Alignment.topRight),
          corner(Alignment.bottomLeft),
          corner(Alignment.bottomRight),
          if (live && s.phase == BarcodePhase.idle)
            AnimatedBuilder(
              animation: _laser,
              builder: (_, _) => Positioned(
                left: 12,
                right: 12,
                top: 8 + (r.height - 20) * _laser.value,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.cyanLight,
                        Colors.white,
                        AppColors.cyanLight,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.turquoise.withValues(alpha: .75),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (s.phase == BarcodePhase.found)
            const Center(
              child: Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.greenLight,
              ),
            ),
          if (!live && _issue == null && s.phase == BarcodePhase.idle)
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.turquoise],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.turquoise.withValues(alpha: .5),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: _startCamera,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 11,
                      ),
                      child: Text(
                        l.barcodeStartCamera,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_issue != null)
            Center(
              child: TextButton(
                onPressed: _startCamera,
                child: Text(l.barcodeRetryCamera),
              ),
            ),
        ],
      ),
    );
  }

  Widget _topBar(AppLocalizations l) => Positioned(
    left: 14,
    right: 14,
    top: 10,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _circle(Icons.close, l.barcodeClose, () => context.pop()),
        Expanded(
          child: Text(
            l.barcodeTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        _circle(
          _torch ? Icons.flash_on : Icons.flash_off,
          l.barcodeFlash,
          () => _toggleTorch(l),
          on: _torch,
        ),
      ],
    ),
  );

  Widget _circle(IconData i, String label, VoidCallback f, {bool on = false}) =>
      Semantics(
        button: true,
        label: label,
        child: InkResponse(
          onTap: f,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on
                  ? const Color(0xFFFDE68A)
                  : Colors.white.withValues(alpha: .12),
              border: Border.all(color: Colors.white.withValues(alpha: .28)),
            ),
            child: Icon(
              i,
              size: 20,
              color: on
                  ? AppColors.darkBackground
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      );

  Widget _pill(String text, Color kc, bool busy) => Container(
    constraints: const BoxConstraints(maxWidth: 358),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      color: AppColors.darkBackground.withValues(alpha: .72),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kc,
              boxShadow: [BoxShadow(color: kc, blurRadius: 10)],
            ),
          ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            key: const ValueKey('barcode-message'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _sheet(
    BuildContext context,
    AppLocalizations l,
    BarcodeState s,
    bool okLen,
    bool valid,
    bool looking,
  ) {
    final cubit = context.read<BarcodeCubit>();
    final failed = s.phase == BarcodePhase.failed;
    final notFound = s.phase == BarcodePhase.notFound;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0E1630).withValues(alpha: .86)
            : Colors.white.withValues(alpha: .88),
        border: Border.all(color: AppColors.orangeLight.withValues(alpha: .5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: .3),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(l.barcodeManualLabel, style: context.mutedStyle(size: 12.5)),
          const SizedBox(height: 8),
          if (MediaQuery.textScalerOf(context).scale(13) > 18)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _field,
                    key: const ValueKey('barcode-field'),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 14,
                    enabled: !looking,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (v) => cubit.submitManual(v),
                    style: TextStyle(
                      fontFamily: AppTheme.displayFontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                      letterSpacing: 2.6,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '0000000000000',
                      semanticCounterText: l.barcodeManualField,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: okLen && valid
                              ? AppColors.greenLight
                              : Colors.white.withValues(alpha: .25),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppColors.aiPurple, AppColors.turquoise],
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: looking
                          ? null
                          : () => cubit.submitManual(_field.text),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        child: Text(
                          l.barcodeLookup,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      controller: _field,
                      key: const ValueKey('barcode-field'),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 14,
                      enabled: !looking,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (v) => cubit.submitManual(v),
                      style: TextStyle(
                        fontFamily: AppTheme.displayFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                        letterSpacing: 2.6,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '0000000000000',
                        semanticCounterText: l.barcodeManualField,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: okLen && valid
                                ? AppColors.greenLight
                                : Colors.white.withValues(alpha: .25),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppColors.aiPurple, AppColors.turquoise],
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: looking
                          ? null
                          : () => cubit.submitManual(_field.text),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        child: Text(
                          l.barcodeLookup,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (_torchNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_torchNote!, style: context.mutedStyle(size: 12)),
            ),
          if (notFound)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.barcodeNotFoundHelp,
                style: context.mutedStyle(size: 12),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (failed && s.failure != OffFailure.notConfigured)
                _action(l.barcodeRetry, cubit.retry),
              if (notFound && widget.onSearchFallback != null)
                _action(l.barcodeSearchFallback, widget.onSearchFallback!),
              if (widget.onPhotoFallback != null)
                _action(l.barcodePhotoFallback, widget.onPhotoFallback!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(String label, VoidCallback f) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: f,
    child: Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: .1),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _MaskPainter extends CustomPainter {
  _MaskPainter({required this.frame, required this.dim});
  final Rect frame;
  final double dim;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(26)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF050816).withValues(alpha: dim),
    );
  }

  @override
  bool shouldRepaint(_MaskPainter o) => o.frame != frame || o.dim != dim;
}
