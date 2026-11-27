import 'package:flutter/material.dart';
import 'sufra_logo.dart';
import 'water_glass.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// App-owned message, with the original content and status preserved.
class SufraSnackBar extends SnackBar {
  SufraSnackBar({
    super.key,
    required Widget content,
    String? actionLabel,
    VoidCallback? onAction,
  }) : super(
         backgroundColor: Colors.transparent,
         elevation: 0,
         padding: EdgeInsets.zero,
         behavior: SnackBarBehavior.floating,
         content: Builder(
           builder: (context) => WaterGlass(
             child: Padding(
               padding: const EdgeInsets.all(14),
               child: Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const SufraLogo(size: 32),
                   const SizedBox(width: 10),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Text(
                           Localizations.of<AppLocalizations>(
                                 context,
                                 AppLocalizations,
                               )?.appName ??
                               (Localizations.localeOf(context).languageCode ==
                                       'ar'
                                   ? 'سفرة'
                                   : 'Sufra'),
                           style: TextStyle(
                             fontFamily: AppTheme.fontFamily,
                             fontWeight: FontWeight.w700,
                             color: Theme.of(context).colorScheme.onSurface,
                           ),
                         ),
                         const SizedBox(height: 3),
                         DefaultTextStyle(
                           style: TextStyle(
                             fontFamily: AppTheme.fontFamily,
                             fontSize: 14,
                             color: Theme.of(context).colorScheme.onSurface,
                           ),
                           child: content,
                         ),
                       ],
                     ),
                   ),
                   if (actionLabel != null && onAction != null)
                     TextButton(onPressed: onAction, child: Text(actionLabel))
                   else
                     IconButton(
                       tooltip: MaterialLocalizations.of(
                         context,
                       ).closeButtonTooltip,
                       onPressed: () =>
                           ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                       icon: const Icon(Icons.close, size: 18),
                     ),
                 ],
               ),
             ),
           ),
         ),
       );
}
