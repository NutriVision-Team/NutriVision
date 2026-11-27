import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/sufra_licenses_screen.dart';

void main() {
  testWidgets(
    'bundled legal credits survive a new screen without scan history',
    (t) async {
      for (var launch = 0; launch < 2; launch++) {
        await t.pumpWidget(const MaterialApp(home: SufraLicensesScreen()));
        await t.pumpAndSettle();
        expect(
          find.textContaining('Open Food Facts contributors'),
          findsOneWidget,
        );
        expect(find.textContaining('ODbL'), findsOneWidget);
        final credits =
            jsonDecode(
                  await rootBundle.loadString('assets/data/image_credits.json'),
                )
                as List;
        if (credits.isNotEmpty) {
          final author = (credits.first as Map)['author'] as String;
          for (
            var i = 0;
            find.textContaining(author).evaluate().isEmpty && i < 30;
            i++
          ) {
            await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
            await t.pump(const Duration(milliseconds: 200));
          }
          expect(find.textContaining(author), findsWidgets);
        }
        await t.pumpWidget(const SizedBox());
      }
    },
  );
}
