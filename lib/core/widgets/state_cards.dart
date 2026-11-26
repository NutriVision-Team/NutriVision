import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'sprite_avatar.dart';

/// The six reusable application states from the design's screen 32
/// ("حالات التطبيق"): each state has its own color, icon, motion and CTA so
/// the user instantly understands what is happening.
///
/// Motion is ported from the HTML keyframes: `sxsh` (error shake), `sxdw`
/// (success check draw), `spin` (loading arc), `sxsp` (sparkle twinkle) and
/// `sxpl` (pulse). Animations stop when the platform requests reduced motion.
enum SufraState { empty, error, unsure, loading, success, celebrate }

class SufraStateCard extends StatelessWidget {
  const SufraStateCard({
    super.key,
    required this.state,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final SufraState state;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  Color get _accent => switch (state) {
    SufraState.empty => const Color(0xFF06B6D4),
    SufraState.error => const Color(0xFFEF4444),
    SufraState.unsure => const Color(0xFFFB8C00),
    SufraState.loading => const Color(0xFF1565C0),
    SufraState.success => const Color(0xFF22C55E),
    SufraState.celebrate => const Color(0xFF7C3AED),
  };

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StateIcon(state: state, accent: accent),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF5F7FA),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: const Color(0xFFF5F7FA).withValues(alpha: 0.65),
              ),
            ),
          if (actionLabel != null) ...[
            const SizedBox(height: 2),
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A1022),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StateIcon extends StatefulWidget {
  const _StateIcon({required this.state, required this.accent});

  final SufraState state;
  final Color accent;

  @override
  State<_StateIcon> createState() => _StateIconState();
}

class _StateIconState extends State<_StateIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Duration get _period => switch (widget.state) {
    SufraState.loading => const Duration(milliseconds: 1200),
    SufraState.error => const Duration(milliseconds: 1300),
    SufraState.success => const Duration(milliseconds: 2400),
    _ => const Duration(milliseconds: 1800),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _period);
    final reduceMotion =
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations ==
        true;
    if (!reduceMotion) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return switch (widget.state) {
          SufraState.empty => _Pulsing(
            t: t,
            child: Icon(
              Icons.soup_kitchen_outlined,
              size: 50,
              color: const Color(0xFF67E8F9),
            ),
          ),
          SufraState.error => Transform.translate(
            // sxsh: 0,60,100% -> 0 ; 10,30,50% -> -5px ; 20,40% -> +5px
            offset: Offset(_shake(t), 0),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.accent,
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.5),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          SufraState.unsure => _Pulsing(
            t: t,
            child: const SpriteAvatar(
              asset: 'assets/images/art/spA.webp',
              col: 0,
              row: 0,
              size: 56,
            ),
          ),
          SufraState.loading => Transform.rotate(
            angle: t * 2 * math.pi,
            child: CustomPaint(
              size: const Size(54, 54),
              painter: _ArcPainter(color: widget.accent),
            ),
          ),
          SufraState.success => _Pulsing(
            t: t,
            child: CustomPaint(
              size: const Size(54, 54),
              painter: _CheckPainter(progress: (t * 1.4).clamp(0.0, 1.0)),
            ),
          ),
          SufraState.celebrate => SizedBox(
            width: 84,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < 4; i++)
                  Positioned(
                    left: const [6.0, 68.0, 74.0, 2.0][i],
                    top: const [8.0, 4.0, 38.0, 40.0][i],
                    child: _Sparkle(t: (t + i * 0.28) % 1.0),
                  ),
                Center(
                  child: _Pulsing(
                    t: t,
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      size: 52,
                      color: Color(0xFFFDBA74),
                    ),
                  ),
                ),
              ],
            ),
          ),
        };
      },
    );
  }

  double _shake(double t) {
    if (t < 0.6) {
      final phase = (t / 0.6 * 5).floor();
      final inSegment = (t / 0.6 * 5) % 1;
      if (inSegment > 0.5) return 0;
      return switch (phase) {
        0 || 2 || 4 => -5,
        1 || 3 => 5,
        _ => 0,
      };
    }
    return 0;
  }
}

class _Pulsing extends StatelessWidget {
  const _Pulsing({required this.t, required this.child});

  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // sxpl: 50% -> scale(1.14), opacity .85
    final curve = math.sin(t * math.pi);
    return Transform.scale(
      scale: 1 + 0.14 * curve,
      child: Opacity(opacity: 1 - 0.15 * curve, child: child),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    // sxsp: 50% -> rotate(45deg) scale(1.8) opacity .3
    final curve = math.sin(t * math.pi);
    return Transform.rotate(
      angle: math.pi / 4,
      child: Transform.scale(
        scale: 1 + 0.8 * curve,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFFDBA74).withValues(alpha: 1 - 0.7 * curve),
            borderRadius: BorderRadius.circular(2),
            boxShadow: const [
              BoxShadow(color: Color(0xFFFDBA74), blurRadius: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(rect.center, 22, track);
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: rect.center, radius: 22),
      -math.pi / 2,
      math.pi / 2,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.color != color;
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, 24, Paint()..color = const Color(0xFF22C55E));
    // sxdw: the check path draws itself (stroke-dasharray 44).
    final path = Path()
      ..moveTo(16, 28)
      ..lineTo(24, 36)
      ..lineTo(38, 19);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final metrics = path.computeMetrics().first;
    canvas.drawPath(metrics.extractPath(0, metrics.length * progress), paint);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
