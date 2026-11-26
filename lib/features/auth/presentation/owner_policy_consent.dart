import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';

/// Populated only after owner approval. Empty defaults keep registration closed.
class OwnerPolicyConfig {
  const OwnerPolicyConfig({
    this.termsUrl = '',
    this.termsVersion = '',
    this.privacyUrl = '',
    this.privacyVersion = '',
    this.termsText = '',
    this.privacyText = '',
  });
  static const absent = OwnerPolicyConfig();
  final String termsUrl, termsVersion, privacyUrl, privacyVersion;
  final String termsText, privacyText;
  bool get isLocal =>
      termsUrl.isEmpty &&
      privacyUrl.isEmpty &&
      termsText.trim().isNotEmpty &&
      privacyText.trim().isNotEmpty;
  static Uri? safeUri(String raw) {
    final u = Uri.tryParse(raw);
    return u != null &&
            u.scheme == 'https' &&
            u.host.contains('.') &&
            !RegExp(r'^[0-9.]+$').hasMatch(u.host) &&
            u.query.isEmpty &&
            u.userInfo.isEmpty &&
            !u.host.endsWith('.invalid') &&
            u.fragment.isEmpty
        ? u
        : null;
  }

  bool get ready =>
      (isLocal ||
          (termsText.isEmpty &&
              privacyText.isEmpty &&
              safeUri(termsUrl) != null &&
              safeUri(privacyUrl) != null)) &&
      termsVersion.trim().isNotEmpty &&
      privacyVersion.trim().isNotEmpty;
  String get binding => [
    termsUrl,
    termsVersion,
    privacyUrl,
    privacyVersion,
    termsText,
    privacyText,
  ].join('\u0000');
}

class PolicyAcceptance {
  String? _binding;
  bool accepts(OwnerPolicyConfig c) => c.ready && _binding == c.binding;
  void update(OwnerPolicyConfig c, bool accepted) {
    _binding = accepted && c.ready ? c.binding : null;
  }

  void invalidate() => _binding = null;
}

typedef PolicyLinkOpener = Future<bool> Function(Uri uri);
Future<bool> openPolicyExternally(Uri uri) async {
  if (OwnerPolicyConfig.safeUri(uri.toString()) == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

class OwnerPolicyConsent extends StatefulWidget {
  const OwnerPolicyConsent({
    super.key,
    required this.config,
    required this.onChanged,
    this.opener = openPolicyExternally,
  });
  final OwnerPolicyConfig config;
  final ValueChanged<bool> onChanged;
  final PolicyLinkOpener opener;
  @override
  State<OwnerPolicyConsent> createState() => _OwnerPolicyConsentState();
}

class _OwnerPolicyConsentState extends State<OwnerPolicyConsent> {
  final _acceptance = PolicyAcceptance();
  @override
  void didUpdateWidget(covariant OwnerPolicyConsent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.binding != widget.config.binding) {
      _acceptance.invalidate();
    }
  }

  Future<void> _showDocument(String title, String text) async {
    await showSufraDialog<void>(
      context: context,
      builder: (context) => SufraAlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(child: SelectableText(text)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String raw) async {
    final uri = OwnerPolicyConfig.safeUri(raw);
    var ok = false;
    try {
      if (uri != null) ok = await widget.opener(uri);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SufraSnackBar(content: Text(AppLocalizations.of(context).stateError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = widget.config;
    if (!c.ready) {
      return Row(
        children: [
          const Checkbox(value: false, onChanged: null),
          Expanded(child: Text(l.registrationPolicyUnavailable)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          children: [
            TextButton(
              onPressed: () => c.isLocal
                  ? _showDocument(
                      '${l.ownerTerms} (${c.termsVersion})',
                      c.termsText,
                    )
                  : _open(c.termsUrl),
              child: Text(l.ownerTerms),
            ),
            TextButton(
              onPressed: () => c.isLocal
                  ? _showDocument(
                      '${l.ownerPrivacy} (${c.privacyVersion})',
                      c.privacyText,
                    )
                  : _open(c.privacyUrl),
              child: Text(l.ownerPrivacy),
            ),
          ],
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _acceptance.accepts(c),
          onChanged: (v) {
            setState(() => _acceptance.update(c, v ?? false));
            widget.onChanged(_acceptance.accepts(c));
          },
          title: Text('${l.agreeTermsPrefix}${l.agreeTermsLink}'),
        ),
      ],
    );
  }
}
