import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/water_glass.dart';
import 'package:sufradepi/core/widgets/sufra_dialog.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/features/diary/presentation/screens/diary_screen.dart';
import '../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(loadRealFonts);
  testWidgets('water reflection frames and dynamic reduced motion', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = await Harness.signedIn();
    final key = GlobalKey();
    final reduced = ValueNotifier(false);
    addTearDown(reduced.dispose);
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ValueListenableBuilder(
          valueListenable: reduced,
          builder: (c, v, _) => MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 844),
              disableAnimations: v,
            ),
            child: h.wrap(DiaryScreen(initialDate: DateTime(2026, 11, 22))),
          ),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 2));
    final context = t.element(find.byType(DiaryScreen)),
        l = AppLocalizations.of(t.element(find.byType(DiaryScreen)));
    showSufraDialog<void>(
      context: context,
      builder: (c) => ValueListenableBuilder(
        valueListenable: reduced,
        builder: (c, v, _) => MediaQuery(
          data: MediaQuery.of(c).copyWith(disableAnimations: v),
          child: SufraAlertDialog(
            title: Text(l.mealDelete),
            content: Text(l.mealDeleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(l.actionCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(l.mealDelete),
              ),
            ],
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 350));
    Future<List<int>> frame(String name) async {
      return (await t.runAsync(() async {
        final im =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final data = await im.toByteData(format: ui.ImageByteFormat.png);
        im.dispose();
        final bytes = data!.buffer.asUint8List();
        File('/downloads/sufra/water_motion/$name.png').writeAsBytesSync(bytes);
        return bytes;
      }))!;
    }

    for (var i = 0; i < 15; i++) {
      await frame('frame_${i.toString().padLeft(2, '0')}');
      await t.pump(const Duration(milliseconds: 450));
    }
    Navigator.of(t.element(find.byType(WaterGlass))).pop();
    await t.pump(const Duration(seconds: 1));
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          home: ValueListenableBuilder(
            valueListenable: reduced,
            builder: (c, v, _) => MediaQuery(
              data: MediaQueryData(disableAnimations: v),
              child: const Center(
                child: WaterGlass(child: SizedBox(width: 280, height: 200)),
              ),
            ),
          ),
        ),
      ),
    );
    reduced.value = true;
    await t.pump();
    await t.pump();
    final stopped = await frame('reduced_0');
    await t.pump(const Duration(seconds: 2));
    final later = await frame('reduced_1');
    expect(later, stopped);
    await t.pumpWidget(const SizedBox());
    await h.dispose();
  });
}
