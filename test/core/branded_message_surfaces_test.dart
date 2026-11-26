import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:sufradepi/core/widgets/sufra_snackbar.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import '../goldens/milestone1_screens_test.dart' show loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  for (final config in [
    ('ar', ThemeMode.dark, 1.0),
    ('en', ThemeMode.light, 1.0),
    ('ar', ThemeMode.dark, 2.0),
    ('en', ThemeMode.light, 2.0),
  ]) {
    testWidgets('branded app messages preserve actions $config', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final key = GlobalKey();
      late BuildContext page;
      final ar = config.$1 == 'ar';
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: Locale(config.$1),
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: config.$2,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(
                disableAnimations: true,
                textScaler: TextScaler.linear(config.$3),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (c) {
                  page = c;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      Future<void> capture(String kind) async {
        await t.pump();
        await t.pump(const Duration(milliseconds: 400));
        expect(t.takeException(), isNull);
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await im.toByteData(format: ui.ImageByteFormat.png);
          im.dispose();
          final f = File(
            '/downloads/sufra-recovered/message-pixels/${config.$1}_${config.$3}_$kind.png',
          );
          await f.parent.create(recursive: true);
          await f.writeAsBytes(data!.buffer.asUint8List());
        });
      }

      bool? choice;
      final confirm = ar ? 'حفظ' : 'Save';
      final cancel = ar ? 'إلغاء' : 'Cancel';
      final future = showSufraDialog<bool>(
        context: page,
        builder: (c) => SufraAlertDialog(
          title: Text(ar ? 'حفظ اختياراتك' : 'Save your choices'),
          content: Text(
            ar
                ? 'تقدر تعدّل اختياراتك أو تمسحها في أي وقت.'
                : 'You can edit or remove your choices at any time.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(confirm),
            ),
          ],
        ),
      );
      await capture('dialog');
      await t.tap(find.text(confirm));
      await t.pump(const Duration(milliseconds: 400));
      choice = await future;
      expect(choice, isTrue);
      final sf = showSufraBottomSheet<String>(
        context: page,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (c) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ar ? 'يومك وخطتك' : 'Your day and plan',
                    style: const TextStyle(fontSize: 22),
                  ),
                  ListTile(
                    title: Text(ar ? 'وجباتي النهاردة' : "Today's meals"),
                    onTap: () => Navigator.pop(c, 'diary'),
                  ),
                  ListTile(
                    title: Text(ar ? 'تقرير تقدمي' : 'My progress report'),
                    onTap: () => Navigator.pop(c, 'report'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await capture('sheet');
      await t.tap(find.text(ar ? 'تقرير تقدمي' : 'My progress report'));
      await t.pump(const Duration(milliseconds: 400));
      expect(await sf, 'report');
      var action = false;
      ScaffoldMessenger.of(page).showSnackBar(
        SufraSnackBar(
          content: Text(
            ar
                ? 'اليوم اتغيّر. راجع بيانات النهاردة قبل الحفظ.'
                : 'The day changed. Review today before saving.',
          ),
          actionLabel: ar ? 'مراجعة' : 'Review',
          onAction: () => action = true,
        ),
      );
      await capture('snackbar');
      await t.tap(find.text(ar ? 'مراجعة' : 'Review'));
      await t.pump();
      expect(action, isTrue);
      await t.pumpWidget(const SizedBox());
    });
  }
}
