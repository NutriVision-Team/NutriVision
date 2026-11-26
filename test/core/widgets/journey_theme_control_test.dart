import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/config/app_preferences.dart';
import 'package:sufradepi/core/theme/theme_cubit.dart';
import 'package:sufradepi/core/widgets/journey_theme_control.dart';
import 'package:sufradepi/core/widgets/theme_switcher.dart';

void main() {
  testWidgets(
    'journey theme control toggles persisted theme without moving content',
    (t) async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final prefs = await AppPreferences.load();
      final cubit = ThemeCubit(prefs);
      await t.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: JourneyThemeControl(
                child: Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      key: const ValueKey('anchor'),
                      width: 10,
                      height: 10,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final before = t.getTopLeft(find.byKey(const ValueKey('anchor')));
      expect(find.byType(LiquidThemeButton), findsOneWidget);
      await t.tap(find.byType(LiquidThemeButton));
      await t.pumpAndSettle();
      expect(cubit.isDark, isFalse);
      expect(t.getTopLeft(find.byKey(const ValueKey('anchor'))), before);
      expect(t.getSize(find.byType(LiquidThemeButton)), const Size(44, 44));
      await t.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    },
  );
  testWidgets('standalone preview without theme owner remains usable', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: JourneyThemeControl(child: Scaffold(body: Text('page'))),
      ),
    );
    expect(find.text('page'), findsOneWidget);
    expect(find.byType(LiquidThemeButton), findsNothing);
    expect(t.takeException(), isNull);
  });
}
