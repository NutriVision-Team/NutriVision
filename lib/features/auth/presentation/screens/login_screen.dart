import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/user_profile_model.dart';
import '../../../../data/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../owner_policy_consent.dart';
import '../widgets/google_identity_button.dart';
import '../cubit/session_cubit.dart';
import '../personal_educational_policy.dart';
import 'package:flutter/material.dart';
import 'package:sufradepi/core/widgets/sufra_button_response.dart';
import 'forgot_password_screen.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../core/widgets/sprite_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import '../cubit/auth_error_mapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.startGoogle = false});
  final bool startGoogle;

  static const String routePath = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.startGoogle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _google();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await AuthService.instance.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Navigation is handled by the router redirect on auth state change.
    } catch (error) {
      if (mounted) {
        _showError(mapAuthError(l10n, error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _google() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final repository = context.read<UserRepository>();
    final session = context.read<SessionCubit>();
    bool accepted = false;
    final mode = await showSufraDialog<String>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => SufraAlertDialog(
          title: Text(l.googleProvider),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ar
                      ? 'لو جوجل مربوط بحسابك، كمّل بجوجل عادي. لو عندك حساب بإيميل وباسورد ولسه ماربطتوش، اكتبهم في شاشة الدخول واختار ربط حساب الإيميل الحالي، وبعدين اختار نفس بريد جوجل عشان تحافظ على الباسورد والبيانات. الحساب الجديد محتاج موافقة الشروط.'
                      : 'Google already linked? Continue with Google normally. For an email/password account not linked yet, enter those details on the login screen, choose Link email account, then select the same Google email to preserve password access and data. New accounts need policy acceptance.',
                ),
                OwnerPolicyConsent(
                  config: personalEducationalPolicy,
                  onChanged: (v) => update(() => accepted = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(l.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, 'link'),
              child: Text(
                ar ? 'ربط حساب الإيميل الحالي' : 'Link email account',
              ),
            ),
            TextButton(
              onPressed: accepted ? () => Navigator.pop(c, 'google') : null,
              child: Text(
                ar
                    ? 'كمّل بجوجل / حساب جديد'
                    : 'Continue with Google / new account',
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || mode == null) return;
    if (mode == 'link' && !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final auth = AuthService.instance;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final previousUid = auth.currentUser?.uid;
    try {
      await session.completeAuthOperation(() async {
        try {
          if (mode == 'link') {
            await auth.signInWithEmail(email: email, password: password);
            final existing = await repository.getCurrentUser();
            if (existing == null && !accepted) {
              await auth.signOut();
              throw StateError(
                'Policy acceptance required for missing profile',
              );
            }
          }
          final user = await auth.signInWithGoogle(
            linkExisting: mode == 'link',
            // Only the web build uses the Google button dialog. On Android and iOS
            // the native account picker is opened by the gateway.
            chooseWebIdentity: kIsWeb
                ? () => chooseSufraGoogleIdentity(context)
                : null,
          );
          if (user == null) throw StateError('Missing Google user');
          if (await repository.getCurrentUser() == null) {
            await repository.upsertUser(
              UserProfileModel(
                uid: user.uid,
                displayName: user.displayName ?? '',
                email: user.email,
                preferredLanguage: ar ? 'ar' : 'en',
                timezone: DateTime.now().timeZoneName,
                policyAcceptance: {
                  'termsVersion': personalEducationalPolicy.termsVersion,
                  'privacyVersion': personalEducationalPolicy.privacyVersion,
                  'mechanism': 'google_registration_checkbox',
                  'recordedAt': FieldValue.serverTimestamp(),
                },
              ),
            );
          }
        } catch (_) {
          // A canceled link or failed profile write must not leave a fresh
          // password session routed into setup behind the Google dialog.
          if (previousUid == null) await auth.signOut();
          rethrow;
        }
      });
    } catch (error) {
      if (mounted) _showError(mapAuthError(l, error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_submitting) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ForgotPasswordScreen(initialEmail: _emailController.text.trim()),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SufraSnackBar(content: Text(message)));
  }

  void _providerToast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SufraSnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Column(
                    children: [
                      const AuthPlateArt(size: 270),
                      const SizedBox(height: 12),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: context
                              .displayStyle(size: 32)
                              .copyWith(
                                fontFamily: AppTheme.fontFamily,
                                height: 1.4,
                              ),
                          children: [
                            TextSpan(text: '${l10n.loginTitleA}\n'),
                            TextSpan(
                              text: l10n.loginTitleB,
                              style: context.accentStyle(
                                size: 40,
                                color: AppColors.copper,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.loginSubtitle, style: context.mutedStyle()),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == 0 ? 26 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == 0
                                    ? AppColors.copper
                                    : Colors.white.withValues(alpha: .3),
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        borderColor: AppColors.orangeLight.withValues(
                          alpha: .5,
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  hintText: l10n.emailHint,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) return l10n.validationRequired;
                                  if (!v.contains('@') || !v.contains('.')) {
                                    return l10n.validationEmail;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  hintText: l10n.passwordHint,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.cyanLight
                                          : const Color(0xFF006A80),
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (value) {
                                  if ((value ?? '').isEmpty) {
                                    return l10n.validationRequired;
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: SufraControlFeedback(
                                  radius: 8,
                                  overlay: true,
                                  child: GestureDetector(
                                    onTap: _resetPassword,
                                    child: Text(
                                      l10n.forgotPassword,
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.cyanLight
                                            : const Color(0xFF006A80),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: MediaQuery.textScalerOf(context).scale(16) > 22
                            ? GradientButton(
                                label: l10n.loginButton,
                                height: 112,
                                isLoading: _submitting,
                                onPressed: _submit,
                              )
                            : IconPillButton(
                                label: l10n.loginButton,
                                isLoading: _submitting,
                                onPressed: _submit,
                              ),
                      ),
                      const SizedBox(height: 14),
                      _OrDivider(label: l10n.orContinueWith),
                      const SizedBox(height: 10),
                      Flex(
                        direction:
                            MediaQuery.textScalerOf(context).scale(13) > 18
                            ? Axis.vertical
                            : Axis.horizontal,
                        children: [
                          FlexibleProviderPill(
                            child: GlassPillButton(
                              label: l10n.googleProvider,
                              leading: const GoogleProviderBadge(),
                              onPressed: () {
                                if (!_submitting) _google();
                              },
                            ),
                          ),
                          const SizedBox(width: 10, height: 10),
                          FlexibleProviderPill(
                            child: GlassPillButton(
                              label: l10n.phoneProvider,
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryBlue,
                                      AppColors.turquoise,
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.phone_outlined,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: () => _providerToast(
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'الدخول برسائل الموبايل محتاج خطة مدفوعة حسب Firebase. استخدم الإيميل أو جوجل، مش هنفعّل دفع.'
                                    : 'Firebase SMS sign-in requires a paid plan. Use email or Google; billing stays off.',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 8,
                        children: [
                          Text(l10n.noAccount, style: context.mutedStyle()),
                          SufraControlFeedback(
                            radius: 8,
                            overlay: true,
                            child: GestureDetector(
                              onTap: () => context.go('/register'),
                              child: Text(
                                l10n.createAccountLink,
                                style: const TextStyle(
                                  color: AppColors.copper,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Circular plate composition from the auth designs: halo ring, dashed
/// spinning orbit, main plate and three floating small plates.
class AuthPlateArt extends StatefulWidget {
  const AuthPlateArt({super.key, this.size = 300, this.registration = false});

  final double size;
  final bool registration;

  @override
  State<AuthPlateArt> createState() => _AuthPlateArtState();
}

class _AuthPlateArtState extends State<AuthPlateArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _plate(double size, int col, int row) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: AppColors.aiPurple.withValues(alpha: .6),
          blurRadius: 18,
        ),
      ],
    ),
    child: SpriteAvatar(
      asset: 'assets/images/art/spA.webp',
      col: col,
      row: row,
      size: size - 6,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: s * 0.86,
            height: s * 0.86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              gradient: RadialGradient(
                colors: [
                  AppColors.aiPurple.withValues(alpha: 0.38),
                  AppColors.aiPurple.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * 3.14159265,
                child: CustomPaint(
                  size: Size.square(s * .69),
                  painter: _AuthOrbitPainter(),
                ),
              );
            },
          ),
          Container(
            width: s * 0.64,
            height: s * 0.64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkBackground,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 40,
                ),
                BoxShadow(
                  color: AppColors.turquoise.withValues(alpha: 0.4),
                  blurRadius: 40,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: SpriteAvatar(
                asset: 'assets/images/art/spA.webp',
                col: widget.registration ? 3 : 0,
                row: 0,
                size: 192,
              ),
            ),
          ),
          Positioned(
            right: s * .02,
            top: s * .12,
            child: _plate(
              widget.registration ? 50 * s / 230 : 60 * s / 300,
              widget.registration ? 0 : 1,
              widget.registration ? 1 : 2,
            ),
          ),
          Positioned(
            left: s * .0133,
            top: s * .32,
            child: _plate(
              widget.registration ? 42 * s / 230 : 48 * s / 300,
              widget.registration ? 1 : 3,
              widget.registration ? 3 : 0,
            ),
          ),
          Positioned(
            right: s * .10,
            bottom: s * .02,
            child: _plate(
              widget.registration ? 40 * s / 230 : 46 * s / 300,
              widget.registration ? 1 : 2,
              widget.registration ? 0 : 3,
            ),
          ),
          Positioned(
            left: s * .0133,
            top: s * .10,
            child: Transform.rotate(
              angle: -.52,
              child: const _AuthLeaf(size: 24),
            ),
          ),
          Positioned(
            right: s * .0067,
            top: s * .62,
            child: Transform.rotate(
              angle: .7,
              child: const _AuthLeaf(size: 20),
            ),
          ),
          Positioned(
            left: s * .30,
            bottom: 0,
            child: Transform.rotate(
              angle: .17,
              child: const _AuthLeaf(size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthOrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.cyanLight.withValues(alpha: .35);
    final rect = Rect.fromLTWH(.5, .5, size.width - 1, size.height - 1);
    final step = 2 * math.pi / 72;
    for (var i = 0; i < 72; i++) {
      canvas.drawArc(rect, i * step, step * .48, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuthLeaf extends StatelessWidget {
  const _AuthLeaf({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _AuthLeafPainter());
}

class _AuthLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final leaf = Path()
      ..moveTo(4, 20)
      ..cubicTo(4, 9, 12, 4, 21, 3)
      ..cubicTo(21, 12, 16, 20, 4, 20)
      ..close();
    canvas.drawShadow(leaf, Colors.black.withValues(alpha: .5), 3, false);
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF22C55E));
    canvas.drawLine(
      const Offset(4, 20),
      const Offset(13, 11),
      Paint()
        ..color = AppColors.darkBackground
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0x4DFFFFFF)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x4DFFFFFF), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Official Google brand mark, bundled for offline sign-in presentation.
class GoogleProviderBadge extends StatelessWidget {
  const GoogleProviderBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Image.asset('assets/images/google_g.png', width: 20, height: 20),
    );
  }
}

class FlexibleProviderPill extends StatelessWidget {
  const FlexibleProviderPill({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(13) > 18
      ? Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: child)
      : Expanded(child: child);
}
