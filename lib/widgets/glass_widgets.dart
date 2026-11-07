import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// كارت زجاجي
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const GlassCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: child,
    );
  }
}

/// حقل إدخال بشكل كبسولة زجاجية
class GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? prefix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const GlassField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.prefix,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  OutlineInputBorder _b(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide(color: c, width: w),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: AppText.body(15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(15, color: AppColors.textSoft),
        prefixIcon: prefix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: _b(AppColors.glassBorder),
        enabledBorder: _b(AppColors.glassBorder),
        focusedBorder: _b(AppColors.cyan, 1.5),
        errorBorder: _b(Colors.redAccent),
        focusedErrorBorder: _b(Colors.redAccent),
      ),
    );
  }
}

/// زرار كبسولة مع دايرة برتقالي وسهم
class PillButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  const PillButton(
      {super.key, required this.text, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                  color: AppColors.orange, shape: BoxShape.circle),
              child: loading
                  ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
                  : const Icon(Icons.chevron_left, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Text(text, style: AppText.title(20)),
            ),
          ],
        ),
      ),
    );
  }
}

/// زرار عريض بتدرج أزرق وسماوي (التالي / يلا نبدأ)
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const GradientButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF15C3D6)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: AppColors.cyan.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Text(text, style: AppText.title(20)),
      ),
    );
  }
}

/// نقط الصفحات
class DotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  final Color activeColor;
  const DotsIndicator(
      {super.key,
        required this.count,
        required this.index,
        this.activeColor = AppColors.cyan});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 30 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}

/// خط "أو كمّل بـ"
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('أو كمّل بـ',
              style: AppText.body(12, color: AppColors.textSoft)),
        ),
        const Expanded(child: Divider(color: Colors.white24)),
      ],
    );
  }
}

/// زراري جوجل ورقم الموبايل
class SocialButtons extends StatelessWidget {
  final VoidCallback onGoogle;
  final VoidCallback onPhone;
  const SocialButtons(
      {super.key, required this.onGoogle, required this.onPhone});

  Widget _btn(String text, Widget icon, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(text,
                style: AppText.body(14, weight: FontWeight.bold)),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _btn(
          'جوجل',
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: const Text('G',
                style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
          ),
          onGoogle,
        ),
        const SizedBox(width: 12),
        _btn(
          'رقم الموبايل',
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
                color: Color(0xFF1E88E5), shape: BoxShape.circle),
            child: const Icon(Icons.phone, color: Colors.white, size: 16),
          ),
          onPhone,
        ),
      ],
    );
  }
}