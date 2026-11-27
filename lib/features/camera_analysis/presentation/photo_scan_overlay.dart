import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';

/// The HTML's cyan scan beam, tied only to the actual in-flight request.
/// Movement is decorative, never a percentage or fabricated recognition result.
class PhotoScanOverlay extends StatefulWidget {
  const PhotoScanOverlay({super.key});
  @override
  State<PhotoScanOverlay> createState() => _PhotoScanOverlayState();
}

class _PhotoScanOverlayState extends State<PhotoScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beam = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _beam.stop();
    } else {
      _beam.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _beam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return ColoredBox(
      color: const Color(0x660A1022),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _beam,
            builder: (_, _) => Align(
              alignment: Alignment(0, -.85 + _beam.value * 1.65),
              child: Container(
                height: 60,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x7706B6D4),
                      Color(0xCCA5F3FC),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFA5F3FC), width: 2),
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0x6606B6D4), blurRadius: 24),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ar ? 'بنحلّل وجبتك' : 'Recognizing your meal',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    ar
                        ? 'Gemma · بنستنى نتيجة التعرّف'
                        : 'Gemma · Waiting for recognition',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0)
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0x4467E8F9),
                            ),
                          ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: i < 2
                                  ? const Color(0x3306B6D4)
                                  : const Color(0x22FFFFFF),
                              child: Icon(
                                i == 0
                                    ? Icons.check
                                    : i == 1
                                    ? Icons.sync
                                    : i == 2
                                    ? Icons.fact_check_outlined
                                    : Icons.calculate_outlined,
                                size: 17,
                                color: i < 2
                                    ? const Color(0xFFA5F3FC)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              (ar
                                  ? ['تجهيز', 'إرسال وفهم', 'مطابقة', 'حساب']
                                  : [
                                      'Ready',
                                      'Recognize',
                                      'Match',
                                      'Calculate',
                                    ])[i],
                              style: TextStyle(
                                fontSize: 11,
                                color: i < 2
                                    ? const Color(0xFFA5F3FC)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ar
                        ? 'الحساب بعد مطابقة الأصناف وتأكيد الكميات'
                        : 'Calculation follows matched foods and confirmed portions',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
