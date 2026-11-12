// Capability: CAP-DESIGN-SYSTEM. Implemented here: the backdrop of the signed-out screens (landing, sign-in). The name is
// kept so the screens that use it did not change. It is the app canvas with a very faint dot grid, in light or dark.

import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class NeonGlowBackground extends StatelessWidget {
  final Widget? child;

  const NeonGlowBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    // A Material layer is needed by the buttons and fields placed on top (ink effects).
    return Material(
      color: BL.background,
      child: CustomPaint(
          painter: _DotGridPainter(
              BL.textPrimary.withValues(alpha: BL.dark ? 0.07 : 0.07)),
          child: child ?? const SizedBox.expand()),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 28.0;
    for (var y = step; y < size.height; y += step) {
      for (var x = step; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}
