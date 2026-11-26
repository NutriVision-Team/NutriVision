import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/nebula_background.dart';
import 'package:sufradepi/features/reminders/data/reminder_scheduler.dart';
import 'package:sufradepi/features/reminders/data/reminder_store.dart';
import 'package:sufradepi/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:sufradepi/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:sufradepi/features/reminders/presentation/screens/reminder_texts.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'reminders_logic_test.dart' show FakeNotifier;

void main() {
  setUpAll(() async {
    await loadRealFonts();
    tzdata.initializeTimeZones();
  });
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('reminders design $lang $dark $scale', (t) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          SharedPreferences.setMockInitialValues({});
          final n = FakeNotifier();
          final l = await AppLocalizations.delegate.load(Locale(lang));
          final c = RemindersCubit(
            uid: 'u1',
            currentUid: () => 'u1',
            store: ReminderStore(await SharedPreferences.getInstance()),
            scheduler: ReminderScheduler(
              notifier: n,
              location: () async => tz.getLocation('Africa/Cairo'),
            ),
            notifier: n,
            texts: () => reminderTextsFor(l),
          );
          await c.load();
          final key = GlobalKey();
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => NebulaBackground(
                  child: BlocProvider.value(
                    value: c,
                    child: const RemindersScreen(),
                  ),
                ),
              ),
              GoRoute(
                path: '/water',
                builder: (_, __) =>
                    const Scaffold(body: Text('water preview route')),
              ),
            ],
          );
          addTearDown(router.dispose);
          await t.pumpWidget(
            RepaintBoundary(
              key: key,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: router,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                locale: Locale(lang),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (c, ch) => MediaQuery(
                  data: MediaQuery.of(c).copyWith(
                    disableAnimations: true,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: ch!,
                ),
              ),
            ),
          );
          await t.pump();
          await t.pump(const Duration(seconds: 1));
          Future<void> shot(String part) async {
            expect(t.takeException(), isNull);
            await t.runAsync(() async {
              final im =
                  await (key.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final b = await im.toByteData(format: ui.ImageByteFormat.png);
              await File(
                '/downloads/sufra-recovered/reminders1817_${lang}_${dark ? 'dark' : 'light'}_${scale}_$part.png',
              ).writeAsBytes(b!.buffer.asUint8List());
              im.dispose();
            });
          }

          await shot('top');
          await t.drag(find.byType(ListView), const Offset(0, -650));
          await t.pump(const Duration(milliseconds: 400));
          await shot('scroll');
          expect(n.prompts, 0);
          expect(n.pending, isEmpty);
          await t.scrollUntilVisible(
            find.text(l.remindersNotifWater),
            -300,
            scrollable: find.byType(Scrollable).first,
          );
          await Scrollable.ensureVisible(
            t.element(find.text(l.remindersNotifWater)),
            alignment: .5,
          );
          await t.pump();
          await t.tap(find.text(l.remindersNotifWater));
          await t.pump();
          await t.pump(const Duration(milliseconds: 400));
          expect(find.text('water preview route'), findsOneWidget);
          expect(n.prompts, 0);
          expect(n.pending, isEmpty);
          await t.pumpWidget(const SizedBox());
          await c.close();
        });
      }
    }
  }
}
