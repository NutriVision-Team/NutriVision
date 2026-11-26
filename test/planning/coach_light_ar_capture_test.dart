import 'package:sufradepi/features/coach/presentation/screens/coach_screen.dart';
import 'screens_smoke_test.dart' show FakeCoachDictation;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/features/coach/data/coach_store.dart';
import 'package:sufradepi/features/coach/presentation/cubit/coach_cubit.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'screens_smoke_test.dart' show SmokeNutritionRepository;

void main() {
  setUpAll(loadRealFonts);
  testWidgets('explicit multi-day history renders with bounded source data', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    var now = DateTime(2026, 11, 23);
    final c = CoachCubit(
      userId: 'qa',
      store: SessionCoachStore(ownerUid: 'qa', currentUid: () => 'qa'),
      nutrition: SmokeNutritionRepository(),
      locale: 'ar',
      clock: () => now,
    );
    c.chooseHabit('log_meal', true);
    c.markHabit('log_meal', true);
    now = DateTime(2026, 11, 24);
    c.chooseHabit('prepare_meal', true);
    c.markHabit('log_meal', true);
    c.markHabit('prepare_meal', true);
    now = DateTime(2026, 11, 25);
    await c.load();
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: CoachScreen(cubit: c, dictation: FakeCoachDictation()),
          ),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 1));
    for (final section in [0, 2, 3]) {
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: CoachScreen(cubit: c, dictation: FakeCoachDictation()),
            ),
          ),
        ),
      );
      await t.tap(find.byType(DropdownButtonFormField<int>));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.byKey(ValueKey('coach_section_$section')).last);
      await t.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 300));
      await t.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/downloads/sufra/coach_light_ar_section_${section}_0752.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await c.close();
  });
}
