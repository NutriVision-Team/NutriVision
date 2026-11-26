import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Vector category illustrations, never an assertion about a specific meal.
class CategoryFoodPainter extends CustomPainter {
  const CategoryFoodPainter(this.category, this.phase);
  final String category;
  final double phase;
  static const categories = {
    'vegetables',
    'fruits',
    'grains',
    'legumes',
    'dairy',
    'eggs',
    'fish',
    'poultry',
    'meat',
    'nuts_seeds',
    'cooking_ingredients',
    'beverages',
  };
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final c = canvas;
    Paint f(Color color) => Paint()..color = color;
    Paint l(Color color, [double width = 4]) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cyan = AppColors.cyanLight,
        orange = AppColors.copper,
        green = AppColors.greenLight,
        purple = AppColors.purpleLight;
    final bob = math.sin(phase * math.pi * 2) * 2;
    c.translate(0, bob);
    switch (category) {
      case 'camera':
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(12, 29, 76, 55),
            const Radius.circular(12),
          ),
          f(AppColors.primaryBlue),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(12, 29, 76, 55),
            const Radius.circular(12),
          ),
          l(cyan),
        );
        c.drawCircle(const Offset(50, 56), 18, f(purple));
        c.drawCircle(const Offset(50, 56), 12, l(cyan));
        c.drawPath(
          Path()
            ..moveTo(29, 29)
            ..lineTo(36, 17)
            ..lineTo(63, 17)
            ..lineTo(70, 29),
          l(cyan),
        );
      case 'barcode':
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(12, 16, 76, 70),
            const Radius.circular(10),
          ),
          l(orange),
        );
        for (var i = 0; i < 8; i++) {
          c.drawLine(
            Offset(22.0 + i * 8, 32),
            Offset(22.0 + i * 8, 68),
            l(cyan, i % 3 == 0 ? 5 : 2),
          );
        }
        c.drawLine(const Offset(8, 50), const Offset(92, 50), l(purple, 4));
      case 'search':
        c.drawCircle(const Offset(43, 41), 27, f(AppColors.primaryBlue));
        c.drawCircle(const Offset(43, 41), 27, l(cyan, 6));
        c.drawLine(const Offset(64, 62), const Offset(85, 84), l(orange, 10));
        c.drawArc(
          const Rect.fromLTWH(26, 24, 34, 34),
          math.pi,
          math.pi / 2,
          false,
          l(Colors.white, 3),
        );
      case 'voice':
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(37, 12, 26, 48),
            const Radius.circular(13),
          ),
          f(purple),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(37, 12, 26, 48),
            const Radius.circular(13),
          ),
          l(cyan),
        );
        c.drawArc(
          const Rect.fromLTWH(25, 25, 50, 48),
          0,
          math.pi,
          false,
          l(cyan, 5),
        );
        c.drawLine(const Offset(50, 73), const Offset(50, 88), l(orange, 5));
        c.drawLine(const Offset(35, 88), const Offset(65, 88), l(orange, 5));
      case 'favorite':
        final heart = Path()
          ..moveTo(50, 85)
          ..cubicTo(8, 60, 5, 34, 22, 23)
          ..cubicTo(34, 13, 46, 21, 50, 29)
          ..cubicTo(62, 9, 88, 17, 89, 38)
          ..cubicTo(91, 57, 66, 77, 50, 85)
          ..close();
        c.drawPath(heart, f(AppColors.pinkLight));
        c.drawPath(heart, l(purple));

      case 'eggs':
        final p = Path()
          ..moveTo(50, 12)
          ..cubicTo(65, 12, 80, 48, 79, 65)
          ..cubicTo(77, 93, 23, 93, 21, 65)
          ..cubicTo(20, 48, 35, 12, 50, 12)
          ..close();
        c.drawPath(p, f(const Color(0xFFF6E8CD)));
        c.drawPath(p, l(orange));
        c.drawOval(const Rect.fromLTWH(32, 49, 36, 30), f(orange));
      case 'fish':
        final p = Path()
          ..moveTo(15, 50)
          ..quadraticBezierTo(42, 12, 73, 46)
          ..lineTo(91, 30)
          ..lineTo(91, 72)
          ..lineTo(73, 56)
          ..quadraticBezierTo(40, 87, 15, 50)
          ..close();
        c.drawPath(p, f(AppColors.primaryBlue));
        c.drawPath(p, l(cyan));
        c.drawCircle(const Offset(31, 45), 4, f(Colors.white));
        c.drawPath(
          Path()
            ..moveTo(53, 34)
            ..lineTo(46, 65),
          l(cyan),
        );
      case 'grains':
        c.drawPath(
          Path()
            ..moveTo(35, 88)
            ..lineTo(65, 12),
          l(orange),
        );
        for (var i = 0; i < 4; i++) {
          final y = 27.0 + i * 15;
          c.drawOval(
            Rect.fromCenter(
              center: Offset(48 - i * 3, y),
              width: 22,
              height: 12,
            ),
            f(orange),
          );
          c.drawOval(
            Rect.fromCenter(
              center: Offset(68 - i * 5, y + 8),
              width: 20,
              height: 12,
            ),
            f(AppColors.gold),
          );
        }
      case 'legumes':
        for (var i = 0; i < 3; i++) {
          c.save();
          c.translate(30.0 + i * 20, 35.0 + (i % 2) * 22);
          c.rotate(i * .5);
          c.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-15, -18, 30, 40),
              const Radius.circular(17),
            ),
            f(orange),
          );
          c.drawPath(
            Path()
              ..moveTo(1, -10)
              ..quadraticBezierTo(-9, 0, 1, 10),
            l(purple, 3),
          );
          c.restore();
        }
      case 'dairy':
        final p = Path()
          ..moveTo(29, 26)
          ..lineTo(43, 11)
          ..lineTo(67, 11)
          ..lineTo(79, 27)
          ..lineTo(79, 87)
          ..lineTo(29, 87)
          ..close();
        c.drawPath(p, f(const Color(0xFFF5F7FA)));
        c.drawPath(p, l(cyan));
        c.drawRect(
          const Rect.fromLTWH(30, 40, 48, 30),
          f(AppColors.primaryBlue),
        );
        c.drawPath(
          Path()
            ..moveTo(53, 45)
            ..quadraticBezierTo(30, 67, 53, 67)
            ..quadraticBezierTo(75, 67, 53, 45),
          f(cyan),
        );
      case 'beverages':
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(18, 32, 53, 48),
            const Radius.circular(12),
          ),
          f(AppColors.primaryBlue),
        );
        c.drawArc(
          const Rect.fromLTWH(56, 38, 32, 29),
          -math.pi / 2,
          math.pi,
          false,
          l(cyan, 6),
        );
        c.drawPath(
          Path()
            ..moveTo(28, 20)
            ..quadraticBezierTo(23, 12, 30, 7)
            ..moveTo(48, 20)
            ..quadraticBezierTo(42, 12, 50, 5),
          l(cyan),
        );
      case 'cooking_ingredients':
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(34, 9, 31, 14),
            const Radius.circular(3),
          ),
          f(purple),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(27, 23, 46, 65),
            const Radius.circular(13),
          ),
          l(cyan),
        );
        c.drawRect(const Rect.fromLTWH(30, 50, 40, 31), f(orange));
        c.drawOval(const Rect.fromLTWH(40, 58, 19, 12), f(green));
      case 'poultry':
        c.drawPath(
          Path()
            ..moveTo(60, 59)
            ..lineTo(78, 79)
            ..moveTo(73, 84)
            ..lineTo(83, 74),
          l(const Color(0xFFF6E8CD), 10),
        );
        c.drawOval(const Rect.fromLTWH(16, 17, 56, 50), f(orange));
        c.drawOval(
          const Rect.fromLTWH(24, 23, 35, 30),
          l(AppColors.orangeLight),
        );
      case 'meat':
        final p = Path()
          ..moveTo(20, 35)
          ..cubicTo(26, 9, 78, 15, 84, 44)
          ..cubicTo(91, 80, 43, 94, 21, 75)
          ..quadraticBezierTo(6, 60, 20, 35)
          ..close();
        c.drawPath(p, f(AppColors.pinkLight));
        c.drawPath(p, l(AppColors.orangeLight));
        c.drawOval(
          const Rect.fromLTWH(51, 36, 20, 19),
          f(const Color(0xFFF6E8CD)),
        );
        c.drawPath(
          Path()
            ..moveTo(26, 47)
            ..quadraticBezierTo(34, 61, 40, 68),
          l(const Color(0xFFF6E8CD), 3),
        );
      case 'nuts_seeds':
        for (final x in [30.0, 52.0, 73.0]) {
          final p = Path()
            ..moveTo(x, 22)
            ..quadraticBezierTo(x - 30, 61, x, 82)
            ..quadraticBezierTo(x + 25, 61, x, 22);
          c.drawPath(p, f(orange));
          c.drawPath(
            Path()
              ..moveTo(x, 32)
              ..lineTo(x, 72),
            l(AppColors.gold, 2),
          );
        }
      case 'fruits':
        c.drawOval(const Rect.fromLTWH(17, 30, 67, 57), f(AppColors.pinkLight));
        c.drawPath(
          Path()
            ..moveTo(49, 38)
            ..quadraticBezierTo(40, 17, 60, 9),
          l(orange),
        );
        c.drawOval(const Rect.fromLTWH(54, 12, 29, 15), f(green));
        c.drawArc(
          const Rect.fromLTWH(28, 40, 18, 28),
          math.pi,
          math.pi / 2,
          false,
          l(Colors.white.withValues(alpha: .7)),
        );
      default:
        final p = Path()
          ..moveTo(24, 82)
          ..quadraticBezierTo(7, 30, 79, 15)
          ..quadraticBezierTo(97, 77, 24, 82)
          ..close();
        c.drawPath(p, f(green));
        c.drawPath(p, l(cyan));
        c.drawPath(
          Path()
            ..moveTo(19, 88)
            ..lineTo(67, 29)
            ..moveTo(39, 63)
            ..lineTo(37, 41)
            ..moveTo(48, 52)
            ..lineTo(70, 53),
          l(AppColors.primaryBlue, 3),
        );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(CategoryFoodPainter old) =>
      old.category != category || old.phase != phase;
}
