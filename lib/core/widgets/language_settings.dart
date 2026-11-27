import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/theme_cubit.dart';
import '../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

Future<void> showLanguageSettings(BuildContext context) async {
  final cubit = context.read<LocaleCubit>();
  final chosen = await showSufraDialog<String>(
    context: context,
    builder: (context) => SufraSimpleDialog(
      title: Text(
        AppLocalizations.of(context).appLanguage,
        style: context.readableDisplayStyle(size: 21),
      ),
      children: [
        for (final item in const [('ar', 'العربية'), ('en', 'English')])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, item.$1),
            child: Row(
              children: [
                Icon(
                  cubit.state.languageCode == item.$1
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.$2,
                    textDirection: item.$1 == 'ar'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
  if (chosen != null && !cubit.isClosed) await cubit.setLocale(Locale(chosen));
}
