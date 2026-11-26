import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../core/widgets/sufra_snackbar.dart';
import '../../../../services/reset_code_service.dart';
import '../widgets/otp_code_field.dart';

/// Email -> 6-digit code (5 min countdown, resend) -> new password + confirm.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = '', this.service});
  final String initialEmail;
  final ResetCodeService? service;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final ResetCodeService _svc = widget.service ?? ResetCodeService();
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  final _code = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Timer? _timer;
  int _remaining = 0;
  bool _codeSent = false;
  bool _busy = false;
  bool _obscure = true;
  bool _done = false;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String _t(String ar, String en) => _ar ? ar : en;
  bool get _expired => _codeSent && _remaining <= 0;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _remaining = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining = _remaining > 0 ? _remaining - 1 : 0);
      if (_remaining <= 0) t.cancel();
    });
  }

  String _err(Object e) {
    final c = e is ResetCodeException ? e.code : 'unknown';
    switch (c) {
      case 'invalid_code':
        return _t('الكود غير صحيح', 'The code is incorrect');
      case 'expired':
        return _t(
          'انتهت صلاحية الكود، اطلب كود جديد',
          'The code expired, request a new one',
        );
      case 'rate_limited':
        return _t(
          'محاولات كتير، استنى شوية وجرب تاني',
          'Too many attempts, wait a bit',
        );
      case 'weak_password':
        return _t(
          'كلمة المرور ضعيفة (8 أحرف على الأقل)',
          'Password too weak (min 8 characters)',
        );
      case 'network':
        return _t('مشكلة في الاتصال', 'Network problem');
      default:
        return _t('حصلت مشكلة، حاول تاني', 'Something went wrong, try again');
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SufraSnackBar(content: Text(m)));

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      _toast(_t('اكتب بريد إلكتروني صحيح', 'Enter a valid email'));
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final secs = await _svc.requestCode(email);
      _code.clear();
      _codeSent = true;
      _startTimer(secs);
      _toast(
        _t(
          'بعتنالك كود من 6 أرقام على بريدك',
          'We sent a 6-digit code to your email',
        ),
      );
    } catch (e) {
      _toast(_err(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReset() async {
    if (!(_formKey.currentState?.validate() ?? false) || _busy) return;
    if (_expired) {
      _toast(_err(ResetCodeException('expired')));
      return;
    }
    setState(() => _busy = true);
    try {
      await _svc.confirm(
        email: _email.text,
        code: _code.text.trim(),
        newPassword: _pass.text,
      );
      _timer?.cancel();
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (e is ResetCodeException && e.code == 'expired') {
        setState(() => _remaining = 0);
      }
      _toast(_err(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String hint, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    isDense: true,
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    final mm = (_remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (_remaining % 60).toString().padLeft(2, '0');
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: GlassCard(
                        borderColor: AppColors.orangeLight.withValues(
                          alpha: .5,
                        ),
                        padding: const EdgeInsets.all(18),
                        child: _done ? _success() : _form(mm, ss),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _success() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.check_circle_rounded,
        size: 64,
        color: AppColors.orangeLight,
      ),
      const SizedBox(height: 12),
      Text(
        _t('تم تغيير كلمة المرور', 'Password changed'),
        style: context.displayStyle(size: 24),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        _t(
          'سجّل دخول بكلمة المرور الجديدة.',
          'Sign in with your new password.',
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      GradientButton(
        label: _t('رجوع لتسجيل الدخول', 'Back to sign in'),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    ],
  );

  Widget _form(String mm, String ss) => Form(
    key: _formKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _t('نسيت كلمة المرور', 'Forgot password'),
          style: context.displayStyle(size: 26),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          _t(
            'اكتب بريدك وهنبعتلك كود من 6 أرقام صالح 5 دقايق.',
            'Enter your email and we will send a 6-digit code valid for 5 minutes.',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _email,
          enabled: !_codeSent,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          decoration: _dec(_t('البريد الإلكتروني', 'Email')),
        ),
        const SizedBox(height: 12),
        if (!_codeSent)
          GradientButton(
            label: _busy ? '...' : _t('ابعت الكود', 'Send code'),
            onPressed: _busy ? null : _send,
          )
        else ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (_expired ? Colors.redAccent : AppColors.orangeLight)
                    .withValues(alpha: .7),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: _expired ? Colors.redAccent : AppColors.orangeLight,
                ),
                const SizedBox(width: 8),
                Text(
                  _expired
                      ? _t('انتهت صلاحية الكود', 'Code expired')
                      : '${_t('الكود صالح لمدة', 'Code valid for')} $mm:$ss',
                  key: const Key('reset-countdown'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _t('اكتب الكود اللي وصلك', 'Enter the code we emailed you'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          FormField<String>(
            validator: (_) => _code.text.length != 6
                ? _t('اكتب الكود المكوّن من 6 أرقام', 'Enter the 6-digit code')
                : null,
            builder: (state) => Column(
              children: [
                OtpCodeField(
                  controller: _code,
                  enabled: !_busy,
                  semanticLabel: _t('كود التحقق', 'Verification code'),
                  onCompleted: (_) => state.didChange(_code.text),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _pass,
            obscureText: _obscure,
            textDirection: TextDirection.ltr,
            decoration: _dec(
              _t('كلمة المرور الجديدة', 'New password'),
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v ?? '').length < 8
                ? _t('8 أحرف على الأقل', 'At least 8 characters')
                : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _confirm,
            obscureText: _obscure,
            textDirection: TextDirection.ltr,
            decoration: _dec(_t('تأكيد كلمة المرور', 'Confirm password')),
            validator: (v) => v != _pass.text
                ? _t('كلمتا المرور غير متطابقتين', 'Passwords do not match')
                : null,
          ),
          const SizedBox(height: 14),
          if (_expired)
            GradientButton(
              label: _busy ? '...' : _t('ابعت كود جديد', 'Resend code'),
              onPressed: _busy ? null : _send,
            )
          else ...[
            GradientButton(
              label: _busy ? '...' : _t('غيّر كلمة المرور', 'Change password'),
              onPressed: _busy ? null : _confirmReset,
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _busy ? null : _send,
              child: Text(_t('ابعت الكود تاني', 'Resend code')),
            ),
          ],
        ],
      ],
    ),
  );
}
