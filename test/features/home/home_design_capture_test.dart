import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/features/home/presentation/screens/home_screen.dart';
import '../../goldens/milestone1_screens_test.dart' show Harness, loadRealFonts;

void main() {
  setUpAll(() async {
    await loadRealFonts();
    final path = Platform.environment['SUFRA_RECIPE_IMAGE_MANIFEST'];
    if (path != null) {
      final files = (jsonDecode(File(path).readAsStringSync()) as Map)
          .cast<String, String>();
      HttpOverrides.global = SourceImageOverrides(files);
    }
  });
  tearDownAll(() => HttpOverrides.global = null);
  testWidgets('Home design checkpoint actual catalog and scroll', (t) async {
    t.view.physicalSize = const Size(780, 1688);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final h = await Harness.signedIn();
    final key = GlobalKey();
    final light = Platform.environment['SUFRA_LIGHT_CAPTURE'] == '1';
    await t.runAsync(() async {
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: h.wrap(
            HomeScreen(clock: () => DateTime(2026, 11, 22, 18)),
            themeMode: light ? ThemeMode.light : ThemeMode.dark,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
    });
    await t.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/sufra_logo.webp'),
        t.element(find.byType(HomeScreen)),
      );
      await precacheImage(
        const AssetImage('assets/images/art/spA.webp'),
        t.element(find.byType(HomeScreen)),
      );
      await precacheImage(
        const AssetImage('assets/images/art/neb.jpg'),
        t.element(find.byType(HomeScreen)),
      );
    });
    final manifest = Platform.environment['SUFRA_RECIPE_IMAGE_MANIFEST'];
    if (manifest != null) {
      final urls = (jsonDecode(File(manifest).readAsStringSync()) as Map).keys
          .cast<String>();
      await t.runAsync(() async {
        for (final url in urls) {
          await precacheImage(
            NetworkImage(url),
            t.element(find.byType(HomeScreen)),
          );
        }
      });
    }
    await t.pump(const Duration(seconds: 2));
    final motionDirectory = Platform.environment['SUFRA_MOTION_CAPTURE'];
    if (motionDirectory != null) {
      for (var frame = 0; frame < 24; frame++) {
        if (frame == 8) {
          await t.drag(
            find.byKey(const ValueKey('interactive-vector-bowl')),
            const Offset(24, -18),
          );
        }
        await t.pump(const Duration(milliseconds: 166));
        await t.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '$motionDirectory/frame_${frame.toString().padLeft(3, '0')}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    final directory = Platform.environment['SUFRA_DESIGN_CAPTURE'];
    if (directory != null) {
      for (var i = 0; i < 3; i++) {
        await t.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$directory/home_${light ? 'light_' : ''}$i.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
        await t.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await t.drag(find.byType(ListView).first, const Offset(0, -520));
        await t.pump(const Duration(seconds: 1));
      }
    }
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
    await h.dispose();
  });
}

// Optional owner-local visual evidence from previously fetched provider images.
// No image bytes are bundled, and normal tests do not make HTTP requests.
class SourceImageOverrides extends HttpOverrides {
  SourceImageOverrides(this.files);
  final Map<String, String> files;
  @override
  HttpClient createHttpClient(SecurityContext? context) => _Client(files);
}

class _Client extends Fake implements HttpClient {
  _Client(this.files);
  final Map<String, String> files;
  @override
  set autoUncompress(bool value) {}
  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _Request(files[url.toString()]);
  @override
  void close({bool force = false}) {}
}

class _Headers extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _Request extends Fake implements HttpClientRequest {
  _Request(this.path);
  final String? path;
  @override
  HttpHeaders get headers => _Headers();
  @override
  Future<HttpClientResponse> close() async => _Response(path);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.path);
  final String? path;
  @override
  int get statusCode => path == null ? 404 : 200;
  @override
  int get contentLength => path == null ? 0 : File(path!).lengthSync();
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      (path == null ? const Stream<List<int>>.empty() : File(path!).openRead())
          .listen(
            onData,
            onError: onError,
            onDone: onDone,
            cancelOnError: cancelOnError,
          );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
