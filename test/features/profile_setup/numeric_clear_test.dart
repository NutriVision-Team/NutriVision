import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/app_buttons.dart';
import 'package:sufradepi/features/profile_setup/presentation/cubit/profile_setup_cubit.dart';
import 'package:sufradepi/features/profile_setup/presentation/screens/profile_setup_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../../goldens/milestone1_screens_test.dart'
    show FakeNutritionRepository, FakeUserRepository;

void main() {
  for (final step in [2, 3, 4]) {
    testWidgets(
      'clearing visible numeric setup step$step disables next and clears data',
      (t) async {
        final cubit = ProfileSetupCubit(
          nutritionRepository: FakeNutritionRepository(),
          userRepository: FakeUserRepository(),
        );
        cubit.update(
          ProfileSetupData(
            gender: 'male',
            dateOfBirth: DateTime(2000, 8, 7),
            heightCm: 175,
            currentWeightKg: 90,
            targetWeightKg: 80,
          ),
        );
        for (var i = 0; i < step; i++) {
          cubit.next();
        }
        await t.pumpWidget(
          BlocProvider.value(
            value: cubit,
            child: MaterialApp(
              theme: AppTheme.dark(),
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const ProfileSetupScreen(),
            ),
          ),
        );
        await t.pump();
        expect(
          t.widget<GradientButton>(find.byType(GradientButton)).onPressed,
          isNotNull,
        );
        await t.enterText(find.byType(TextField), '');
        await t.pump();
        expect(cubit.canAdvance, isFalse);
        expect(
          t.widget<GradientButton>(find.byType(GradientButton)).onPressed,
          isNull,
        );
        final data = cubit.state.data;
        expect(switch (step) {
          2 => data.heightCm,
          3 => data.currentWeightKg,
          _ => data.targetWeightKg,
        }, isNull);
        await t.enterText(find.byType(TextField), step == 2 ? '180' : '85');
        await t.pump();
        expect(cubit.canAdvance, isTrue);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
        await cubit.close();
      },
    );
  }
}
