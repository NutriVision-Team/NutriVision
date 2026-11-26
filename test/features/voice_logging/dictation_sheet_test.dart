import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/voice_logging/presentation/dictation_text_sheet.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'voice_flow_test.dart' show FixtureDictation;

void main() {
  testWidgets(
    'sheet needs explicit tap, protects manual edits, returns only confirmed text and releases lease',
    (tester) async {
      final device = FixtureDictation();
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => DictationTextSheet(
                      initialText: 'base',
                      dictation: device,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(device.starts, 0);
      await tester.tap(find.byKey(const ValueKey('dictation-sheet-mic')));
      await tester.pump();
      device.result('rice');
      await tester.pump();
      expect(find.text('base rice'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'reviewed words');
      device.result('late result');
      await tester.pump();
      expect(find.text('reviewed words'), findsOneWidget);
      expect(result, isNull);
      await tester.tap(find.byKey(const ValueKey('dictation-use-text')));
      await tester.pumpAndSettle();
      expect(result, 'reviewed words');
      expect(device.stops, greaterThanOrEqualTo(1));
      expect(device.releases, 1);
    },
  );
}
