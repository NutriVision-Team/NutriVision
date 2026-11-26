import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/config/app_preferences.dart';
import 'package:sufradepi/core/theme/app_accents.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/theme/theme_cubit.dart';
import 'package:sufradepi/core/widgets/app_buttons.dart';

void main() {
  testWidgets(
    'primary and pill buttons animate independent per-mode custom colors',
    (t) async {
      SharedPreferences.setMockInitialValues({});
      final cubit = ThemeCubit(await AppPreferences.load());
      await t.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) => MaterialApp(
              theme: AppTheme.light(
                accent: SufraAccents.resolve(
                  state.lightAccentId,
                  brightness: Brightness.light,
                ).color,
              ),
              darkTheme: AppTheme.dark(
                accent: SufraAccents.resolve(
                  state.darkAccentId,
                  brightness: Brightness.dark,
                ).color,
              ),
              themeMode: state.mode,
              home: Scaffold(
                body: Column(
                  children: [
                    GradientButton(label: 'Primary', onPressed: () {}),
                    IconPillButton(label: 'Pill', onPressed: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      Color gradientColor() {
        final box =
            t
                    .widget<AnimatedContainer>(
                      find
                          .descendant(
                            of: find.byType(GradientButton),
                            matching: find.byType(AnimatedContainer),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration;
        return (box.gradient! as LinearGradient).colors.first;
      }

      await cubit.setAccent(Brightness.dark, 'copper');
      await t.pump();
      await t.pump(const Duration(milliseconds: 350));
      expect(gradientColor(), SufraAccents.copper.color);
      await cubit.setAccent(Brightness.light, 'purple');
      await cubit.setMode(ThemeMode.light);
      await t.pump();
      await t.pump(const Duration(milliseconds: 650));
      expect(gradientColor(), SufraAccents.purple.color);
      await cubit.setMode(ThemeMode.dark);
      await t.pump();
      await t.pump(const Duration(milliseconds: 650));
      expect(gradientColor(), SufraAccents.copper.color);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await cubit.close();
    },
  );
}
