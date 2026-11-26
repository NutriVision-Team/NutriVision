import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/nebula_background.dart';
import 'package:sufradepi/features/reminders/data/reminder_scheduler.dart';
import 'package:sufradepi/features/reminders/data/reminder_store.dart';
import 'package:sufradepi/features/reminders/domain/reminder_models.dart';
import 'package:sufradepi/features/reminders/domain/reminder_plan.dart';
import 'package:sufradepi/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:sufradepi/features/reminders/presentation/screens/reminder_texts.dart';
import 'package:sufradepi/features/reminders/presentation/screens/reminders_host.dart';
import 'package:sufradepi/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'reminders_logic_test.dart' show FakeNotifier;

Future<void> compareOrCapture(WidgetTester t, String name) async {
  if (const bool.fromEnvironment('CONTROLLED_CAPTURE')) {
    final boundary = t.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('reminder-review')),
    );
    await t.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '/downloads/sufra/verification/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  } else {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  setUpAll(loadRealFonts);

  late FakeNotifier n;
  late ReminderStore store;
  late ReminderScheduler sch;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = ReminderStore(await SharedPreferences.getInstance());
    n = FakeNotifier();
    sch = ReminderScheduler(
      notifier: n,
      location: () async => tz.getLocation('Africa/Cairo'),
      clock: () => DateTime.utc(2026, 11, 22, 7),
    );
  });

  Widget app(Widget child, {Locale locale = const Locale('ar')}) => MediaQuery(
    data: const MediaQueryData(size: Size(390, 844)),
    child: MaterialApp(
      theme: AppTheme.dark(),
      builder: (_, child) => RepaintBoundary(
        key: const ValueKey('reminder-review'),
        child: child!,
      ),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      home: NebulaBackground(child: child),
    ),
  );

  Future<RemindersCubit> cubit({Locale locale = const Locale('ar')}) async {
    final l = await AppLocalizations.delegate.load(locale);
    final c = RemindersCubit(
      uid: 'u1',
      currentUid: () => 'u1',
      store: store,
      scheduler: sch,
      notifier: n,
      texts: () => reminderTextsFor(l),
    );
    await c.load();
    return c;
  }

  Future<void> show(WidgetTester t, Widget w) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    t.view.devicePixelRatio = 1;
    await t.runAsync(() async {
      await t.pumpWidget(w);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await t.pump(const Duration(milliseconds: 500));
  }

  Widget screen(RemindersCubit c, {Locale locale = const Locale('ar')}) => app(
    BlocProvider.value(value: c, child: const RemindersScreen()),
    locale: locale,
  );

  testWidgets('all off by default; golden', (t) async {
    final c = (await t.runAsync(cubit))!;
    await show(t, screen(c));
    expect(n.pending, isEmpty);
    expect(n.prompts, 0);
    await compareOrCapture(t, 'reminders_off');
    await t.pumpWidget(const SizedBox.shrink());
    await c.close();
  });

  testWidgets('switch on water: time picker, then scheduled; off cancels', (
    t,
  ) async {
    n.enabled = false;
    final c = (await t.runAsync(cubit))!;
    await show(t, screen(c));
    await t.tap(find.byType(Switch).first);
    await t.pump(const Duration(milliseconds: 600));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await t.tap(
      find
          .descendant(
            of: find.byType(TimePickerDialog),
            matching: find.byType(TextButton),
          )
          .last,
    );
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump(const Duration(milliseconds: 600));
    expect(
      n.prompts,
      1,
      reason: 'asked in context, after the user chose a time',
    );
    expect(n.pending.keys, [ReminderIds.water(0)]);
    expect(n.pending.values.single.$1.minute, 600);
    await t.tap(find.byType(Switch).first);
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump(const Duration(milliseconds: 600));
    expect(n.pending, isEmpty);
    await t.pumpWidget(const SizedBox.shrink());
    await c.close();
  });

  testWidgets('permission denied shows banner and keeps everything off', (
    t,
  ) async {
    n
      ..enabled = false
      ..grant = false;
    final c = (await t.runAsync(cubit))!;
    await show(t, screen(c));
    await t.tap(find.byType(Switch).at(1)); // breakfast
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(
      find
          .descendant(
            of: find.byType(TimePickerDialog),
            matching: find.byType(TextButton),
          )
          .last,
    );
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump(const Duration(milliseconds: 600));
    expect(n.pending, isEmpty);
    expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
    await compareOrCapture(t, 'reminders_denied');
    await t.pumpWidget(const SizedBox.shrink());
    await c.close();
  });

  testWidgets('configured state, Arabic and English goldens', (t) async {
    final c = (await t.runAsync(cubit))!;
    await t.runAsync(() => c.addWaterTime(600));
    await t.runAsync(() => c.addWaterTime(840));
    await t.runAsync(() => c.addWaterTime(1080));
    await t.runAsync(() => c.setMealTime('breakfast', 480));
    await t.runAsync(() => c.setMealTime('dinner', 1200));
    await t.runAsync(() => c.setMealEnabled('dinner', false));
    await t.runAsync(
      () => c.setWeightSchedule(weekday: DateTime.friday, minute: 540),
    );
    await show(t, screen(c));
    await compareOrCapture(t, 'reminders_on_ar');
    await t.pumpWidget(const SizedBox.shrink());
    await show(t, screen(c, locale: const Locale('en')));
    await compareOrCapture(t, 'reminders_on_en');
    await t.pumpWidget(const SizedBox.shrink());
    await c.close();
  });

  testWidgets(
    'host: sign-in schedules, switch cancels old account, sign-out cancels',
    (t) async {
      await t.runAsync(
        () => store.save(
          'a',
          ReminderSettings.empty.withMeal(
            'lunch',
            const MealReminder(enabled: true, minute: 840),
          ),
        ),
      );
      Widget host(String? uid) => app(
        RemindersHost(
          uid: uid,
          authResolved: true,
          store: store,
          scheduler: sch,
          child: const SizedBox(),
        ),
      );
      await show(t, host('a'));
      expect(n.pending.keys, [ReminderIds.meal('lunch')]);
      await t.runAsync(() => t.pumpWidget(host('b')));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      expect(
        n.pending,
        isEmpty,
        reason: 'b has no reminders and a must not fire for b',
      );
      await t.runAsync(() => t.pumpWidget(host('a')));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      expect(n.pending.length, 1);
      await t.runAsync(() => t.pumpWidget(host(null)));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      expect(n.pending, isEmpty);
      // resume repairs a cleared schedule
      await t.runAsync(() => t.pumpWidget(host('a')));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      n.pending.clear();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.runAsync(
        () async =>
            t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      expect(n.pending.length, 1);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  Widget variant(
    RemindersCubit c, {
    required ThemeData theme,
    double scale = 1,
  }) => MediaQuery(
    data: MediaQueryData(
      size: const Size(390, 844),
      textScaler: TextScaler.linear(scale),
    ),
    child: MaterialApp(
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(
          key: const ValueKey('reminder-review'),
          child: child!,
        ),
      ),
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      home: NebulaBackground(
        child: BlocProvider.value(value: c, child: const RemindersScreen()),
      ),
    ),
  );

  for (final v in [('light', false, 1.0), ('large_text', true, 2.0)]) {
    testWidgets('variant ${v.$1}', (t) async {
      final c = (await t.runAsync(cubit))!;
      await t.runAsync(() => c.addWaterTime(600));
      await t.runAsync(() => c.addWaterTime(840));
      await t.runAsync(() => c.setMealTime('breakfast', 480));
      await t.runAsync(
        () => c.setWeightSchedule(weekday: DateTime.friday, minute: 540),
      );
      await show(
        t,
        variant(
          c,
          theme: v.$2 ? AppTheme.dark() : AppTheme.light(),
          scale: v.$3,
        ),
      );
      expect(t.takeException(), isNull);
      await compareOrCapture(t, 'reminders_${v.$1}');
      if (v.$1 == 'large_text') {
        final position = t
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        position.jumpTo(position.maxScrollExtent);
        await t.pump(const Duration(milliseconds: 500));
        expect(t.takeException(), isNull);
        expect(
          t.getRect(find.byType(Switch).last).bottom,
          lessThanOrEqualTo(844),
        );
        if (const bool.fromEnvironment('CONTROLLED_CAPTURE')) {
          await compareOrCapture(t, 'reminders_large_text_bottom');
        }
      }

      await t.pumpWidget(const SizedBox.shrink());
      await c.close();
    });
  }
}
