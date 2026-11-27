import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/app_localizations.dart';

/// Camera-only mode header. Other modes use their own capture flow and do not
/// reuse the current camera image or trigger image recognition.
class CameraModeHeader extends StatelessWidget {
  const CameraModeHeader({
    super.key,
    required this.onClose,
    required this.onVoice,
    required this.onBarcode,
    required this.onFlash,
    required this.flashEnabled,
    this.topInset = 44,
  });
  final VoidCallback onClose, onVoice, onBarcode;
  final VoidCallback? onFlash;
  final bool flashEnabled;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final large =
        MediaQuery.textScalerOf(context).scale(13) > 18 ||
        (Localizations.localeOf(context).languageCode != 'ar' &&
            MediaQuery.sizeOf(context).width < 480);
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget circle(IconData icon, String tooltip, VoidCallback? tap) =>
        IconButton(
          onPressed: tap,
          tooltip: tooltip,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          style: IconButton.styleFrom(
            backgroundColor: dark
                ? Colors.white.withValues(alpha: .10)
                : Colors.white.withValues(alpha: .85),
            side: BorderSide(
              color: dark
                  ? Colors.white.withValues(alpha: .22)
                  : AppColors.lightTextMuted.withValues(alpha: .3),
            ),
          ),
          icon: Icon(icon, size: 22),
        );
    final modes = GlassCard(
      borderRadius: 99,
      padding: const EdgeInsets.all(4),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _mode(l.logHubChipVoice, onVoice),
          Semantics(
            selected: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.all(Radius.circular(99)),
              ),
              child: Text(
                l.logHubChipPhoto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _mode(l.logHubChipBarcode, onBarcode),
        ],
      ),
    );
    final close = circle(Icons.close, l.cameraClose, onClose);
    final flash = circle(
      flashEnabled ? Icons.flash_on : Icons.flash_off,
      l.cameraFlash,
      onFlash,
    );
    return Semantics(
      label: l.cameraTitle,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topInset, 16, 20),
        child: large
            ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [close, flash],
                  ),
                  const SizedBox(height: 10),
                  modes,
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [close, modes, flash],
              ),
      ),
    );
  }

  Widget _mode(String label, VoidCallback onPressed) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      minimumSize: const Size(0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      textStyle: const TextStyle(fontSize: 13, fontFamily: AppTheme.fontFamily),
    ),
    child: Text(label),
  );
}
