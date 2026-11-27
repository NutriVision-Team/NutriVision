import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'sufra_badge.dart';
import '../../../../core/widgets/water_glass.dart';
import '../../../../core/widgets/sufra_dialog.dart';

/// Previewable presentation only. Production never calls this as an earned
/// reward until a trusted award event is available.
Future<void> showBadgeCelebration(
  BuildContext context, {
  required String id,
  required String title,
  bool preview = true,
}) => showSufraDialog<void>(
  context: context,
  builder: (_) => BadgeCelebration(id: id, title: title, preview: preview),
);

class BadgeCelebration extends StatefulWidget {
  const BadgeCelebration({
    super.key,
    required this.id,
    required this.title,
    this.preview = true,
  });
  final String id, title;
  final bool preview;
  @override
  State<BadgeCelebration> createState() => _BadgeCelebrationState();
}

class _BadgeCelebrationState extends State<BadgeCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      insetPadding: const EdgeInsets.all(20),
      child: WaterGlass(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/sufra_logo.webp',
                      width: 27,
                      height: 27,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ar ? 'سُفرة' : 'Sufra',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => SizedBox(
                    height: 190,
                    width: 240,
                    child: CustomPaint(
                      painter: _CelebrationPainter(_controller.value),
                      child: Center(
                        child: Transform.scale(
                          scale:
                              .5 +
                              .5 *
                                  Curves.easeOutBack.transform(
                                    (_controller.value / .6).clamp(0, 1),
                                  ),
                          child: Transform.rotate(
                            angle:
                                (1 -
                                    Curves.easeOutCubic.transform(
                                      (_controller.value / .65).clamp(0, 1),
                                    )) *
                                -.25,
                            child: SufraBadge(
                              id: widget.id,
                              unlocked: true,
                              size: 152,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  widget.preview
                      ? (ar
                            ? 'معاينة لحظة الإنجاز'
                            : 'Achievement moment preview')
                      : (ar
                            ? 'خطوة جميلة في رحلتك!'
                            : 'A lovely step forward!'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.preview
                      ? (ar
                            ? 'ده عرض للحركة والتصميم، مش فتح إنجاز أو إضافة نقاط لحسابك.'
                            : 'This shows the design and motion. It does not unlock an achievement or add XP.')
                      : (ar
                            ? 'كل خطوة صغيرة بتبني عادة تدوم. كمّل على مهلك.'
                            : 'Small steps build lasting habits. Keep your own pace.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.6, fontSize: 14),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(ar ? 'تمام' : 'Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2),
        progress = Curves.easeOutCubic.transform(t);
    canvas.drawCircle(
      center,
      55 + 35 * progress,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xff08b8c5).withValues(alpha: .19),
            const Color(0xff08b8c5).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 95)),
    );
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8 - .2,
          r = 45 + 66 * progress,
          p = center + Offset(math.cos(a) * r, math.sin(a) * r * .72);
      final opacity = (math.sin(math.pi * t) * .75 + .15).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = [
          const Color(0xffffc76d),
          const Color(0xff2cd1ba),
          const Color(0xffa99bff),
        ][i % 3].withValues(alpha: opacity);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a + t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: i.isEven ? 4 : 3,
            height: i.isEven ? 10 : 4,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter old) => old.t != t;
}
