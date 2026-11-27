import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:sufradepi/features/coach/presentation/screens/coach_tools_sheet.dart';
import 'package:sufradepi/features/reminders/data/reminder_scheduler.dart';
import 'package:sufradepi/features/reminders/data/reminder_store.dart';
import 'package:sufradepi/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:sufradepi/features/reminders/presentation/screens/reminder_texts.dart';
import 'package:sufradepi/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:sufradepi/features/voice_logging/presentation/dictation_text_sheet.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../features/voice_logging/voice_flow_test.dart' show FixtureDictation;
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;
import '../reminders/reminders_logic_test.dart' show FakeNotifier;

const _sizes = <String, Size>{
  'tabletP': Size(800, 1280),
  'tabletL': Size(1280, 800),
  'desktop': Size(1440, 900),
};
const _variants = <String, (String, bool)>{
  'ar-dark': ('ar', false),
  'en-light': ('en', true),
};

void main() {
  tzdata.initializeTimeZones();
  setUpAll(loadRealFonts);
  final only = Platform.environment['ONLY'];

  for (final name in [
    'reminders',
    'dialog',
    'sheet',
    'coachtools',
    'dictation',
  ]) {
    if (only != null && !only.split(',').contains(name)) continue;
    testWidgets('overlay $name', (t) async {
      addTearDown(t.view.reset);
      final problems = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) =>
          problems.add('ERR ${d.exceptionAsString().split('\n').first}');
      addTearDown(() => FlutterError.onError = prev);
      for (final s in _sizes.entries) {
        for (final v in _variants.entries) {
          final h = await Harness.signedIn();
          t.view.physicalSize = s.value;
          t.view.devicePixelRatio = 1;
          final key = GlobalKey();
          RemindersCubit? cubit;
          if (name == 'reminders') {
            SharedPreferences.setMockInitialValues({});
            final n = FakeNotifier();
            final l = await AppLocalizations.delegate.load(Locale(v.value.$1));
            cubit = RemindersCubit(
              uid: 'u1',
              currentUid: () => 'u1',
              store: ReminderStore(await SharedPreferences.getInstance()),
              scheduler: ReminderScheduler(
                notifier: n,
                location: () async => tz.getLocation('Africa/Cairo'),
                clock: () => DateTime.utc(2026, 11, 22, 7),
              ),
              notifier: n,
              texts: () => reminderTextsFor(l),
            );
            await cubit.load();
          }
          final home = name == 'reminders'
              ? BlocProvider.value(
                  value: cubit!,
                  child: const RemindersScreen(),
                )
              : const Scaffold(body: Center(child: Text('page')));
          await t.runAsync(() async {
            await t.pumpWidget(
              RepaintBoundary(
                key: key,
                child: h.wrap(
                  home,
                  appShell: true,
                  locale: Locale(v.value.$1),
                  themeMode: v.value.$2 ? ThemeMode.light : ThemeMode.dark,
                ),
              ),
            );
            await Future<void>.delayed(const Duration(milliseconds: 150));
          });
          await t.pump(const Duration(milliseconds: 600));
          final ctx = t.element(find.byType(Scaffold).first);
          switch (name) {
            case 'dialog':
              showSufraDialog<void>(
                context: ctx,
                builder: (c) => SufraAlertDialog(
                  title: const Text('Title'),
                  content: const Text(
                    'Body text for the dialog that wraps over a couple of lines to check the width.',
                  ),
                  actions: [
                    TextButton(onPressed: () {}, child: const Text('OK')),
                  ],
                ),
              );
            case 'sheet':
              showSufraBottomSheet<void>(
                context: ctx,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (c) => const SizedBox(
                  height: 320,
                  child: Center(child: Text('Sheet')),
                ),
              );
            case 'coachtools':
              showCoachTools(ctx, onHabits: () {});
            case 'dictation':
              showSufraBottomSheet<void>(
                context: ctx,
                isScrollControlled: true,
                builder: (c) =>
                    DictationTextSheet(dictation: FixtureDictation()),
              );
          }
          await t.pump(const Duration(milliseconds: 700));
          await t.pump(const Duration(milliseconds: 700));
          await t.runAsync(() async {
            final im =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final b = await im.toByteData(format: ui.ImageByteFormat.png);
            Directory('build/matrix').createSync(recursive: true);
            File(
              'build/matrix/${s.key}__ov_$name${'__'}${v.key}.png',
            ).writeAsBytesSync(b!.buffer.asUint8List());
            im.dispose();
          });
          await t.pumpWidget(const SizedBox());
          await h.dispose();
        }
      }
      File('build/matrix/problems.txt').writeAsStringSync(
        '$name: ${problems.isEmpty ? 'ok' : problems.join(' | ')}\n',
        mode: FileMode.append,
      );
    });
  }
}
