import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import '../owner_policy_consent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../personal_educational_policy.dart';
import 'package:flutter/material.dart';
import 'package:sufradepi/core/widgets/sufra_button_response.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nebula_background.dart';
import '../../../../data/models/user_profile_model.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/auth_service.dart';
import '../cubit/auth_error_mapper.dart';
import '../cubit/session_cubit.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.policy = personalEducationalPolicy});
  final OwnerPolicyConfig policy;

  static const String routePath = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  final _policyAcceptance = PolicyAcceptance();
  bool get _acceptedTerms => _policyAcceptance.accepts(widget.policy);
  @override
  void didUpdateWidget(covariant RegisterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.policy.binding != widget.policy.binding) {
      _policyAcceptance.invalidate();
    }
  }

  bool _submitting = false;
  String _interest = 'weight_loss';
  SessionCubit? _sessionCubit;
  UserRepository? _userRepository;
  String _languageCode = 'ar';
  bool get _ar => _languageCode == 'ar';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sessionCubit ??= context.read<SessionCubit>();
    _userRepository ??= context.read<UserRepository>();
    _languageCode = Localizations.localeOf(context).languageCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _confirmController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    var score = 1;
    if (p.length >= 8) score++;
    if (p.length >= 10 &&
        RegExp(r'[0-9]').hasMatch(p) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(p)) {
      score++;
    }
    return score.clamp(1, 3);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      _showError(l10n.registrationPolicyUnavailable);
      return;
    }
    if (_submitting) return;
    final displayName =
        '${_nameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final repository = _userRepository!;
    final language = _languageCode;
    setState(() => _submitting = true);
    try {
      final user = await AuthService.instance.createUserWithEmail(
        email: email,
        password: password,
      );
      final uid = user?.uid;
      if (uid == null) {
        throw StateError('Registration returned no user');
      }
      if (AuthService.instance.currentUser?.uid != uid) {
        throw StateError('Registration owner changed');
      }
      await user?.updateDisplayName(displayName);
      if (AuthService.instance.currentUser?.uid != uid) {
        throw StateError('Registration owner changed');
      }
      await repository.upsertUser(
        UserProfileModel(
          uid: uid,
          displayName: displayName,
          email: email,
          preferredLanguage: language,
          timezone: DateTime.now().timeZoneName,
          onboardingCompleted: false,
          policyAcceptance: {
            'termsVersion': widget.policy.termsVersion,
            'privacyVersion': widget.policy.privacyVersion,
            'mechanism': 'registration_checkbox',
            'recordedAt': FieldValue.serverTimestamp(),
          },
        ),
      );
      final sessionCubit = _sessionCubit;
      if (mounted && sessionCubit != null) {
        await sessionCubit.refreshProfile();
      }
      // Router redirect sends the fresh account to the welcome screen.
    } catch (error) {
      if (mounted) _showError(mapAuthError(l10n, error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SufraSnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final strength = _passwordStrength;
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
                      const AuthPlateArt(size: 180, registration: true),
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
                            TextSpan(text: '${l10n.registerTitleA}\n'),
                            TextSpan(
                              text: l10n.registerTitleB,
                              style: const TextStyle(color: AppColors.copper),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == 1 ? 26 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == 1
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: _ar ? 'الاسم الأول' : 'First name',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                validator: (value) =>
                                    (value?.trim().isEmpty ?? true)
                                    ? l10n.validationName
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _lastNameController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: _ar ? 'اسم العائلة' : 'Last name',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                validator: (value) =>
                                    (value?.trim().isEmpty ?? true)
                                    ? l10n.validationName
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  hintText: l10n.emailHint,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
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
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: l10n.passwordRegisterHint,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: AppColors.cyanLight,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (value) {
                                  final v = value ?? '';
                                  if (v.length < 8) {
                                    return l10n.validationPassword;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              _StrengthMeter(strength: strength),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: _obscure,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  hintText: _ar
                                      ? 'تأكيد كلمة المرور'
                                      : 'Confirm password',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                validator: (value) =>
                                    value != _passwordController.text
                                    ? (_ar
                                          ? 'كلمتا المرور غير متطابقتين'
                                          : 'Passwords do not match')
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  SelectableSufraChip(
                                    label: l10n.interestHealthyFasting,
                                    selected: _interest == 'fasting',
                                    onTap: () =>
                                        setState(() => _interest = 'fasting'),
                                  ),
                                  SelectableSufraChip(
                                    label: l10n.interestWeightLoss,
                                    selected: _interest == 'weight_loss',
                                    onTap: () => setState(
                                      () => _interest = 'weight_loss',
                                    ),
                                  ),
                                  SelectableSufraChip(
                                    label: l10n.interestFitness,
                                    selected: _interest == 'fitness',
                                    onTap: () =>
                                        setState(() => _interest = 'fitness'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OwnerPolicyConsent(
                        config: widget.policy,
                        onChanged: (accepted) => setState(
                          () =>
                              _policyAcceptance.update(widget.policy, accepted),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: MediaQuery.textScalerOf(context).scale(16) > 22
                            ? GradientButton(
                                label: l10n.createAccountButton,
                                height: 112,
                                isLoading: _submitting,
                                onPressed: _acceptedTerms ? _submit : null,
                              )
                            : IconPillButton(
                                label: l10n.createAccountButton,
                                isLoading: _submitting,
                                onPressed: _acceptedTerms ? _submit : null,
                              ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.orContinueWith,
                        style: context.mutedStyle(size: 12),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          GlassPillButton(
                            label: l10n.googleProvider,
                            leading: const GoogleProviderBadge(),
                            onPressed: () => context.go('/login?google=1'),
                          ),
                          GlassPillButton(
                            label: l10n.phoneProvider,
                            leading: const Icon(Icons.phone_outlined),
                            onPressed: () => _showError(
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? 'الدخول برسائل الموبايل مش متاح على Spark. استخدم الإيميل أو جوجل من غير دفع.'
                                  : 'SMS sign-in is not available on Spark. Use email or Google without enabling billing.',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 8,
                        children: [
                          Text(l10n.haveAccount, style: context.mutedStyle()),
                          SufraControlFeedback(
                            radius: 8,
                            overlay: true,
                            child: GestureDetector(
                              onTap: () => context.go(LoginScreen.routePath),
                              child: Text(
                                l10n.signInLink,
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

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength});

  final int strength;

  static const _colors = [
    Colors.transparent,
    AppColors.error,
    AppColors.copper,
    AppColors.success,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      '',
      l10n.passwordStrengthWeak,
      l10n.passwordStrengthMedium,
      l10n.passwordStrengthStrong,
    ];
    return Row(
      children: [
        for (var i = 1; i <= 3; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: i <= strength
                    ? _colors[strength]
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 6),
        ],
        const SizedBox(width: 8),
        Text(
          labels[strength],
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
