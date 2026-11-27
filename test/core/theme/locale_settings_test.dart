import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/config/app_preferences.dart';
import 'package:sufradepi/core/theme/theme_cubit.dart';
import 'package:sufradepi/core/widgets/language_settings.dart';
import 'package:sufradepi/l10n/app_localizations.dart';

void main() {
  test(
    'locale selection survives reload both ways, unsupported values ignored',
    () async {
      SharedPreferences.setMockInitialValues({'locale': 'fr'});
      final c = LocaleCubit(await AppPreferences.load());
      expect(c.state, const Locale('ar'));
      await c.setLocale(const Locale('en'));
      expect(
        LocaleCubit(await AppPreferences.load()).state,
        const Locale('en'),
      );
      await c.setLocale(const Locale('fr'));
      expect(c.state, const Locale('en'));
      await c.toggle();
      expect(
        LocaleCubit(await AppPreferences.load()).state,
        const Locale('ar'),
      );
      await c.close();
    },
  );
  testWidgets(
    'language settings presents native language names, switches direction and persists',
    (t) async {
      SharedPreferences.setMockInitialValues({});
      final c = LocaleCubit(await AppPreferences.load());
      await t.pumpWidget(
        BlocProvider.value(
          value: c,
          child: BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) => MaterialApp(
              locale: locale,
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showLanguageSettings(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.text('العربية'), findsOneWidget);
      await t.tap(find.text('English'));
      await t.pumpAndSettle();
      expect(c.state, const Locale('en'));
      expect(
        Directionality.of(t.element(find.text('open'))),
        TextDirection.ltr,
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.tap(find.text('العربية'));
      await t.pumpAndSettle();
      expect(
        Directionality.of(t.element(find.text('open'))),
        TextDirection.rtl,
      );
      expect((await AppPreferences.load()).localeCode, 'ar');
      await t.pumpWidget(const SizedBox());
      await c.close();
    },
  );
}
