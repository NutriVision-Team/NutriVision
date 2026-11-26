import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/data/models/weight_log_model.dart';
import 'package:sufradepi/features/progress/presentation/screens/weight_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;
import 'progress_test.dart' as f;
import 'weight_goal_test.dart' as goal;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sufradepi/core/widgets/app_buttons.dart';
import 'package:sufradepi/features/progress/presentation/cubit/weight_cubit.dart';

void main() {
  setUpAll(loadRealFonts);
  for (final count in [1, 2]) {
    for (final lang in ['ar', 'en']) {
      for (final dark in [false, true]) {
        for (final scale in [1.0, 1.6]) {
          testWidgets('weight history$count visual $lang dark$dark scale$scale', (
            t,
          ) async {
            t.view.physicalSize = const Size(390, 844);
            t.view.devicePixelRatio = 1;
            t.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(t.view.reset);
            addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
            final key = GlobalKey();
            await f.pumpScreen(
              t,
              RepaintBoundary(
                key: key,
                child: WeightScreen(
                  waterWeightRepository: f.FakeWaterWeightRepository()
                    ..weight = [
                      if (count == 2)
                        WeightLogModel(
                          weightId: 'baseline',
                          weightKg: 90,
                          recordedAt: DateTime(2026, 10, 1),
                          dateKey: '2026-10-01',
                        ),
                      WeightLogModel(
                        weightId: 'fixture',
                        weightKg: 88,
                        recordedAt: DateTime(2026, 11, 22, 12),
                        dateKey: '2026-11-22',
                      ),
                    ],
                ),
              ),
              f.FakeNutritionRepository()
                ..logs = [f.log('2026-11-22')]
                ..activeProfile = goal.profile(),
              locale: Locale(lang),
              theme: dark ? AppTheme.dark() : AppTheme.light(),
            );
            await t.pump(const Duration(seconds: 2));
            final cubit = t
                .element(find.byType(GradientButton))
                .read<WeightCubit>();
            expect(cubit.state.weekDates.map((d) => d.day).toList(), [
              16,
              17,
              18,
              19,
              20,
              21,
              22,
            ]);
            expect(cubit.state.weekLogged, [
              false,
              false,
              false,
              false,
              false,
              false,
              true,
            ]);
            expect(cubit.state.weekDates.last.weekday, DateTime.sunday);
            expect(
              find.text(count == 1 ? '—' : (lang == 'en' ? '20%' : '٢٠%')),
              findsOneWidget,
            );
            if (count == 1) {
              expect(
                find.textContaining(
                  lang == 'en' ? 'Progress is unavailable' : 'التقدم مش متاح',
                ),
                findsOneWidget,
              );
            } else {
              expect(
                find.textContaining(lang == 'en' ? 'oldest entry' : 'أقدم وزن'),
                findsOneWidget,
              );
              expect(find.textContaining('2026-10-01'), findsOneWidget);
            }
            for (var page = 0; page < 2; page++) {
              expect(t.takeException(), isNull);
              await t.runAsync(() async {
                final im =
                    await (key.currentContext!.findRenderObject()!
                            as RenderRepaintBoundary)
                        .toImage();
                final b = await im.toByteData(format: ui.ImageByteFormat.png);
                final stage =
                    Platform.environment['SUFRA_WEIGHT_STAGE'] ?? 'reviewed';
                await File(
                  '/downloads/sufra-recovered/weight1414_${stage}_h${count}_${lang}_${dark ? 'dark' : 'light'}_${scale}_$page.png',
                ).writeAsBytes(b!.buffer.asUint8List());
                im.dispose();
              });
              await t.drag(
                find.byType(SingleChildScrollView).first,
                const Offset(0, -500),
              );
              await t.pump(const Duration(milliseconds: 300));
            }
            if (count == 1 && lang == 'en' && scale == 1.0) {
              final cta = find.byType(GradientButton);
              await t.ensureVisible(cta);
              await t.pump(const Duration(milliseconds: 300));
              final target = t.getCenter(cta);
              final mouse = await t.createGesture(
                kind: PointerDeviceKind.mouse,
              );
              await mouse.addPointer(location: const Offset(0, 0));
              await mouse.moveTo(target);
              await t.pump(const Duration(milliseconds: 300));
              final finger = await t.startGesture(target);
              for (var frame = 0; frame < 7; frame++) {
                await t.pump(const Duration(milliseconds: 166));
                await t.runAsync(() async {
                  final im =
                      await (key.currentContext!.findRenderObject()!
                              as RenderRepaintBoundary)
                          .toImage();
                  final bytes = await im.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  await File(
                    '/downloads/sufra-recovered/weight1421_press_${dark ? 'dark' : 'light'}_$frame.png',
                  ).writeAsBytes(bytes!.buffer.asUint8List());
                  im.dispose();
                });
              }
              await finger.cancel();
              await mouse.removePointer();
              await t.pump();
              expect(find.byType(TextField), findsNothing);
            }
            await t.pumpWidget(const SizedBox());
          });
        }
      }
    }
  }
}
