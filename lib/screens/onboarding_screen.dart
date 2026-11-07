import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_widgets.dart';
import 'welcome_screen.dart';

class _OnboardData {
  final String image;
  final String title;
  final String subtitle;
  const _OnboardData(this.image, this.title, this.subtitle);
}

const _pages = [
  _OnboardData(
    'assets/images/onboard_1.png',
    'سجّل أكلك بالكلام',
    'قول اللي أكلته بالعامية وإحنا نفهمك في ثواني',
  ),
  _OnboardData(
    'assets/images/onboard_2.png',
    'أرقام تقدر تثق فيها',
    'بنحسب من مكونات الطبق نفسه، مش تخمين',
  ),
  _OnboardData(
    'assets/images/onboard_3.png',
    'أكلك المصري كلّه',
    'كشري، فول، ملوخية، محشي... كلها في سفرة',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pc = PageController();
  late final AnimationController _float = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat(reverse: true);
  late final AnimationController _reset = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));

  int _index = 0;
  double _dragX = 0, _dragY = 0, _fromX = 0, _fromY = 0;

  @override
  void initState() {
    super.initState();
    _reset.addListener(() {
      final k = 1 - Curves.easeOutBack.transform(_reset.value);
      _dragX = _fromX * k;
      _dragY = _fromY * k;
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    _float.dispose();
    _reset.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      await AuthService.instance.markOnboardingSeen();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _pc.nextPage(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  double get _page =>
      (_pc.hasClients && _pc.position.haveDimensions) ? (_pc.page ?? 0) : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _finish,
                      child: Text('تخطي',
                          style: AppText.body(14, color: AppColors.textSoft)),
                    ),
                    const Spacer(),
                    Text('${_index + 1} / ${_pages.length}',
                        style: AppText.body(13, color: AppColors.textSoft)),
                  ],
                ),
              ),
              // القوس الزجاجي + الصورة 3D
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.glass,
                      border: Border.all(color: AppColors.glassBorder),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(200),
                        topRight: Radius.circular(200),
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onPanStart: (_) => _reset.stop(),
                            onPanUpdate: (d) => setState(() {
                              _dragY = (_dragY + d.delta.dx * 0.012)
                                  .clamp(-1.0, 1.0);
                              _dragX = (_dragX - d.delta.dy * 0.012)
                                  .clamp(-0.6, 0.6);
                            }),
                            onPanEnd: (_) {
                              _fromX = _dragX;
                              _fromY = _dragY;
                              _reset.forward(from: 0);
                            },
                            child: Center(
                              child: AnimatedBuilder(
                                animation:
                                Listenable.merge([_pc, _float, _reset]),
                                builder: (context, _) {
                                  final p = _page;
                                  final cur = p
                                      .round()
                                      .clamp(0, _pages.length - 1);
                                  // لفّة: الصورة بتبقى جنب (edge-on) في نص التنقل
                                  final flip = (p - cur) * math.pi;
                                  final dy =
                                      Curves.easeInOut.transform(_float.value) *
                                          16 -
                                          8;
                                  return Transform.translate(
                                    offset: Offset(0, dy),
                                    child: Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.0012)
                                        ..rotateX(_dragX)
                                        ..rotateY(flip + _dragY),
                                      child: Padding(
                                        padding: const EdgeInsets.all(28),
                                        child: Image.asset(_pages[cur].image,
                                            fit: BoxFit.contain),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text('اسحب عشان تدوّرها',
                              style:
                              AppText.body(13, color: AppColors.textSoft)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // النصوص (بتتحرك مع السحب)
              SizedBox(
                height: 110,
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => Column(
                    children: [
                      Text(_pages[i].title,
                          textAlign: TextAlign.center,
                          style: AppText.title(32)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_pages[i].subtitle,
                            textAlign: TextAlign.center,
                            style: AppText.body(16, color: AppColors.textSoft)),
                      ),
                    ],
                  ),
                ),
              ),
              DotsIndicator(count: _pages.length, index: _index),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: GradientButton(
                  text: _index == _pages.length - 1 ? 'يلا نبدأ' : 'التالي',
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}