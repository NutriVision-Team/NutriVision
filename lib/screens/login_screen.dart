import 'package:flutter/material.dart';
import '../core/app_router.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  late final AnimationController _float = AnimationController(
      vsync: this, duration: const Duration(seconds: 6))
    ..repeat();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _float.dispose();
    super.dispose();
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.login(_email.text, _password.text);
      final next = await screenAfterAuth();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => next),
            (r) => false,
      );
    } catch (e) {
      if (mounted) _msg(AuthService.instance.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    if (!_email.text.contains('@')) {
      _msg('اكتب الإيميل الأول');
      return;
    }
    try {
      await AuthService.instance.resetPassword(_email.text);
      _msg('لو الإيميل مسجل هتوصلك رسالة لإعادة كلمة السر');
    } catch (e) {
      _msg(AuthService.instance.errorMessage(e));
    }
  }

  Widget _dish(IconData icon, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.bgDark,
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Icon(icon, color: AppColors.orange, size: size * 0.5),
  );

  Widget _floating(Widget child, double phase, Alignment a) {
    return Align(
      alignment: a,
      child: AnimatedBuilder(
        animation: _float,
        builder: (_, c) => Transform.translate(
          offset: Offset(
              0, 6 * (0.5 - ((_float.value + phase) % 1.0)).abs() * 4 - 6),
          child: c,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(
                    height: 230,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/koshari.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        _floating(_dish(Icons.set_meal, 56), 0.0,
                            const Alignment(0.6, -0.95)),
                        _floating(_dish(Icons.rice_bowl, 50), 0.35,
                            const Alignment(-0.65, -0.5)),
                        _floating(_dish(Icons.restaurant, 44), 0.7,
                            const Alignment(0.4, 0.85)),
                      ],
                    ),
                  ),
                  Text('ما تاكلش أقل،',
                      style: AppText.title(34), textAlign: TextAlign.center),
                  Text('كُل صح',
                      style: AppText.title(34, color: AppColors.orange),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('سجّل دخولك وكمّل رحلتك الصحية',
                      style: AppText.body(14, color: AppColors.textSoft)),
                  const SizedBox(height: 10),
                  const DotsIndicator(
                      count: 3, index: 2, activeColor: AppColors.orange),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      children: [
                        GlassField(
                          controller: _email,
                          hint: 'الإيميل',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'اكتب إيميل صحيح'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        GlassField(
                          controller: _password,
                          hint: 'كلمة السر',
                          obscure: _hide,
                          prefix: IconButton(
                            icon: Icon(
                                _hide ? Icons.visibility : Icons.visibility_off,
                                color: AppColors.cyan),
                            onPressed: () => setState(() => _hide = !_hide),
                          ),
                          validator: (v) => (v == null || v.length < 8)
                              ? '8 حروف على الأقل'
                              : null,
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            onPressed: _forgot,
                            child: Text('نسيت كلمة السر؟',
                                style: AppText.body(13, color: AppColors.cyan)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                      text: 'تسجيل الدخول',
                      loading: _loading,
                      onPressed: _submit),
                  const SizedBox(height: 16),
                  const OrDivider(),
                  const SizedBox(height: 14),
                  SocialButtons(
                    onGoogle: () => _msg('الدخول بجوجل هنفعّله لاحقا'),
                    onPhone: () => _msg('الدخول برقم الموبايل هنفعّله لاحقا'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('معندكش حساب؟ ',
                          style: AppText.body(13, color: AppColors.textSoft)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: Text('أنشئ حساب جديد',
                            style: AppText.body(13,
                                color: AppColors.orange,
                                weight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}