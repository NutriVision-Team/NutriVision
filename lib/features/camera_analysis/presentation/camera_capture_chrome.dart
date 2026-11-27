import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/app_localizations.dart';

class CameraViewfinderCorners extends StatelessWidget {
  const CameraViewfinderCorners({super.key});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: CustomPaint(painter: _CornersPainter()),
    ),
  );
}

class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyanLight
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const length = 34.0;
    for (final offset in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      final dx = offset.dx == 0 ? 1.0 : -1.0;
      final dy = offset.dy == 0 ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(offset.dx, offset.dy + dy * length)
        ..lineTo(offset.dx, offset.dy + dy * 16)
        ..quadraticBezierTo(
          offset.dx,
          offset.dy,
          offset.dx + dx * 16,
          offset.dy,
        )
        ..lineTo(offset.dx + dx * length, offset.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CornersPainter oldDelegate) => false;
}

class CameraCaptureDock extends StatelessWidget {
  const CameraCaptureDock({
    super.key,
    required this.zooms,
    required this.zoom,
    required this.onZoom,
    required this.onCapture,
    required this.onGallery,
  });
  final List<double> zooms;
  final double zoom;
  final ValueChanged<double>? onZoom;
  final VoidCallback? onCapture, onGallery;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final large = MediaQuery.textScalerOf(context).scale(13) > 18;
    final selector = Wrap(
      spacing: 2,
      children: [
        for (final z in zooms)
          ChoiceChip(
            label: Text(
              '${z.toStringAsFixed(z % 1 == 0 ? 0 : 1)}×',
              textDirection: TextDirection.ltr,
            ),
            selected: zoom == z,
            showCheckmark: false,
            onSelected: onZoom == null ? null : (_) => onZoom!(z),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
    final shutter = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cyanLight, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.turquoise.withValues(alpha: .35),
            blurRadius: 18,
          ),
        ],
      ),
      child: IconButton.filled(
        onPressed: onCapture,
        tooltip: l.cameraCapture,
        iconSize: 32,
        padding: const EdgeInsets.all(14),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFE5E7FF),
          foregroundColor: AppColors.blueDeep,
        ),
        icon: const Icon(Icons.camera),
      ),
    );
    final gallery = IconButton(
      onPressed: onGallery,
      tooltip: l.cameraGallery,
      icon: const Icon(Icons.photo_library_outlined),
    );
    return GlassCard(
      borderColor: AppColors.orangeLight.withValues(alpha: .5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 28,
      child: large
          ? Column(
              children: [
                selector,
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [shutter, gallery],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: selector),
                shutter,
                Expanded(child: gallery),
              ],
            ),
    );
  }
}
