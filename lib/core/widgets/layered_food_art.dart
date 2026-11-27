import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Native port of the HTML .w3d rig: nine depth layers, 1700ms entrance,
/// drag rotation, inertial release and the source's gentle resting tilt.
class LayeredFoodArt extends StatefulWidget {
  const LayeredFoodArt({super.key, required this.asset, required this.hint});
  final String asset;
  final String hint;
  @override
  State<LayeredFoodArt> createState() => _LayeredFoodArtState();
}

class _LayeredFoodArtState extends State<LayeredFoodArt>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _yaw = -720;
  double _velocity = 0;
  double _scale = .55;
  double _pitch = 10;
  bool _dragging = false;
  bool _intro = true;
  bool _reducedMotion = false;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) {
      _ticker.stop();
      _yaw = 0;
      _scale = 1;
      _pitch = 4;
      _intro = false;
    } else if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final ms = elapsed.inMicroseconds / 1000;
    final dt = _last == Duration.zero
        ? 1.0
        : ((elapsed - _last).inMicroseconds / 16667).clamp(0.0, 3.0);
    _last = elapsed;
    setState(() {
      if (_intro) {
        final k = (ms / 1700).clamp(0.0, 1.0);
        final eased = 1 - math.pow(1 - k, 4);
        _yaw = (-720 * (1 - eased)).toDouble();
        _scale = .55 + .45 * math.min(1, eased * 1.15);
        if (k == 1) {
          _intro = false;
          _yaw = 0;
          _scale = 1;
        }
      } else if (!_dragging) {
        _yaw += _velocity * dt;
        _velocity *= math.pow(.94, dt);
        final target = math.sin(ms / 1900) * 24;
        final turns = ((_yaw - target) / 360).round() * 360;
        if (_velocity.abs() < 1.2) {
          _yaw += (target + turns - _yaw) * (1 - math.pow(.95, dt));
        }
      }
      _pitch = 7 + math.cos(ms / 2300) * 3;
    });
  }

  @override
  void didUpdateWidget(covariant LayeredFoodArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _yaw = 0;
      _scale = 1;
      _velocity = 0;
      _intro = false;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radians = _yaw * math.pi / 180;
    final layers = List.generate(9, (i) => i)
      ..sort(
        (a, b) => ((8 - a * 3) * math.cos(radians)).compareTo(
          (8 - b * 3) * math.cos(radians),
        ),
      );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => setState(() {
        _dragging = true;
        _velocity = 0;
        _intro = false;
        _scale = 1;
      }),
      onHorizontalDragUpdate: (details) => setState(() {
        final delta = details.delta.dx * .8;
        _yaw += delta;
        _velocity = delta;
      }),
      onHorizontalDragEnd: (_) => setState(() {
        _dragging = false;
      }),
      onHorizontalDragCancel: () => setState(() {
        _dragging = false;
      }),
      child: SizedBox(
        width: 330,
        height: 300,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            for (final layer in layers)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 300,
                child: Transform(
                  key: ValueKey('food-depth-$layer'),
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, -1 / 850)
                    ..scaleByDouble(_scale, _scale, _scale, 1)
                    ..rotateX(_pitch * math.pi / 180)
                    ..rotateY(radians)
                    ..translateByDouble(
                      0.0,
                      0.0,
                      (8 - layer * 3).toDouble(),
                      1,
                    ),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      layer == 0
                          ? Colors.white
                          : layer == 8
                          ? const Color(0xFFE6E6E6)
                          : const Color(0xFF9E9E9E),
                      BlendMode.modulate,
                    ),
                    child: Image.asset(widget.asset, fit: BoxFit.contain),
                  ),
                ),
              ),
            Positioned(
              bottom: -26,
              left: 0,
              right: 0,
              child: Text(
                widget.hint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFD8E0EF)
                      : const Color(0xFF465062),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
