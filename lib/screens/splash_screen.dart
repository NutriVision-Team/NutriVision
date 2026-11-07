import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_router.dart';
import '../core/app_theme.dart';
import '../widgets/app_background.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..forward();
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);
  late final AnimationController _progress = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800))
    ..forward();

  @override
  void initState() {
    super.initState();
    _progress.addStatusListener((s) {
      if (s == AnimationStatus.completed) _goNext();
    });
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    final Widget next = FirebaseAuth.instance.currentUser == null
        ? const LoginScreen()
        : await screenAfterAuth();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_intro, _pulse]),
                  builder: (context, _) {
                    final t = Curves.easeOutBack.transform(_intro.value);
                    final glow = 50 + 50 * _pulse.value;
                    return Opacity(
                      opacity: _intro.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.7 + 0.3 * t + 0.03 * _pulse.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(48),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.cyan
                                        .withOpacity(0.25 + 0.2 * _pulse.value),
                                    blurRadius: glow,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              child: Image.asset('assets/images/logo.png',
                                  width: 210),
                            ),
                            const SizedBox(height: 56),
                            Text('سفرة', style: AppText.title(56)),
                            const SizedBox(height: 10),
                            Text('صحتك على سفرتك',
                                style:
                                AppText.body(18, color: AppColors.cyan)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: Column(
                  children: [
                    Text('بالهنا والشفا',
                        style: AppText.body(16, color: AppColors.orange)),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 260,
                      child: AnimatedBuilder(
                        animation: _progress,
                        builder: (context, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _progress.value,
                            minHeight: 4,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF7C4DFF)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}