import 'package:flutter/material.dart';

/// Circular crop of one cell from a 4x4 food sprite sheet.
///
/// The design ships food thumbnails as sprite atlases (assets/images/art/
/// spA.webp, spB.webp, spC.webp) referenced with
/// `background-size: 400% 400%; background-position: X% Y%`. [col] and [row]
/// are the 0-based cell coordinates, matching the CSS percentages
/// (0%, 33.33%, 66.67%, 100%).
class SpriteAvatar extends StatelessWidget {
  const SpriteAvatar({
    super.key,
    required this.asset,
    required this.col,
    required this.row,
    this.size = 52,
  }) : assert(col >= 0 && col < 4 && row >= 0 && row < 4);

  final String asset;
  final int col;
  final int row;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x8C000000),
            blurRadius: 10,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: OverflowBox(
            minWidth: size * 4,
            maxWidth: size * 4,
            minHeight: size * 4,
            maxHeight: size * 4,
            child: Transform.translate(
              // OverflowBox centers the 4x sheet, so shift by (cell - 1.5)
              // cells to bring the requested quadrant into view.
              offset: Offset(-(col - 1.5) * size, -(row - 1.5) * size),
              child: Image.asset(
                asset,
                width: size * 4,
                height: size * 4,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
