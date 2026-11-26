import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Decorative achievement badge. Unlock status is provided by real state.
class AchievementVector extends StatelessWidget {
  const AchievementVector({
    super.key,
    required this.index,
    required this.earned,
    this.size = 78,
  });
  final int index;
  final bool earned;
  final double size;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: earned ? 1 : .45,
    child: CustomPaint(size: Size.square(size), painter: _BadgePainter(index)),
  );
}

class _BadgePainter extends CustomPainter {
  const _BadgePainter(this.index);
  final int index;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 100, size.height / 100);
    Paint f(Color color) => Paint()..color = color;
    Paint l(Color color, [double w = 4]) => Paint()
      ..color = color
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cyan = AppColors.cyanLight,
        purple = AppColors.purpleLight,
        gold = AppColors.copper;
    final points = Path();
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6 - math.pi / 2, r = i.isEven ? 43.0 : 36.0;
      final p = Offset(50 + math.cos(a) * r, 48 + math.sin(a) * r);
      if (i == 0) {
        points.moveTo(p.dx, p.dy);
      } else {
        points.lineTo(p.dx, p.dy);
      }
    }
    points.close();
    c.drawPath(points, f(AppColors.primaryBlue));
    c.drawPath(points, l(purple, 2));
    switch (index % 6) {
      case 0:
        c.drawPath(
          Path()
            ..moveTo(32, 25)
            ..lineTo(68, 25)
            ..lineTo(62, 55)
            ..quadraticBezierTo(50, 69, 38, 55)
            ..close(),
          f(gold),
        );
        c.drawArc(
          const Rect.fromLTWH(20, 28, 25, 27),
          1.5,
          3.5,
          false,
          l(cyan),
        );
        c.drawArc(
          const Rect.fromLTWH(55, 28, 25, 27),
          -1.7,
          3.5,
          false,
          l(cyan),
        );
        c.drawLine(const Offset(50, 62), const Offset(50, 77), l(gold, 5));
        c.drawLine(const Offset(37, 78), const Offset(63, 78), l(gold, 5));
        break;
      case 1:
        c.drawPath(
          Path()
            ..moveTo(35, 12)
            ..lineTo(50, 31)
            ..lineTo(65, 12)
            ..lineTo(67, 43)
            ..lineTo(34, 43)
            ..close(),
          f(purple),
        );
        c.drawCircle(const Offset(50, 58), 22, f(gold));
        c.drawCircle(const Offset(50, 58), 15, l(cyan, 2));
        c.drawLine(const Offset(43, 58), const Offset(49, 64), l(Colors.white));
        c.drawLine(const Offset(49, 64), const Offset(60, 49), l(Colors.white));
        break;
      case 2:
        final leaf = Path()
          ..moveTo(29, 73)
          ..quadraticBezierTo(14, 22, 73, 22)
          ..quadraticBezierTo(85, 73, 29, 73);
        c.drawPath(leaf, f(AppColors.greenLight));
        c.drawLine(const Offset(30, 74), const Offset(64, 36), l(cyan));
        break;
      case 3:
        c.drawPath(
          Path()
            ..moveTo(56, 15)
            ..cubicTo(78, 48, 80, 60, 68, 75)
            ..cubicTo(48, 96, 20, 72, 28, 53)
            ..cubicTo(31, 43, 46, 29, 56, 15),
          f(gold),
        );
        c.drawPath(
          Path()
            ..moveTo(52, 45)
            ..quadraticBezierTo(76, 74, 50, 79)
            ..quadraticBezierTo(31, 74, 52, 45),
          f(purple),
        );
        break;
      case 4:
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(24, 23, 53, 55),
            const Radius.circular(9),
          ),
          f(cyan),
        );
        c.drawLine(
          const Offset(25, 39),
          const Offset(76, 39),
          l(AppColors.primaryBlue),
        );
        for (var i = 0; i < 6; i++) {
          c.drawCircle(
            Offset(35 + (i % 3) * 15.0, 50 + (i ~/ 3) * 15.0),
            3,
            f(AppColors.primaryBlue),
          );
        }
        break;
      case 5:
        final heart = Path()
          ..moveTo(50, 77)
          ..cubicTo(1, 47, 28, 16, 50, 35)
          ..cubicTo(75, 15, 97, 48, 50, 77);
        c.drawPath(heart, f(AppColors.pinkLight));
        break;
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_BadgePainter old) => old.index != index;
}

class RamadanVectorScene extends StatelessWidget {
  const RamadanVectorScene({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 270,
    width: double.infinity,
    child: CustomPaint(painter: _RamadanPainter()),
  );
}

class _RamadanPainter extends CustomPainter {
  const _RamadanPainter();
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 390, size.height / 270);
    Paint f(Color color) => Paint()..color = color;
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(const Rect.fromLTWH(265, 20, 76, 76)),
      Path()..addOval(const Rect.fromLTWH(289, 12, 65, 70)),
    );
    c.drawPath(moon, f(AppColors.copper));
    for (var i = 0; i < 20; i++) {
      c.drawCircle(
        Offset(16 + (i * 67 % 355).toDouble(), 18 + (i * 37 % 138).toDouble()),
        i % 3 == 0 ? 2 : 1,
        f(AppColors.cyanLight.withValues(alpha: .6)),
      );
    }
    for (var i = 0; i < 5; i++) {
      final x = 20 + i * 77.0, h = 40 + (i % 3) * 25.0;
      c.drawRect(
        Rect.fromLTWH(x, 270 - h, 52, h),
        f(AppColors.aiPurple.withValues(alpha: .22)),
      );
      c.drawArc(
        Rect.fromLTWH(x, 244 - h, 52, 52),
        math.pi,
        math.pi,
        true,
        f(AppColors.primaryBlue.withValues(alpha: .65)),
      );
      c.drawRect(
        Rect.fromLTWH(x + 36, 205 - h, 8, 65),
        f(AppColors.primaryBlue),
      );
      c.drawPath(
        Path()
          ..moveTo(x + 35, 205 - h)
          ..lineTo(x + 40, 193 - h)
          ..lineTo(x + 45, 205 - h)
          ..close(),
        f(AppColors.copper),
      );
    }
    c.drawLine(
      const Offset(83, 0),
      const Offset(83, 48),
      Paint()
        ..color = AppColors.copper
        ..strokeWidth = 2,
    );
    final lantern = Path()
      ..moveTo(69, 55)
      ..lineTo(97, 55)
      ..lineTo(103, 90)
      ..lineTo(83, 105)
      ..lineTo(63, 90)
      ..close();
    c.drawPath(lantern, f(AppColors.copper));
    c.drawRect(const Rect.fromLTWH(74, 62, 18, 25), f(AppColors.cyanLight));
    c.restore();
  }

  @override
  bool shouldRepaint(_RamadanPainter old) => false;
}
