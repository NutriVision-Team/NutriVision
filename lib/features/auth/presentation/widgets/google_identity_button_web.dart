import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../services/google_auth_gateway.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Future<void>? _initialization;
Future<SufraGoogleIdentity?> chooseSufraGoogleIdentity(
  BuildContext context,
) async {
  final google = GoogleSignIn.instance;
  await (_initialization ??= google.initialize(
    clientId:
        '489693655346-m586mm1m0pkbc7psaurip7n295l0kgpc.apps.googleusercontent.com',
  ));
  if (!context.mounted) return null;
  return showSufraDialog<SufraGoogleIdentity>(
    context: context,
    builder: (_) => const _IdentityDialog(),
  );
}

class _IdentityDialog extends StatefulWidget {
  const _IdentityDialog();
  @override
  State<_IdentityDialog> createState() => _IdentityDialogState();
}

class _IdentityDialogState extends State<_IdentityDialog> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  String? _error;
  @override
  void initState() {
    super.initState();
    _subscription = GoogleSignIn.instance.authenticationEvents.listen(
      (event) {
        if (mounted && event is GoogleSignInAuthenticationEventSignIn) {
          Navigator.pop(
            context,
            SufraGoogleIdentity(
              email: event.user.email,
              idToken: event.user.authentication.idToken,
            ),
          );
        }
      },
      onError: (_) {
        if (mounted) {
          setState(
            () => _error = Localizations.localeOf(context).languageCode == 'ar'
                ? 'الدخول بجوجل ماكملش. جرّب تاني أو الغي.'
                : 'Google sign-in could not finish. Try again or cancel.',
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SufraAlertDialog(
    title: const Text('Google'),
    content: SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          web.renderButton(
            configuration: web.GSIButtonConfiguration(
              shape: web.GSIButtonShape.pill,
              size: web.GSIButtonSize.large,
              locale: Localizations.localeOf(context).languageCode,
              minimumWidth: 260,
            ),
          ),
          if (_error != null) Text(_error!),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
    ],
  );
}
