import 'package:flutter/material.dart';
import 'water_glass.dart';
import 'sufra_logo.dart';
import '../../l10n/app_localizations.dart';

/// Retains Material's action overflow, keyboard insets, focus and scrolling,
/// replacing only the surface with Sufra's frosted glass.
class SufraAlertDialog extends AlertDialog {
  const SufraAlertDialog({
    super.key,
    super.title,
    super.content,
    super.actions,
    super.insetPadding,
    super.scrollable,
    super.titlePadding,
    super.contentPadding,
    super.actionsPadding,
    super.actionsAlignment,
    super.actionsOverflowAlignment,
    super.actionsOverflowDirection,
    super.actionsOverflowButtonSpacing,
  });
  @override
  Widget build(BuildContext context) =>
      _glassDialog(context, super.build(context) as Dialog);
}

class SufraSimpleDialog extends SimpleDialog {
  const SufraSimpleDialog({
    super.key,
    super.title,
    super.children,
    super.contentPadding,
    super.titlePadding,
  });
  @override
  Widget build(BuildContext context) =>
      _glassDialog(context, super.build(context) as Dialog);
}

Widget _glassDialog(BuildContext context, Dialog base) => Dialog(
  backgroundColor: Colors.transparent,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  insetPadding: base.insetPadding,
  constraints: base.constraints,
  alignment: base.alignment,
  semanticsRole: base.semanticsRole,
  child: WaterGlass(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 0),
          child: Row(
            children: [
              const SufraLogo(size: 34),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).appName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: .85),
                ),
              ),
            ],
          ),
        ),
        Flexible(child: base.child!),
      ],
    ),
  ),
);

/// The same surface for editing sheets, without changing their result types.
Future<T?> showSufraBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool? showDragHandle,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  useSafeArea: useSafeArea,
  showDragHandle: false,
  backgroundColor: Colors.transparent,
  builder: (c) => WaterGlass(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDragHandle == true)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(c).colorScheme.onSurface.withValues(alpha: .3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 12),
          child: Row(
            children: [
              const SufraLogo(size: 30),
              const SizedBox(width: 8),
              Text(
                Localizations.of<AppLocalizations>(
                      c,
                      AppLocalizations,
                    )?.appName ??
                    (Localizations.localeOf(c).languageCode == 'ar'
                        ? 'سفرة'
                        : 'Sufra'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Flexible(child: builder(c)),
      ],
    ),
  ),
);

Future<T?> showSufraDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  builder: builder,
  barrierDismissible: barrierDismissible,
  barrierColor: Colors.black26,
);
