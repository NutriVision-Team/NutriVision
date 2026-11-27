import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Dish-specific decorative art, not a portion or nutrition measurement.
class EgyptianDishArt extends StatefulWidget {
  const EgyptianDishArt({super.key, required this.dishId, this.size = 96});
  final String dishId;
  final double size;
  static const ids = {
    'themealdb_52963',
    'themealdb_53025',
    'themealdb_53026',
    'themealdb_53027',
    'themealdb_53028',
    'themealdb_53029',
    'themealdb_53030',
    'themealdb_53031',
  };
  @override
  State<EgyptianDishArt> createState() => _EgyptianDishArtState();
}

class _EgyptianDishArtState extends State<EgyptianDishArt> {
  Offset tilt = Offset.zero;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      tilt = Offset.zero;
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: Localizations.localeOf(context).languageCode == 'ar'
        ? 'رسم توضيحي للطبق، ليس صورة الحصة'
        : 'Dish illustration, not a portion photograph',
    child: MouseRegion(
      onHover: (e) => move(e.localPosition),
      onExit: (_) => reset(),
      child: GestureDetector(
        onPanUpdate: (e) => move(e.localPosition),
        onPanEnd: (_) => reset(),
        onPanCancel: reset,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .001)
            ..rotateX(-tilt.dy * .2)
            ..rotateY(tilt.dx * .2),
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: EgyptianDishPainter(widget.dishId),
          ),
        ),
      ),
    ),
  );
  void move(Offset p) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(
      () => tilt = Offset(
        (p.dx / widget.size - .5).clamp(-.5, .5),
        (p.dy / widget.size - .5).clamp(-.5, .5),
      ),
    );
  }

  void reset() {
    if (mounted) setState(() => tilt = Offset.zero);
  }
}

class EgyptianDishPainter extends CustomPainter {
  const EgyptianDishPainter(this.id);
  final String id;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 100, size.height / 100);
    Paint f(Color color) => Paint()..color = color;
    Paint l(Color color, [double w = 2]) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    const cyan = AppColors.cyanLight,
        green = AppColors.greenLight,
        orange = AppColors.copper,
        purple = AppColors.purpleLight;
    const bread = Color(0xFFF1CB83),
        bean = Color(0xFF95583A),
        tomato = Color(0xFFEF7065),
        rice = Color(0xFFFFE8BE);
    void oval(double x, double y, double w, double h, Color color) =>
        c.drawOval(Rect.fromLTWH(x, y, w, h), f(color));
    void plate() {
      oval(6, 28, 88, 61, AppColors.primaryBlue);
      oval(6, 24, 88, 61, cyan);
      oval(10, 27, 80, 53, AppColors.darkSurface);
    }

    void herb(double x, double y) {
      oval(x, y, 5, 3, green);
      oval(x + 3, y - 2, 3, 5, green);
    }

    switch (id) {
      case 'themealdb_52963': // Shakshuka: tomato skillet, eggs, feta, coriander.
        c.drawLine(const Offset(76, 61), const Offset(96, 80), l(purple, 10));
        oval(5, 20, 82, 64, AppColors.primaryBlue);
        oval(9, 24, 74, 52, tomato);
        for (final o in [
          const Offset(31, 41),
          const Offset(57, 53),
          const Offset(30, 62),
        ]) {
          oval(o.dx - 10, o.dy - 8, 23, 17, Colors.white);
          c.drawCircle(o, 5, f(orange));
        }
        for (var i = 0; i < 7; i++) {
          herb(15.0 + i * 9, 30 + (i % 3) * 17.0);
          c.drawRect(
            Rect.fromLTWH(19.0 + i * 8, 36.0 + (i % 2) * 32, 3, 3),
            f(Colors.white),
          );
        }
        break;
      case 'themealdb_53025': // Ful: crushed beans with oil, parsley and lemon.
        plate();
        oval(15, 33, 70, 40, bean);
        for (var i = 0; i < 22; i++) {
          oval(
            20 + (i * 17 % 60).toDouble(),
            38 + (i * 11 % 28).toDouble(),
            7,
            4,
            i.isEven ? bread : orange,
          );
        }
        c.drawArc(
          const Rect.fromLTWH(27, 40, 45, 24),
          .3,
          4.8,
          false,
          l(orange, 3),
        );
        for (var i = 0; i < 5; i++) {
          herb(24.0 + i * 12, 43.0 + (i % 2) * 17);
        }
        c.drawArc(
          const Rect.fromLTWH(68, 22, 20, 20),
          0,
          math.pi,
          true,
          f(bread),
        );
        break;
      case 'themealdb_53026': // Taameya: green-centred fava patties.
        plate();
        for (final o in [
          const Offset(30, 44),
          const Offset(55, 39),
          const Offset(69, 57),
          const Offset(43, 64),
        ]) {
          c.drawCircle(o, 13, f(orange));
          c.drawCircle(o, 10, f(green));
          for (var j = 0; j < 5; j++) {
            c.drawLine(
              o + Offset(j * 3.0 - 6, -3),
              o + Offset(j * 3.0 - 5, -1),
              l(bread, 1.4),
            );
          }
        }
        herb(15, 66);
        break;
      case 'themealdb_53027': // Koshari: rice, lentils, pasta, tomato and fried onion.
        plate();
        oval(14, 32, 72, 43, rice);
        for (var i = 0; i < 26; i++) {
          final x = 20 + (i * 19 % 61).toDouble(),
              y = 37 + (i * 13 % 31).toDouble();
          c.drawLine(
            Offset(x, y),
            Offset(x + 4, y + 1),
            l(i % 3 == 0 ? bean : bread, 3),
          );
        }
        oval(28, 42, 44, 23, tomato);
        for (var i = 0; i < 9; i++) {
          c.drawArc(
            Rect.fromLTWH(
              25 + (i * 7 % 45).toDouble(),
              35 + (i % 3) * 10.0,
              12,
              6,
            ),
            .1,
            2.6,
            false,
            l(bean, 2),
          );
        }
        break;
      case 'themealdb_53028': // Shawarma wrap with chicken and vegetables.
        c.save();
        c.translate(50, 52);
        c.rotate(-.32);
        final wrap = Path()
          ..moveTo(-25, -30)
          ..lineTo(27, -30)
          ..lineTo(17, 39)
          ..lineTo(-12, 39)
          ..close();
        c.drawPath(wrap, f(bread));
        c.drawPath(wrap, l(orange));
        for (var i = 0; i < 5; i++) {
          c.drawLine(
            Offset(-18.0 + i * 8, -26),
            Offset(-12.0 + i * 7, -6),
            l(i.isEven ? bean : green, 6),
          );
        }
        for (var i = 0; i < 3; i++) {
          oval(-12 + i * 12.0, -22, 7, 6, tomato);
        }
        c.drawLine(const Offset(-21, -3), const Offset(20, 9), l(orange));
        c.drawLine(const Offset(-18, 11), const Offset(18, 23), l(orange));
        c.restore();
        break;
      case 'themealdb_53029': // Molokhia soup with minced leaves, garlic and side rice.
        plate();
        oval(12, 31, 66, 43, const Color(0xFF48774C));
        for (var i = 0; i < 34; i++) {
          oval(
            17 + (i * 19 % 54).toDouble(),
            36 + (i * 13 % 31).toDouble(),
            3,
            2,
            i.isEven ? green : AppColors.darkSurface,
          );
        }
        oval(65, 51, 28, 25, rice);
        for (var i = 0; i < 7; i++) {
          c.drawLine(
            Offset(71.0 + i * 2, 58),
            Offset(74.0 + i * 2, 63),
            l(bread, 1),
          );
        }
        break;
      case 'themealdb_53030': // Feteer: concentric laminated pastry, no invented filling.
        plate();
        oval(13, 28, 75, 48, bread);
        for (var i = 0; i < 6; i++) {
          c.drawOval(
            Rect.fromLTWH(
              18.0 + i * 4,
              32.0 + i * 2,
              65.0 - i * 8,
              38.0 - i * 4,
            ),
            l(orange, 1.5),
          );
        }
        for (var i = 0; i < 12; i++) {
          oval(
            24 + (i * 19 % 49).toDouble(),
            37 + (i * 11 % 26).toDouble(),
            5,
            2,
            bean,
          );
        }
        break;
      case 'themealdb_53031': // Fatta: rice, bread cubes, meat and tomato garlic sauce.
        plate();
        oval(14, 32, 72, 41, rice);
        for (var i = 0; i < 14; i++) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                18 + (i * 13 % 61).toDouble(),
                37 + (i * 17 % 29).toDouble(),
                8,
                7,
              ),
              const Radius.circular(2),
            ),
            f(i % 3 == 0 ? bean : bread),
          );
        }
        oval(27, 43, 45, 21, tomato);
        for (final o in [
          const Offset(36, 48),
          const Offset(55, 53),
          const Offset(45, 63),
        ]) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: o, width: 14, height: 11),
              const Radius.circular(3),
            ),
            f(bean),
          );
          c.drawLine(
            o - const Offset(4, 2),
            o + const Offset(3, 1),
            l(orange, 2),
          );
        }
        break;
    }
    c.restore();
  }

  @override
  bool shouldRepaint(EgyptianDishPainter old) => old.id != id;
}
