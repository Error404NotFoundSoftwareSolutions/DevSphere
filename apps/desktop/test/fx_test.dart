// Capability: CAP-DESIGN-SYSTEM. Tests: TC-FX-01..05
// Implemented here: the visual effects kit draws without errors, animates nothing in tests (so tests stay fast and
// steady), and the pieces keep their children interactive.
import 'package:desktop/ui/fx.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
    home: Scaffold(
        body: Center(child: SizedBox(width: 500, height: 300, child: child))));

void main() {
  testWidgets('TC-FX-01 effects are off in tests', (tester) async {
    late bool on;
    await tester.pumpWidget(host(Builder(builder: (c) {
      on = fxOn(c);
      return const SizedBox();
    })));
    expect(on, isFalse);
  });

  testWidgets(
      'TC-FX-02 the aurora, the 3D stack, the glow frame and the pulse ring draw and settle',
      (tester) async {
    await tester.pumpWidget(host(const Stack(children: [
      Positioned.fill(child: AuroraBackdrop(child: SizedBox.expand())),
      Positioned(left: 20, top: 20, child: IsoStack(size: 160)),
      Positioned(
          right: 20,
          top: 20,
          child: GlowFrame(child: SizedBox(width: 120, height: 80))),
      Positioned(
          left: 200,
          top: 150,
          child: PulseRing(
              color: Colors.blue, child: SizedBox(width: 44, height: 44))),
    ])));
    await tester
        .pumpAndSettle(); // nothing loops in tests, so this returns at once
    expect(find.byType(AuroraBackdrop), findsOneWidget);
    expect(find.byType(IsoStack), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-FX-03 a tilt card keeps its child tappable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(TiltCard(
        child: GestureDetector(
            onTap: () => taps++,
            child: const SizedBox(
                width: 200, height: 100, child: Text('card'))))));
    await tester.tap(find.text('card'));
    expect(taps, 1);
  });

  testWidgets(
      'TC-FX-04 confetti shows nothing in tests and shimmer placeholders have their size',
      (tester) async {
    await tester.pumpWidget(host(const Column(children: [
      SizedBox(height: 40, child: Confetti()),
      ShimmerBox(width: 120, height: 18),
    ])));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(ShimmerBox)), const Size(120, 18));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'TC-FX-05 with effects forced on, everything animates without errors and stops when removed',
      (tester) async {
    debugFxForceOn = true;
    addTearDown(() => debugFxForceOn = false);
    await tester.pumpWidget(host(const Stack(children: [
      Positioned.fill(child: AuroraBackdrop(child: SizedBox.expand())),
      Positioned(left: 20, top: 20, child: IsoStack(size: 160)),
      Positioned(
          right: 20,
          top: 20,
          child: GlowFrame(child: SizedBox(width: 120, height: 80))),
      Positioned(
          left: 200,
          top: 150,
          child: PulseRing(
              color: Colors.blue, child: SizedBox(width: 44, height: 44))),
      Positioned(
          left: 0,
          top: 0,
          child: SizedBox(width: 300, height: 200, child: Confetti())),
      Positioned(
          left: 300, top: 200, child: ShimmerBox(width: 100, height: 14)),
    ])));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(tester.takeException(), isNull);
    // a tilt card tilts with the pointer and still works
    await tester.pumpWidget(host(TiltCard(
        child: const SizedBox(width: 200, height: 100, child: Text('card')))));
    final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: tester.getCenter(find.text('card')));
    await g.moveTo(tester.getTopLeft(find.text('card')) + const Offset(10, 5));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    await g.removePointer();
    await tester.pumpWidget(
        const SizedBox()); // the animations stop: nothing is left running
    await tester.pumpAndSettle();
  });
}
