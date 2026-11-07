import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_widgets.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600))
    ..forward();
  late final AnimationController _loop =
  AnimationController(vsync: this, duration: const Duration(seconds: 8))
    ..repeat();

  late final Future<String> _nameFuture = _loadName();

  static final _tiles = [
    (Icons.mic_rounded, 'تسجّل أكلك بصوتك بالعامية', const Color(0xFF9C7BFF)),
    (Icons.analytics_rounded, 'أرقام من مكونات الطبق نفسه', AppColors.cyan),
    (Icons.restaurant_rounded, 'كشري وفول وملوخية وأكتر', AppColors.orange),
  ];

  Future<String> _loadName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final n = (doc.data()?['name'] ?? user.displayName ?? '') as String;
      return n.trim().split(' ').first;
    } catch (_) {
      return (user.displayName ?? '').trim().split(' ').first;
    }
  }

  double _t(double a, double b) => Curves.easeOutCubic
      .transform(((_in.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  Widget _img(String asset, double width, Alignment align, double a, double b,
      double phase) {
    return Align(
      alignment: align,
      child: AnimatedBuilder(
        animation: Listenable.merge([_in, _loop]),
        builder: (_, __) {
          final t = _t(a, b);
          final dy = math.sin((_loop.value + phase) * 2 * math.pi) * 6;
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 40 + dy),
              child: Transform.scale(
                scale: 0.8 + 0.2 * t,
                child: Image.asset(asset, width: width),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            // الكونفيتي
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ConfettiPainter(_loop)),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    SizedBox(
                      height: 300,
                      child: Stack(
                        children: [
                          _img('assets/images/onboard_1.png', 210,
                              const Alignment(0, -1), 0.0, 0.4, 0.0),
                          _img('assets/images/onboard_2.png', 170,
                              const Alignment(-1, 0.9), 0.1, 0.5, 0.3),
                          _img('assets/images/onboard_3.png', 170,
                              const Alignment(1, 0.9), 0.2, 0.6, 0.6),
                        ],
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _in,
                      builder: (_, child) => Opacity(
                        opacity: _t(0.25, 0.55),
                        child: Transform.translate(
                            offset: Offset(0, (1 - _t(0.25, 0.55)) * 20),
                            child: child),
                      ),
                      child: Column(
                        children: [
                          FutureBuilder<String>(
                            future: _nameFuture,
                            builder: (context, snap) {
                              final n = snap.data ?? '';
                              return Text(
                                n.isEmpty ? 'أهلاً بيك' : 'أهلاً بيك يا $n',
                                style: AppText.title(36),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Text('حسابك اتعمل، وسفرتك جاهزة. بالهنا والشفا',
                              textAlign: TextAlign.center,
                              style:
                              AppText.body(14, color: AppColors.textSoft)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    for (var i = 0; i < _tiles.length; i++)
                      AnimatedBuilder(
                        animation: _in,
                        builder: (_, child) {
                          final t = _t(0.4 + i * 0.1, 0.75 + i * 0.1);
                          return Opacity(
                            opacity: t,
                            child: Transform.translate(
                                offset: Offset((1 - t) * 70, 0), child: child),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.white.withOpacity(0.06),
                              const Color(0xFF3F3AA8).withOpacity(0.35),
                            ]),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                  Border.all(color: _tiles[i].$3, width: 2),
                                ),
                                child: Icon(_tiles[i].$1,
                                    color: _tiles[i].$3, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(_tiles[i].$2,
                                    style: AppText.body(15,
                                        weight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _in,
                      builder: (_, child) =>
                          Opacity(opacity: _t(0.7, 1.0), child: child),
                      child: GradientButton(
                        text: 'يلا نبدأ',
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content:
                            Text('الشاشة الرئيسية في الخطوة الجاية'))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // زرار تسجيل الخروج
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  tooltip: 'تسجيل خروج',
                  onPressed: () async {
                    await AuthService.instance.logout();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (r) => false,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// حبّات كونفيتي صغيرة بتنزل ببطء
class _ConfettiPainter extends CustomPainter {
  final Animation<double> loop;
  _ConfettiPainter(this.loop) : super(repaint: loop);

  static final _rnd = math.Random(7);
  static final _colors = [
    AppColors.cyan,
    AppColors.orange,
    const Color(0xFF9C7BFF),
    Colors.greenAccent,
  ];
  static final _items = List.generate(
    22,
        (_) => (
    x: _rnd.nextDouble(),
    y: _rnd.nextDouble(),
    speed: 0.4 + _rnd.nextDouble() * 0.8,
    size: 2.0 + _rnd.nextDouble() * 3.5,
    color: _colors[_rnd.nextInt(4)],
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _items) {
      final y = ((p.y + loop.value * p.speed) % 1.0) * size.height;
      final x = p.x * size.width + math.sin(loop.value * 6 + p.y * 10) * 8;
      canvas.drawCircle(
          Offset(x, y), p.size, Paint()..color = p.color.withOpacity(0.75));
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => false;
}