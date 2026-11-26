import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sufradepi/core/widgets/viewport_reveal.dart';

void main() {
  testWidgets('reveal waits for viewport and fires once', (t) async {
    final scroll = ScrollController();
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            cacheExtent: 2000,
            controller: scroll,
            children: [
              const SizedBox(height: 1200),
              ViewportReveal(
                builder: (c, visible) => SizedBox(
                  height: 150,
                  child: Text(visible ? 'revealed' : 'waiting'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await t.pump();
    expect(find.text('waiting', skipOffstage: false), findsOneWidget);
    expect(find.text('revealed', skipOffstage: false), findsNothing);
    scroll.jumpTo(900);
    await t.pump();
    await t.pump();
    expect(find.text('revealed', skipOffstage: false), findsOneWidget);
    scroll.jumpTo(0);
    await t.pump();
    expect(find.text('revealed', skipOffstage: false), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    scroll.dispose();
  });
}
