import 'package:flutter/material.dart';
import '../core/app_router.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  static const _goals = ['صيام صحي', 'تخسيس', 'لياقة'];
  String _goal = 'صيام صحي';
  bool _agree = true;
  bool _loading = false;
  int _strength = 0; // 0..3

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  int _calcStrength(String p) {
    if (p.isEmpty) return 0;
    if (p.length < 8) return 1;
    var score = 1;
    if (RegExp(r'[A-Za-z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p) && RegExp(r'[^A-Za-z0-9]').hasMatch(p)) {
      score++;
    }
    return score.clamp(1, 3);
  }

  String get _strengthLabel =>
      const ['', 'ضعيفة', 'متوسطة', 'قوية'][_strength];

  Color get _strengthColor => _strength == 1
      ? Colors.redAccent
      : _strength == 2
      ? AppColors.orange
      : Colors.greenAccent;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      _msg('لازم توافق على الشروط والخصوصية');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        goal: _goal,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      icon:
                      const Icon(Icons.arrow_forward, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(
                    height: 190,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/koshari.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                            top: 0, right: 60, child: _dish(Icons.set_meal, 50)),
                        Positioned(
                            top: 30,
                            left: 60,
                            child: _dish(Icons.rice_bowl, 44)),
                        Positioned(
                            bottom: 8,
                            right: 90,
                            child: _dish(Icons.restaurant, 40)),
                      ],
                    ),
                  ),
                  Text('ابدأ سفرتك،',
                      style: AppText.title(32), textAlign: TextAlign.center),
                  Text('كُل حقيقي',
                      style: AppText.title(32, color: AppColors.orange),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const DotsIndicator(
                      count: 3, index: 1, activeColor: AppColors.orange),
                  const SizedBox(height: 14),
                  GlassCard(
                    child: Column(
                      children: [
                        GlassField(
                          controller: _name,
                          hint: 'الاسم',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'اكتب اسمك'
                              : null,
                        ),
                        const SizedBox(height: 12),
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
                          hint: 'كلمة السر (٨ حروف على الأقل)',
                          obscure: true,
                          onChanged: (v) =>
                              setState(() => _strength = _calcStrength(v)),
                          validator: (v) => (v == null || v.length < 8)
                              ? '8 حروف على الأقل'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: List.generate(3, (i) {
                                  final on = i < _strength;
                                  return Expanded(
                                    child: Container(
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: on
                                            ? _strengthColor
                                            : Colors.white24,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 50,
                              child: Text(_strengthLabel,
                                  style: AppText.body(12,
                                      color: AppColors.textSoft)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: _goals.map((g) {
                            final sel = g == _goal;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _goal = g),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin:
                                  const EdgeInsets.symmetric(horizontal: 4),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: sel
                                        ? const LinearGradient(colors: [
                                      Color(0xFF7C4DFF),
                                      AppColors.cyan
                                    ])
                                        : null,
                                    color: sel ? null : Colors.white10,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                        color: AppColors.glassBorder),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(g,
                                      style: AppText.body(13,
                                          weight: FontWeight.bold)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _agree,
                        activeColor: AppColors.orange,
                        onChanged: (v) => setState(() => _agree = v ?? false),
                      ),
                      Text('أوافق على ', style: AppText.body(13)),
                      Text('الشروط والخصوصية',
                          style: AppText.body(13, color: AppColors.cyan)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  PillButton(
                      text: 'إنشاء الحساب',
                      loading: _loading,
                      onPressed: _submit),
                  const SizedBox(height: 14),
                  const OrDivider(),
                  const SizedBox(height: 12),
                  SocialButtons(
                    onGoogle: () => _msg('التسجيل بجوجل هنفعّله لاحقا'),
                    onPhone: () => _msg('التسجيل برقم الموبايل هنفعّله لاحقا'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('عندك حساب؟ ',
                          style: AppText.body(13, color: AppColors.textSoft)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text('سجّل دخول',
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