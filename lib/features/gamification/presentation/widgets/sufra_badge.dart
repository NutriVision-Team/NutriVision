import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Original vector emblems. Each achievement has its own illustration,
/// silhouette and palette, with a consistent Sufra jewel rim and ribbon.
class SufraBadge extends StatelessWidget {
  const SufraBadge({
    super.key,
    required this.id,
    required this.unlocked,
    this.size = 72,
  });
  final String id;
  final bool unlocked;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: unlocked ? 'Achievement emblem' : 'Locked achievement emblem',
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _BadgePainter(id, unlocked)),
    ),
  );
}

class _BadgePainter extends CustomPainter {
  _BadgePainter(this.id, this.unlocked);
  final String id;
  final bool unlocked;
  static const palettes = {
    'journey': [Color(0xff26c99c), Color(0xff087e76)],
    'first_meal': [Color(0xffffb15d), Color(0xffd06528)],
    'aware': [Color(0xff9eda72), Color(0xff319668)],
    'planner': [Color(0xff53c7f3), Color(0xff4666ca)],
    'planner3': [Color(0xffb4a0ff), Color(0xff7957d5)],
    'active7': [Color(0xffffc06d), Color(0xffee6843)],
    'active30': [Color(0xffffd47b), Color(0xffc78a33)],
    'learner': [Color(0xff76c7ef), Color(0xff4d70cb)],
    'cook': [Color(0xfff797be), Color(0xffbd4b8d)],
    'returning': [Color(0xff7bddd5), Color(0xff268eac)],
  };
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final colors = unlocked
        ? (palettes[id] ?? palettes['journey']!)
        : [const Color(0xffa0b0c4), const Color(0xff65758f)];
    final gold = unlocked ? const Color(0xffffdda4) : const Color(0xffb2bfd0);
    final paper = unlocked ? const Color(0xfffff2d5) : const Color(0xffe0e6ed);
    Paint fill(Color c) => Paint()..color = c;
    void line(Offset a, Offset b, Color c, [double width = 3]) =>
        canvas.drawLine(
          a,
          b,
          Paint()
            ..color = c
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round,
        );
    void dot(double x, double y, double r, Color c) =>
        canvas.drawCircle(Offset(x, y), r, fill(c));
    void path(List<Offset> pts, Color c) {
      final p = Path()..addPolygon(pts, true);
      canvas.drawPath(p, fill(c));
    }

    void star(double x, double y, double r, Color c) {
      final p = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5, rr = i.isEven ? r : r * .43;
        final dx = x + math.cos(a) * rr, dy = y + math.sin(a) * rr;
        i == 0 ? p.moveTo(dx, dy) : p.lineTo(dx, dy);
      }
      p.close();
      canvas.drawPath(p, fill(c));
    }

    canvas.drawCircle(
      const Offset(50, 48),
      41,
      Paint()
        ..color = colors[1].withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    // Split ribbon tails under each jewel.
    path(const [
      Offset(28, 65),
      Offset(46, 72),
      Offset(35, 96),
      Offset(29, 86),
      Offset(17, 89),
    ], colors[1]);
    path(const [
      Offset(54, 72),
      Offset(72, 65),
      Offset(83, 89),
      Offset(71, 86),
      Offset(65, 96),
    ], colors[0]);
    final shield = ['planner', 'planner3', 'learner'].contains(id);
    final hex = ['aware', 'active30', 'cook'].contains(id);
    Path shape(double inset) {
      if (shield) {
        return Path()
          ..moveTo(50, 5 + inset)
          ..quadraticBezierTo(77 - inset, 10 + inset, 86 - inset, 20 + inset)
          ..lineTo(82 - inset, 56)
          ..quadraticBezierTo(75, 76 - inset, 50, 85 - inset)
          ..quadraticBezierTo(25, 76 - inset, 18 + inset, 56)
          ..lineTo(14 + inset, 20 + inset)
          ..quadraticBezierTo(23 + inset, 10 + inset, 50, 5 + inset)
          ..close();
      }
      if (hex) {
        final p = Path();
        for (var i = 0; i < 6; i++) {
          final a = -math.pi / 2 + i * math.pi / 3,
              x = 50 + math.cos(a) * (43 - inset),
              y = 46 + math.sin(a) * (41 - inset);
          i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
        }
        return p..close();
      }
      return Path()..addOval(
        Rect.fromCircle(center: const Offset(50, 46), radius: 40 - inset),
      );
    }

    canvas.drawPath(shape(0), fill(gold));
    canvas.drawPath(
      shape(3),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(const Rect.fromLTWH(10, 8, 80, 80)),
    );
    canvas.drawPath(
      shape(7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = paper.withValues(alpha: .55),
    );
    // Independent illustrated scenes, no font glyphs or repeated icon assets.
    switch (id) {
      case 'journey':
        canvas.drawOval(const Rect.fromLTWH(29, 64, 42, 7), fill(colors[1]));
        line(const Offset(50, 64), const Offset(50, 34), paper, 4);
        final leaf = Path()
          ..moveTo(49, 46)
          ..quadraticBezierTo(23, 46, 29, 26)
          ..quadraticBezierTo(51, 26, 49, 46);
        canvas.drawPath(leaf, fill(paper));
        final right = Path()
          ..moveTo(51, 53)
          ..quadraticBezierTo(74, 48, 71, 34)
          ..quadraticBezierTo(53, 33, 51, 53);
        canvas.drawPath(right, fill(gold));
        star(67, 24, 5, paper);
      case 'first_meal':
        dot(50, 47, 22, paper);
        dot(50, 47, 16, colors[1]);
        dot(50, 47, 12, gold);
        line(const Offset(22, 29), const Offset(22, 64), paper, 3);
        for (final x in [18.0, 22.0, 26.0]) {
          line(Offset(x, 27), Offset(x, 38), paper, 2);
        }
        line(const Offset(78, 28), const Offset(78, 64), paper, 3);
        line(const Offset(74, 28), const Offset(74, 43), paper, 4);
        final l = Path()
          ..moveTo(44, 51)
          ..quadraticBezierTo(42, 37, 57, 37)
          ..quadraticBezierTo(60, 51, 44, 51);
        canvas.drawPath(l, fill(colors[0]));
      case 'aware':
        final bowl = Path()
          ..moveTo(25, 46)
          ..lineTo(75, 46)
          ..quadraticBezierTo(70, 67, 50, 69)
          ..quadraticBezierTo(30, 67, 25, 46);
        canvas.drawPath(bowl, fill(paper));
        for (final o in [
          const Offset(34, 40),
          const Offset(49, 36),
          const Offset(63, 41),
        ]) {
          dot(o.dx, o.dy, 9, colors[1]);
          line(Offset(o.dx - 3, o.dy + 3), Offset(o.dx + 3, o.dy - 3), gold, 2);
        }
        dot(47, 45, 6, gold);
        dot(63, 47, 5, const Color(0xffec8871));
        star(50, 19, 6, paper);
      case 'planner':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(27, 26, 47, 41),
            const Radius.circular(6),
          ),
          fill(paper),
        );
        canvas.drawRect(const Rect.fromLTWH(27, 32, 47, 9), fill(colors[1]));
        line(const Offset(38, 22), const Offset(38, 33), gold, 4);
        line(const Offset(63, 22), const Offset(63, 33), gold, 4);
        for (final x in [36.0, 48.0, 60.0]) {
          dot(x, 49, 2, colors[1]);
        }
        line(const Offset(44, 58), const Offset(49, 62), colors[1]);
        line(const Offset(49, 62), const Offset(60, 51), colors[1]);
      case 'planner3':
        for (var i = 0; i < 3; i++) {
          final x = 27.0 + i * 15;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, 46 - i * 10, 12, 24 + i * 10),
              const Radius.circular(3),
            ),
            fill(i == 2 ? gold : paper),
          );
        }
        line(const Offset(28, 36), const Offset(44, 26), paper);
        line(const Offset(44, 26), const Offset(64, 22), paper);
        path(const [Offset(58, 19), Offset(69, 20), Offset(65, 30)], gold);
      case 'active7':
        final flame = Path()
          ..moveTo(50, 18)
          ..cubicTo(55, 35, 76, 41, 68, 59)
          ..cubicTo(61, 77, 28, 70, 30, 50)
          ..quadraticBezierTo(31, 37, 41, 31)
          ..quadraticBezierTo(37, 47, 46, 44)
          ..quadraticBezierTo(55, 38, 50, 18);
        canvas.drawPath(flame, fill(paper));
        final core = Path()
          ..moveTo(49, 44)
          ..quadraticBezierTo(70, 65, 49, 67)
          ..quadraticBezierTo(36, 63, 49, 44);
        canvas.drawPath(core, fill(gold));
        for (var i = 0; i < 7; i++) {
          dot(29 + i * 7, 78, 1.8, paper);
        }
      case 'active30':
        final moon = Path()..addOval(const Rect.fromLTWH(30, 29, 40, 40));
        final cut = Path()..addOval(const Rect.fromLTWH(45, 23, 37, 39));
        canvas.drawPath(
          Path.combine(PathOperation.difference, moon, cut),
          fill(paper),
        );
        star(62, 35, 8, gold);
        star(38, 24, 3, paper);
        star(73, 55, 3, paper);
        path(const [
          Offset(32, 17),
          Offset(39, 23),
          Offset(50, 13),
          Offset(61, 23),
          Offset(68, 17),
          Offset(65, 29),
          Offset(35, 29),
        ], gold);
      case 'learner':
        final book = Path()
          ..moveTo(50, 34)
          ..quadraticBezierTo(38, 23, 24, 28)
          ..lineTo(24, 64)
          ..quadraticBezierTo(40, 60, 50, 70)
          ..quadraticBezierTo(60, 60, 76, 64)
          ..lineTo(76, 28)
          ..quadraticBezierTo(62, 23, 50, 34);
        canvas.drawPath(book, fill(paper));
        line(const Offset(50, 35), const Offset(50, 66), colors[1], 2);
        for (final y in [39.0, 47.0, 55.0]) {
          line(Offset(31, y), Offset(43, y + 2), colors[1], 2);
          line(Offset(57, y + 2), Offset(69, y), colors[1], 2);
        }
        star(50, 18, 6, gold);
      case 'cook':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(34, 39, 33, 29),
            const Radius.circular(3),
          ),
          fill(paper),
        );
        dot(34, 38, 11, paper);
        dot(50, 30, 14, paper);
        dot(67, 38, 11, paper);
        line(const Offset(36, 58), const Offset(65, 58), colors[1], 3);
        line(const Offset(43, 42), const Offset(43, 51), colors[1], 2);
        line(const Offset(57, 42), const Offset(57, 51), colors[1], 2);
        star(76, 62, 5, gold);
      default:
        for (var i = 0; i < 3; i++) {
          final x = 34.0 + i * 15, y = 64.0 - i * 15;
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(i.isEven ? -.3 : .3);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-5, -7, 10, 17),
              const Radius.circular(4),
            ),
            fill(i == 2 ? gold : paper),
          );
          canvas.restore();
        }
        star(72, 22, 7, gold);
        line(const Offset(26, 74), const Offset(39, 74), paper, 2);
    }
    // Jewel glint and clear overlaid padlock, not merely lower opacity.
    line(
      const Offset(25, 18),
      const Offset(35, 13),
      paper.withValues(alpha: .65),
      2,
    );
    if (!unlocked) {
      dot(77, 76, 13, const Color(0xff263b53));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(71, 75, 12, 9),
          const Radius.circular(2),
        ),
        fill(const Color(0xffe0e6ed)),
      );
      canvas.drawArc(
        const Rect.fromLTWH(73, 68, 8, 12),
        math.pi,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xffe0e6ed),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BadgePainter old) =>
      old.id != id || old.unlocked != unlocked;
}
