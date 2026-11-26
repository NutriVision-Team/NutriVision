import 'dart:math' as math;
import 'catalog_photo.dart';
import 'dish_float.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Explicit food identity, not a category symbol or measured portion.
class CatalogFoodArt extends StatefulWidget {
  const CatalogFoodArt({super.key, required this.id, this.size = 52});
  final String id;
  final double size;
  @override
  State<CatalogFoodArt> createState() => _CatalogFoodArtState();
}

class _CatalogFoodArtState extends State<CatalogFoodArt> {
  Offset tilt = Offset.zero;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      tilt = Offset.zero;
    }
  }

  void move(Offset point) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(
      () => tilt = Offset(
        (point.dx / widget.size - .5).clamp(-.5, .5),
        (point.dy / widget.size - .5).clamp(-.5, .5),
      ),
    );
  }

  void reset() => setState(() => tilt = Offset.zero);
  @override
  Widget build(BuildContext context) => MouseRegion(
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
          ..rotateY(tilt.dx * .25),
        child: CatalogPhoto.forFood(widget.id) != null
            ? DishFloat(
                child: ClipOval(
                  child: CatalogPhoto(
                    name: CatalogPhoto.forFood(widget.id)!,
                    size: widget.size,
                  ),
                ),
              )
            : CustomPaint(
                size: Size.square(widget.size),
                painter: CatalogFoodPainter(widget.id),
              ),
      ),
    ),
  );
}

class CatalogFoodPainter extends CustomPainter {
  const CatalogFoodPainter(this.id);
  final String id;
  static const identities = <String, String>{
    '1999634': 'tomato',
    '790646': 'onion-yellow',
    '790577': 'onion-red',
    '1104647': 'garlic',
    '2346401': 'potato',
    '2346404': 'sweet-potato',
    '2258586': 'carrot',
    '2346406': 'cucumber',
    '2685577': 'aubergine',
    '2685568': 'zucchini',
    '2258588': 'pepper-green',
    '2258590': 'pepper-red',
    '1999632': 'spinach',
    '747447': 'broccoli',
    '2685573': 'cauliflower',
    '2346407': 'cabbage',
    '746769': 'lettuce',
    '2346400': 'green-beans',
    '2644291': 'peas',
    '1999629': 'mushroom',
    '323505': 'kale',
    '2685580': 'tomato-paste',
    '1105314': 'banana',
    '1750341': 'apple',
    '746771': 'orange',
    '2346413': 'grapes',
    '2346409': 'strawberry',
    '2710833': 'mango',
    '2747675': 'watermelon',
    '746768': 'fig',
    '2758980': 'raisins',
    '2710824': 'avocado',
    '2710832': 'mandarin',
    '746770': 'melon',
    '748967': 'egg-whole',
    '747997': 'egg-white',
    '748236': 'egg-yolk',
    '746782': 'milk-whole',
    '746778': 'milk-2',
    '746776': 'milk-0',
    '2259793': 'yogurt-whole',
    '2647437': 'yogurt-0',
    '330137': 'greek-0',
    '2259794': 'greek-whole',
    '328637': 'cheddar',
    '2259796': 'feta',
    '328841': 'cottage',
    '789828': 'butter-unsalted',
    '790508': 'butter-salted',
    '2512381': 'rice-white',
    '2512380': 'rice-brown',
    '2710820': 'bulgur',
    '2346396': 'oats',
    '790018': 'flour-white',
    '790085': 'flour-whole',
    '2003589': 'semolina',
    '2758998': 'spaghetti',
    '2759000': 'pasta-whole',
    '2758993': 'bread-white',
    '2758994': 'bread-whole',
    '2644283': 'lentils',
    '2644282': 'chickpeas-dry',
    '2644288': 'chickpeas-canned',
    '2644289': 'kidney-canned',
    '747441': 'white-beans',
    '321358': 'hummus',
    '2515376': 'peanuts',
    '2758989': 'peanut-butter',
    '2646170': 'chicken-breast-raw',
    '331960': 'chicken-breast-cooked',
    '2646171': 'chicken-thigh',
    '2727566': 'chicken-leg',
    '2514747': 'turkey-minced',
    '2514743': 'beef-lean',
    '2514744': 'beef-minced',
    '2727574': 'sirloin',
    '2727573': 'tenderloin',
    '2727570': 'lamb-minced',
    '2684442': 'tilapia',
    '2684441': 'salmon-atlantic',
    '2684440': 'salmon-sockeye',
    '334194': 'tuna-canned',
    '2684445': 'catfish',
    '2684443': 'shrimp',
    '2346393': 'almonds',
    '2346394': 'walnuts',
    '2515375': 'hazelnuts',
    '2515379': 'pistachios',
    '2515374': 'cashews',
    '2515381': 'sunflower',
    '2262073': 'tahini',
    '746784': 'sugar',
    '746775': 'salt',
    '747693': 'ketchup',
    '1999630': 'soy-milk',
  };
  static String? identity(String id) =>
      identities[id.replaceFirst('usda_foundation_', '')];
  @override
  void paint(Canvas c, Size size) {
    final kind = identity(id);
    if (kind == null) {
      final paint = Paint()
        ..color = AppColors.cyanLight
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final center = size.center(Offset.zero);
      final radius = size.width * .3;
      c.drawCircle(center, radius, paint);
      c.drawLine(
        center - Offset(radius * .5, 0),
        center + Offset(radius * .5, 0),
        paint,
      );
      return;
    }
    c.save();
    c.scale(size.width / 100, size.height / 100);
    Paint f(Color color) => Paint()..color = color;
    Paint l(Color color, [double w = 3]) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const green = Color(0xFF64C987),
        darkGreen = Color(0xFF2F8563),
        red = Color(0xFFE87979),
        orange = Color(0xFFEBB16B),
        cream = Color(0xFFFFE4B5),
        purple = Color(0xFFAC8CE9),
        brown = Color(0xFFAC7E60),
        cyan = AppColors.cyanLight;
    void oval(double x, double y, double w, double h, Color color) =>
        c.drawOval(Rect.fromLTWH(x, y, w, h), f(color));
    void leaf(double x, double y) {
      final p = Path()
        ..moveTo(x, y + 12)
        ..quadraticBezierTo(x - 15, y - 9, x + 10, y - 10)
        ..quadraticBezierTo(x + 19, y + 7, x, y + 12);
      c.drawPath(p, f(green));
      c.drawLine(Offset(x, y + 10), Offset(x + 5, y - 5), l(darkGreen, 1.6));
    }

    void label(
      String text, {
      Color color = AppColors.darkSurface,
      double y = 48,
      double font = 16,
    }) {
      final p = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: font,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Cairo',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 88);
      p.paint(c, Offset(50 - p.width / 2, y));
    }

    void bowl(Color fill) {
      oval(8, 45, 84, 39, cyan);
      oval(11, 39, 78, 34, fill);
      c.drawArc(const Rect.fromLTWH(8, 33, 84, 40), 0, math.pi, false, l(cyan));
    }

    void grains(Color color, {bool round = false}) {
      bowl(cream);
      for (var i = 0; i < 23; i++) {
        final x = 17 + (i * 19 % 65).toDouble(),
            y = 47 + (i * 13 % 18).toDouble();
        oval(x, y, round ? 5 : 8, round ? 5 : 3, color);
      }
    }

    if (kind == 'tomato') {
      oval(16, 26, 69, 59, red);
      for (var i = 0; i < 5; i++) {
        c.save();
        c.translate(50, 34);
        c.rotate(i * math.pi * 2 / 5);
        c.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(-5, -18)
            ..lineTo(6, -7)
            ..close(),
          f(green),
        );
        c.restore();
      }
      c.drawArc(const Rect.fromLTWH(25, 38, 44, 33), 2.7, 1.0, false, l(cream));
    } else if (kind.startsWith('onion')) {
      final color = kind.endsWith('red') ? purple : orange;
      final p = Path()
        ..moveTo(50, 12)
        ..cubicTo(44, 35, 12, 37, 17, 64)
        ..cubicTo(20, 95, 81, 92, 84, 65)
        ..cubicTo(88, 40, 57, 32, 50, 12);
      c.drawPath(p, f(color));
      for (var i = 0; i < 3; i++) {
        c.drawArc(
          Rect.fromLTWH(29.0 + i * 8, 29, 39 - i * 12.0, 54),
          1.4,
          3.7,
          false,
          l(cream, 1.5),
        );
      }
      c.drawLine(const Offset(50, 15), const Offset(55, 5), l(green));
    } else if (kind == 'garlic') {
      for (var i = 0; i < 5; i++) {
        oval(17 + i * 12.0, 29 - (i == 2 ? 7 : 0), 20, 54, cream);
      }
      c.drawLine(const Offset(50, 25), const Offset(53, 8), l(brown, 7));
    } else if (kind == 'carrot') {
      final p = Path()
        ..moveTo(31, 32)
        ..quadraticBezierTo(42, 17, 63, 32)
        ..lineTo(34, 91)
        ..close();
      c.drawPath(p, f(orange));
      for (var i = 0; i < 4; i++) {
        c.drawLine(
          Offset(33.0 + i, 43 + i * 8.0),
          Offset(45.0 - i, 45 + i * 8.0),
          l(brown, 2),
        );
      }
      leaf(44, 18);
      leaf(56, 18);
    } else if (kind == 'potato' || kind == 'sweet-potato') {
      oval(14, 27, 74, 53, kind == 'potato' ? brown : orange);
      for (var i = 0; i < 7; i++) {
        oval(
          24 + (i * 19 % 50).toDouble(),
          38 + (i * 13 % 29).toDouble(),
          3,
          2,
          cream,
        );
      }
    } else if (kind == 'cucumber' ||
        kind == 'zucchini' ||
        kind == 'aubergine') {
      c.save();
      c.translate(50, 50);
      c.rotate(.6);
      oval(
        -18,
        -38,
        36,
        79,
        kind == 'aubergine'
            ? purple
            : kind == 'cucumber'
            ? darkGreen
            : green,
      );
      c.drawLine(const Offset(0, -36), const Offset(0, -47), l(green, 7));
      c.drawLine(
        const Offset(-8, -19),
        const Offset(-8, 22),
        l(cream.withValues(alpha: .5), 2),
      );
      c.restore();
      if (kind == 'cucumber') {
        oval(58, 66, 29, 23, cream);
        oval(62, 69, 21, 17, green);
      }
    } else if (kind.startsWith('pepper')) {
      for (var i = 0; i < 3; i++) {
        oval(17 + i * 18.0, 29, 31, 55, kind.endsWith('red') ? red : green);
      }
      c.drawPath(
        Path()
          ..moveTo(50, 32)
          ..quadraticBezierTo(40, 18, 54, 12),
        l(darkGreen, 7),
      );
    } else if (['spinach', 'lettuce', 'kale'].contains(kind)) {
      for (var i = 0; i < 6; i++) {
        c.save();
        c.translate(50, 72);
        c.rotate((i - 2.5) * .35);
        c.scale(kind == 'lettuce' ? 0.8 : 1, kind == 'lettuce' ? 1.4 : 1);
        leaf(0, -28.0 - i % 2 * 8);
        c.restore();
      }
    } else if (kind == 'broccoli' || kind == 'cauliflower') {
      c.drawPath(
        Path()
          ..moveTo(40, 87)
          ..lineTo(44, 47)
          ..lineTo(57, 47)
          ..lineTo(63, 87)
          ..close(),
        f(green),
      );
      for (final o in [
        const Offset(27, 41),
        const Offset(48, 28),
        const Offset(71, 41),
        const Offset(49, 51),
      ]) {
        c.drawCircle(o, 18, f(kind == 'broccoli' ? darkGreen : cream));
        for (var j = 0; j < 4; j++) {
          c.drawCircle(
            o + Offset((j % 2) * 9 - 5, (j ~/ 2) * 9 - 5),
            4,
            f(kind == 'broccoli' ? green : orange.withValues(alpha: .4)),
          );
        }
      }
    } else if (kind == 'cabbage') {
      c.drawCircle(const Offset(50, 54), 34, f(green));
      for (var i = 0; i < 5; i++) {
        c.drawArc(
          Rect.fromLTWH(
            22 + i * 5.0,
            27 + i * 3.0,
            56 - i * 10.0,
            54 - i * 6.0,
          ),
          .3,
          4.8,
          false,
          l(cream, 2),
        );
      }
    } else if (kind == 'green-beans') {
      for (var i = 0; i < 5; i++) {
        c.drawPath(
          Path()
            ..moveTo(18 + i * 12.0, 77)
            ..quadraticBezierTo(30 + i * 12.0, 41, 23 + i * 12.0, 20),
          l(green, 7),
        );
      }
    } else if (kind == 'peas') {
      final p = Path()
        ..moveTo(15, 74)
        ..quadraticBezierTo(30, 13, 84, 26)
        ..quadraticBezierTo(77, 76, 15, 74);
      c.drawPath(p, f(darkGreen));
      for (var i = 0; i < 4; i++) {
        c.drawCircle(Offset(29 + i * 14.0, 61 - i * 9.0), 7, f(green));
      }
    } else if (kind == 'mushroom') {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(41, 45, 19, 41),
          const Radius.circular(6),
        ),
        f(cream),
      );
      c.drawArc(
        const Rect.fromLTWH(12, 12, 77, 74),
        math.pi,
        math.pi,
        true,
        f(brown),
      );
      oval(12, 43, 77, 13, cream);
    } else if (kind == 'banana') {
      c.drawPath(
        Path()
          ..moveTo(21, 23)
          ..cubicTo(18, 73, 65, 87, 83, 33)
          ..cubicTo(81, 96, 15, 100, 13, 51)
          ..lineTo(14, 23)
          ..close(),
        f(cream),
      );
      c.drawLine(const Offset(14, 23), const Offset(17, 15), l(brown, 5));
    } else if (kind == 'apple') {
      oval(16, 28, 41, 56, red);
      oval(43, 28, 41, 56, red);
      c.drawLine(const Offset(50, 31), const Offset(53, 13), l(brown, 5));
      leaf(61, 22);
    } else if (kind == 'orange' || kind == 'mandarin') {
      oval(
        16,
        kind == 'orange' ? 23 : 34,
        68,
        kind == 'orange' ? 65 : 49,
        orange,
      );
      leaf(53, 20);
      for (var i = 0; i < 10; i++) {
        oval(
          26 + (i * 17 % 46).toDouble(),
          42 + (i * 11 % 31).toDouble(),
          2,
          2,
          cream,
        );
      }
    } else if (kind == 'grapes' || kind == 'raisins') {
      for (var row = 0; row < 4; row++) {
        for (var j = 0; j < 4 - row; j++) {
          oval(
            19 + j * 17.0 + row * 8,
            23 + row * 16.0,
            19,
            19,
            kind == 'grapes' ? green : purple,
          );
        }
      }
      c.drawLine(const Offset(48, 24), const Offset(57, 11), l(brown));
    } else if (kind == 'strawberry') {
      final p = Path()
        ..moveTo(16, 38)
        ..cubicTo(21, 12, 80, 17, 84, 39)
        ..quadraticBezierTo(81, 65, 51, 89)
        ..quadraticBezierTo(17, 63, 16, 38);
      c.drawPath(p, f(red));
      for (var i = 0; i < 16; i++) {
        oval(
          26 + (i * 17 % 49).toDouble(),
          37 + (i * 11 % 36).toDouble(),
          2,
          4,
          cream,
        );
      }
      leaf(46, 26);
      leaf(58, 24);
    } else if (kind == 'watermelon') {
      c.drawArc(const Rect.fromLTWH(9, 15, 82, 72), 0, math.pi, true, f(green));
      c.drawArc(const Rect.fromLTWH(15, 21, 70, 59), 0, math.pi, true, f(red));
      for (var i = 0; i < 7; i++) {
        oval(25 + i * 8.0, 52 + (i % 2) * 10.0, 3, 5, AppColors.darkSurface);
      }
    } else if (kind == 'avocado') {
      oval(23, 13, 57, 75, green);
      oval(29, 20, 44, 61, cream);
      c.drawCircle(const Offset(51, 61), 16, f(brown));
    } else if (kind == 'mango') {
      oval(22, 16, 59, 73, orange);
      leaf(54, 16);
      c.drawArc(const Rect.fromLTWH(32, 28, 33, 47), .1, 1.5, false, l(cream));
    } else if (kind == 'fig') {
      oval(18, 25, 36, 55, purple);
      oval(51, 29, 35, 54, purple);
      oval(56, 35, 24, 41, red);
      for (var i = 0; i < 9; i++) {
        oval(
          60 + (i * 7 % 15).toDouble(),
          44 + (i * 11 % 25).toDouble(),
          2,
          2,
          cream,
        );
      }
    } else if (kind == 'melon') {
      oval(17, 20, 69, 65, cream);
      for (var i = 0; i < 5; i++) {
        c.drawArc(
          Rect.fromLTWH(26 + i * 7.0, 24, 48 - i * 12.0, 57),
          1.5,
          3,
          false,
          l(green, 2),
        );
      }
    } else if (kind.startsWith('egg')) {
      oval(21, 15, 58, 72, cream);
      if (kind != 'egg-whole') {
        oval(25, 20, 50, 64, Colors.white);
        if (kind == 'egg-yolk') {
          c.drawCircle(const Offset(50, 57), 17, f(orange));
        }
      } else {
        c.drawArc(
          const Rect.fromLTWH(28, 26, 38, 49),
          2.9,
          1.3,
          false,
          l(Colors.white),
        );
      }
    } else if (kind.contains('milk')) {
      final p = Path()
        ..moveTo(25, 29)
        ..lineTo(36, 12)
        ..lineTo(66, 12)
        ..lineTo(77, 29)
        ..lineTo(77, 88)
        ..lineTo(25, 88)
        ..close();
      c.drawPath(p, f(cream));
      c.drawRect(const Rect.fromLTWH(25, 39, 52, 30), f(cyan));
      label(
        kind == 'milk-2'
            ? '2%'
            : kind == 'milk-0'
            ? 'خالي'
            : kind == 'soy-milk'
            ? 'SOY'
            : 'كامل',
        y: 43,
        font: 14,
      );
    } else if (kind.startsWith('yogurt') ||
        kind.startsWith('greek') ||
        kind == 'cottage') {
      c.drawPath(
        Path()
          ..moveTo(17, 33)
          ..lineTo(83, 33)
          ..lineTo(73, 85)
          ..lineTo(27, 85)
          ..close(),
        f(cream),
      );
      oval(14, 22, 73, 22, kind.startsWith('greek') ? purple : cyan);
      label(
        kind == 'cottage'
            ? '•••'
            : kind.endsWith('0')
            ? 'خالي'
            : kind.startsWith('greek')
            ? 'G'
            : 'عادي',
        y: 49,
      );
    } else if (kind == 'cheddar' || kind == 'feta') {
      final p = Path()
        ..moveTo(16, 41)
        ..lineTo(61, 20)
        ..lineTo(86, 43)
        ..lineTo(81, 79)
        ..lineTo(17, 79)
        ..close();
      c.drawPath(p, f(kind == 'cheddar' ? orange : cream));
      c.drawLine(const Offset(17, 42), const Offset(81, 43), l(brown, 2));
      for (var i = 0; i < 4; i++) {
        c.drawCircle(
          Offset(28 + i * 15.0, 57 + (i % 2) * 10.0),
          3,
          f(kind == 'cheddar' ? cream : purple),
        );
      }
    } else if (kind.startsWith('butter')) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(15, 31, 70, 45),
          const Radius.circular(5),
        ),
        f(cream),
      );
      c.drawRect(const Rect.fromLTWH(17, 63, 66, 15), f(purple));
      if (kind.endsWith('salted') && !kind.endsWith('unsalted')) {
        label('+', y: 35);
      }
    } else if (kind.startsWith('rice') ||
        kind == 'bulgur' ||
        kind == 'oats' ||
        kind == 'lentils' ||
        kind == 'white-beans' ||
        kind.startsWith('chickpeas') ||
        kind.startsWith('kidney')) {
      grains(
        kind == 'rice-white'
            ? Colors.white
            : kind == 'lentils'
            ? orange
            : kind.startsWith('kidney')
            ? red
            : kind == 'white-beans'
            ? Colors.white
            : kind == 'rice-brown'
            ? brown
            : cream,
        round: kind == 'lentils' || kind.startsWith('chickpeas'),
      );
      if (kind.contains('canned')) {
        c.drawLine(const Offset(19, 78), const Offset(81, 78), l(purple, 5));
      }
    } else if (kind.startsWith('flour') ||
        kind == 'semolina' ||
        kind == 'sugar' ||
        kind == 'salt') {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(23, 17, 55, 72),
          const Radius.circular(7),
        ),
        f(cream),
      );
      c.drawRect(
        const Rect.fromLTWH(23, 42, 55, 25),
        f(kind == 'flour-whole' ? brown : cyan),
      );
      label(
        kind == 'salt'
            ? 'NaCl'
            : kind == 'sugar'
            ? 'S'
            : kind == 'semolina'
            ? '••'
            : 'W',
        y: 43,
        font: 16,
      );
    } else if (kind == 'spaghetti' || kind == 'pasta-whole') {
      bowl(cream);
      for (var i = 0; i < 12; i++) {
        if (kind == 'spaghetti') {
          c.drawPath(
            Path()
              ..moveTo(22 + i * 4.0, 58)
              ..cubicTo(18 + i * 4.0, 38, 49 + i * 2.0, 43, 71 - i * 2.0, 61),
            l(orange, 2),
          );
        } else {
          c.drawArc(
            Rect.fromLTWH(
              20 + (i * 13 % 53).toDouble(),
              44 + (i * 7 % 19).toDouble(),
              10,
              8,
            ),
            0,
            math.pi * 1.5,
            false,
            l(brown, 3),
          );
        }
      }
    } else if (kind.startsWith('bread')) {
      final p = Path()
        ..moveTo(18, 39)
        ..cubicTo(7, 8, 91, 7, 82, 39)
        ..lineTo(78, 87)
        ..lineTo(22, 87)
        ..close();
      c.drawPath(p, f(brown));
      final inner = Path()
        ..moveTo(25, 40)
        ..cubicTo(16, 19, 84, 19, 75, 40)
        ..lineTo(71, 79)
        ..lineTo(29, 79)
        ..close();
      c.drawPath(inner, f(kind.endsWith('whole') ? orange : cream));
    } else if (kind == 'hummus' ||
        kind == 'peanut-butter' ||
        kind == 'tahini' ||
        kind == 'tomato-paste' ||
        kind == 'ketchup') {
      bowl(kind == 'tomato-paste' || kind == 'ketchup' ? red : cream);
      c.drawArc(
        const Rect.fromLTWH(27, 45, 47, 19),
        .1,
        5.5,
        false,
        l(
          kind == 'hummus'
              ? orange
              : kind == 'tahini'
              ? brown
              : purple,
          2,
        ),
      );
      if (kind == 'hummus') {
        leaf(47, 49);
      } else {
        label(
          kind == 'tahini'
              ? 'طحينة'
              : kind == 'ketchup'
              ? 'K'
              : kind == 'peanut-butter'
              ? 'P'
              : 'T',
          y: 17,
          font: 14,
        );
      }
    } else if (kind.startsWith('chicken')) {
      if (kind == 'chicken-leg') {
        oval(16, 29, 48, 45, orange);
        c.drawLine(const Offset(54, 60), const Offset(80, 80), l(cream, 11));
        c.drawCircle(const Offset(84, 83), 7, f(cream));
      } else {
        oval(
          15,
          22,
          71,
          57,
          kind.endsWith('cooked')
              ? orange
              : kind == 'chicken-thigh'
              ? red
              : const Color(0xFFF3BDB1),
        );
        for (var i = 0; i < 3; i++) {
          c.drawLine(
            Offset(35 + i * 13.0, 36),
            Offset(25 + i * 13.0, 65),
            l(kind.endsWith('cooked') ? brown : cream, 3),
          );
        }
      }
    } else if (kind.contains('minced') || kind == 'beef-lean') {
      bowl(kind.startsWith('turkey') ? cream : red);
      for (var i = 0; i < 16; i++) {
        c.drawPath(
          Path()
            ..moveTo(
              18 + (i * 13 % 60).toDouble(),
              45 + (i * 7 % 20).toDouble(),
            )
            ..relativeQuadraticBezierTo(7, -5, 10, 3),
          l(
            kind == 'lamb-minced'
                ? brown
                : kind == 'beef-lean'
                ? purple
                : orange,
            2,
          ),
        );
      }
    } else if (kind == 'sirloin' || kind == 'tenderloin') {
      oval(
        13,
        kind == 'sirloin' ? 28 : 22,
        kind == 'sirloin' ? 74 : 59,
        kind == 'sirloin' ? 51 : 66,
        red,
      );
      c.drawOval(
        Rect.fromLTWH(
          18,
          32,
          kind == 'sirloin' ? 63 : 48,
          kind == 'sirloin' ? 40 : 51,
        ),
        l(cream, 4),
      );
      c.drawPath(
        Path()
          ..moveTo(31, 44)
          ..lineTo(49, 50)
          ..lineTo(43, 67)
          ..moveTo(49, 50)
          ..lineTo(65, 42),
        l(cream, 2),
      );
    } else if (kind == 'shrimp') {
      c.drawArc(
        const Rect.fromLTWH(22, 18, 58, 66),
        .4,
        math.pi * 1.6,
        false,
        l(orange, 17),
      );
      for (var i = 0; i < 5; i++) {
        c.save();
        c.translate(51, 50);
        c.rotate(i * .6);
        c.drawLine(const Offset(-21, -5), const Offset(-32, -5), l(cream, 2));
        c.restore();
      }
      c.drawCircle(const Offset(70, 29), 3, f(AppColors.darkSurface));
    } else if (kind.contains('salmon')) {
      oval(14, 28, 72, 48, kind.endsWith('sockeye') ? red : orange);
      for (var i = 0; i < 5; i++) {
        c.drawPath(
          Path()
            ..moveTo(27 + i * 10.0, 34)
            ..lineTo(22 + i * 10.0, 49)
            ..lineTo(32 + i * 10.0, 69),
          l(cream, 2),
        );
      }
    } else if (kind == 'tilapia' ||
        kind == 'catfish' ||
        kind == 'tuna-canned') {
      if (kind == 'tuna-canned') {
        oval(10, 35, 80, 44, cyan);
        oval(15, 31, 70, 31, red);
        for (var i = 0; i < 6; i++) {
          c.drawLine(
            Offset(24 + i * 9.0, 39),
            Offset(21 + i * 9.0, 53),
            l(cream, 2),
          );
        }
      } else {
        oval(14, 27, 57, 43, kind == 'catfish' ? purple : cyan);
        c.drawPath(
          Path()
            ..moveTo(64, 47)
            ..lineTo(89, 27)
            ..lineTo(89, 67)
            ..close(),
          f(kind == 'catfish' ? purple : cyan),
        );
        c.drawCircle(const Offset(26, 43), 3, f(AppColors.darkSurface));
        if (kind == 'catfish') {
          c.drawLine(const Offset(17, 52), const Offset(6, 63), l(cream, 2));
          c.drawLine(const Offset(19, 52), const Offset(4, 44), l(cream, 2));
        } else {
          for (var i = 0; i < 3; i++) {
            c.drawArc(
              Rect.fromLTWH(34 + i * 7.0, 32, 9, 30),
              -1.5,
              3,
              false,
              l(cream, 1),
            );
          }
        }
      }
    } else {
      // Explicit nut species, not hash-based color variants.
      for (var i = 0; i < 5; i++) {
        c.save();
        c.translate(27 + (i % 3) * 23.0, 33 + (i ~/ 3) * 30.0);
        c.rotate((i - 2) * .3);
        if (kind == 'cashews') {
          c.drawArc(
            const Rect.fromLTWH(-9, -10, 20, 23),
            .3,
            4.9,
            false,
            l(cream, 8),
          );
        } else if (kind == 'walnuts') {
          for (var j = 0; j < 4; j++) {
            c.drawCircle(
              Offset((j % 2) * 8.0 - 4, (j ~/ 2) * 9.0 - 4),
              6,
              f(brown),
            );
          }
          c.drawLine(const Offset(0, -10), const Offset(0, 10), l(cream, 1));
        } else if (kind == 'pistachios') {
          oval(-9, -13, 19, 27, cream);
          oval(-4, -9, 9, 19, green);
        } else if (kind == 'sunflower') {
          oval(-5, -14, 10, 28, AppColors.primaryBlue);
          c.drawLine(const Offset(0, -10), const Offset(0, 10), l(cream, 2));
        } else {
          oval(
            -9,
            -13,
            kind == 'peanuts' ? 17 : 19,
            kind == 'hazelnuts' ? 20 : 28,
            kind == 'hazelnuts' ? brown : orange,
          );
          c.drawLine(const Offset(0, -9), const Offset(0, 9), l(cream, 1.3));
        }
        c.restore();
      }
    }
    const stateMarks = <String, String>{
      'rice-white': 'أبيض',
      'rice-brown': 'بني',
      'bulgur': 'برغل',
      'oats': 'شوفان',
      'chickpeas-dry': 'جاف',
      'chickpeas-canned': 'معلب',
      'white-beans': 'أبيض',
      'lentils': 'عدس',
      'kidney-canned': 'حمراء',
      'milk-whole': 'كامل',
      'milk-2': '2%',
      'milk-0': 'خالي',
      'yogurt-whole': 'عادي',
      'yogurt-0': 'خالي',
      'greek-whole': 'يوناني',
      'greek-0': 'يوناني خالي',
      'flour-white': 'أبيض',
      'flour-whole': 'كامل',
      'semolina': 'سميد',
      'sugar': 'سكر',
      'salt': 'ملح',
      'beef-lean': 'قليل الدهن',
      'beef-minced': 'بقري',
      'lamb-minced': 'ضاني',
      'turkey-minced': 'رومي',
      'salmon-atlantic': 'أطلسي',
      'salmon-sockeye': 'بري',
    };
    final mark = stateMarks[kind];
    if (mark != null) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(7, 76, 86, 21),
          const Radius.circular(7),
        ),
        f(AppColors.darkSurface),
      );
      label(mark, color: Colors.white, y: 76, font: 12);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(CatalogFoodPainter old) => old.id != id;
}
