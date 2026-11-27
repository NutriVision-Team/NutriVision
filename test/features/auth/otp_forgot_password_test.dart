import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:sufradepi/features/auth/presentation/widgets/otp_code_field.dart';
import 'package:sufradepi/l10n/app_localizations.dart';
import 'package:sufradepi/services/reset_code_service.dart';

import '../../goldens/milestone1_screens_test.dart' show loadRealFonts;

Widget _app(Widget child, {String lang = 'en', bool dark = true}) =>
    MaterialApp(
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: child,
    );

void main() {
  setUpAll(loadRealFonts);

  group('OtpCodeField', () {
    testWidgets('typing advances, backspace goes back, paste fills all', (
      t,
    ) async {
      final c = TextEditingController();
      await t.pumpWidget(
        _app(
          Scaffold(
            body: Center(child: OtpCodeField(controller: c)),
          ),
        ),
      );
      await t.enterText(find.byKey(const ValueKey('otp-box-0')), '1');
      await t.pump();
      await t.enterText(find.byKey(const ValueKey('otp-box-1')), '2');
      await t.pump();
      expect(c.text, '12');
      // Focus moved to box 2 on its own.
      final focused = FocusManager.instance.primaryFocus;
      expect(focused, isNotNull);
      await t.sendKeyEvent(LogicalKeyboardKey.backspace);
      await t.pump();
      expect(c.text, '1');
      // Paste of the full code into the first box fills every box.
      await t.enterText(find.byKey(const ValueKey('otp-box-0')), '987654');
      await t.pump();
      expect(c.text, '987654');
      for (var i = 0; i < 6; i++) {
        expect(
          (t.widget<TextField>(
            find.byKey(ValueKey('otp-box-$i')),
          )).controller!.text,
          '987654'[i],
        );
      }
      // Non digits are dropped, Arabic-Indic digits convert.
      await t.enterText(find.byKey(const ValueKey('otp-box-0')), '١٢٣ab456');
      await t.pump();
      expect(c.text, '123456');
      // Clearing the controller clears the boxes.
      c.clear();
      await t.pump();
      expect(
        (t.widget<TextField>(
          find.byKey(const ValueKey('otp-box-3')),
        )).controller!.text,
        '',
      );
    });
  });

  for (final entry in [('ar', true), ('en', false)]) {
    testWidgets(
      'forgot password uses OTP boxes and sends pasted code ${entry.$1}',
      (t) async {
        t.view.physicalSize = const Size(390, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final posts = <String, Map<String, dynamic>>{};
        final client = MockClient((r) async {
          posts[r.url.path] = jsonDecode(r.body) as Map<String, dynamic>;
          return http.Response(
            r.url.path == '/request' ? '{"expiresIn":300}' : '{}',
            200,
          );
        });
        final key = GlobalKey();
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: _app(
              ForgotPasswordScreen(
                initialEmail: 'a@b.com',
                service: ResetCodeService(
                  client: client,
                  baseUrl: 'https://x.test',
                ),
              ),
              lang: entry.$1,
              dark: entry.$2,
            ),
          ),
        );
        await t.tap(find.text(entry.$2 ? 'ابعت الكود' : 'Send code'));
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(find.byType(OtpCodeField), findsOneWidget);
        expect(find.byKey(const ValueKey('otp-box-5')), findsOneWidget);
        await t.enterText(find.byKey(const ValueKey('otp-box-0')), '482916');
        await t.pump();
        final fields = find.byType(TextFormField);
        await t.enterText(fields.at(1), 'Passw0rd!x');
        await t.enterText(fields.at(2), 'Passw0rd!x');
        await t.pump();
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final b = await im.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/otp').createSync(recursive: true);
          await File(
            'build/otp/forgot_${entry.$1}.png',
          ).writeAsBytes(b!.buffer.asUint8List());
          im.dispose();
        });
        await t.tap(
          find.text(entry.$2 ? 'غيّر كلمة المرور' : 'Change password'),
        );
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(posts['/confirm']?['code'], '482916');
        expect(posts['/confirm']?['email'], 'a@b.com');
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }

  test('reset service refuses a non-https endpoint', () {
    expect(
      () => ResetCodeService(baseUrl: 'http://insecure.test'),
      throwsArgumentError,
    );
  });
}
