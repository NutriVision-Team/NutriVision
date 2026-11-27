import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/theme/app_theme.dart';
import 'package:sufradepi/core/widgets/app_buttons.dart';
import 'package:sufradepi/core/widgets/sufra_button_response.dart';

/// Hover (orange) and press (blue) must visibly change every control kind.
void main() {
  final key = GlobalKey();
  setUpAll(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  Future<List<int>> shot(WidgetTester t) async {
    late List<int> bytes;
    await t.runAsync(() async {
      final im =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      bytes = (await im.toByteData())!.buffer.asUint8List();
      im.dispose();
    });
    return bytes;
  }

  int diff(List<int> a, List<int> b) {
    var n = 0;
    for (var i = 0; i < a.length; i += 4) {
      if (a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2]) n++;
    }
    return n;
  }

  // Controls that draw the shared blue press response themselves. Material
  // chips, icon buttons and list tiles get the themed hover and splash only.
  const customPress = {
    'selectable chip',
    'elevated',
    'outlined',
    'text button',
  };
  final cases = <String, Widget Function()>{
    'selectable chip': () =>
        SelectableSufraChip(label: 'Chip', selected: false, onTap: () {}),
    'choice chip': () => ChoiceChip(
      label: const Text('Choice'),
      selected: false,
      onSelected: (_) {},
    ),
    'filter chip': () => FilterChip(
      label: const Text('Filter'),
      selected: false,
      onSelected: (_) {},
    ),
    'action chip': () =>
        ActionChip(label: const Text('Action'), onPressed: () {}),
    'shadowed overlay button': () => SufraControlFeedback(
      radius: 18,
      overlay: true,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Colors.indigo, Colors.cyan],
            ),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
          ),
        ),
      ),
    ),
    'elevated': () => ElevatedButton(onPressed: () {}, child: const Text('Go')),
    'outlined': () => OutlinedButton(onPressed: () {}, child: const Text('Go')),
    'text button': () => TextButton(onPressed: () {}, child: const Text('Go')),
    'icon button': () =>
        IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
    'list tile': () => ListTile(onTap: () {}, title: const Text('Tile')),
  };

  for (final c in cases.entries) {
    testWidgets('hover and press change ${c.key}', (t) async {
      t.view.physicalSize = const Size(400, 200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: Center(child: SizedBox(width: 220, child: c.value())),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      final idle = await shot(t);
      final g = await t.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: const Offset(5, 5));
      await g.moveTo(t.getCenter(find.byType(Scaffold).first));
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 300));
      final hover = await shot(t);
      await g.down(t.getCenter(find.byType(Scaffold).first));
      await t.pump(const Duration(milliseconds: 400));
      final press = await shot(t);
      await t.runAsync(() async {
        Directory('build/matrix').createSync(recursive: true);
      });
      // ignore: avoid_print
      print(
        'DIFF ${c.key}: hover=${diff(idle, hover)} press=${diff(idle, press)}',
      );
      expect(diff(idle, hover), greaterThan(40), reason: 'hover shows');
      if (customPress.contains(c.key)) {
        expect(diff(hover, press), greaterThan(20), reason: 'press shows');
      }
      await g.up();
    });
  }
}
