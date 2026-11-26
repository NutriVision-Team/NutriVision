import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Native four-sided version of the design's .sxcb rig. It is decorative;
/// the named actions remain in the accessible cards below it.
class MethodCube extends StatefulWidget {
  const MethodCube({super.key});
  @override
  State<MethodCube> createState() => _MethodCubeState();
}

class _MethodCubeState extends State<MethodCube>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _rotation.stop();
      _rotation.value = 0;
    } else if (!_rotation.isAnimating) {
      _rotation.repeat();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final faces = [
      (l.logHubChipPhoto, Icons.photo_camera_outlined, const Color(0x8C06B6D4)),
      (
        l.logHubChipBarcode,
        Icons.qr_code_scanner_rounded,
        const Color(0x8CFB8C00),
      ),
      (l.logHubChipVoice, Icons.mic_none_rounded, const Color(0x997C3AED)),
      (l.logHubChipSearch, Icons.search_rounded, const Color(0x804ADE80)),
    ];
    return ExcludeSemantics(
      child: SizedBox(
        height: 150,
        child: Center(
          child: AnimatedBuilder(
            animation: _rotation,
            builder: (context, child) {
              final yaw = _rotation.value * math.pi * 2;
              final order = List.generate(4, (i) => i)
                ..sort(
                  (a, b) => math
                      .cos(yaw + a * math.pi / 2)
                      .compareTo(math.cos(yaw + b * math.pi / 2)),
                );
              return SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final i in order)
                      if (math.cos(yaw + i * math.pi / 2) > 0.01)
                        Transform(
                          key: ValueKey('method-cube-face-$i'),
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, -1 / 800)
                            ..rotateX(-16 * math.pi / 180)
                            ..rotateY(yaw + i * math.pi / 2)
                            ..translateByDouble(0.0, 0.0, 48.0, 1),
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: faces[i].$3,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .5),
                              ),
                              gradient: RadialGradient(
                                colors: [
                                  Color.alphaBlend(
                                    Colors.white.withValues(alpha: .03),
                                    faces[i].$3,
                                  ),
                                  Color.alphaBlend(
                                    Colors.white.withValues(alpha: .28),
                                    faces[i].$3,
                                  ),
                                ],
                                radius: .8,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  faces[i].$2,
                                  size: 30,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF0A1022),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  faces[i].$1,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : const Color(0xFF0A1022),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
