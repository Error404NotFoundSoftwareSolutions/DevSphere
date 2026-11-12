// Capability: CAP-DESIGN-SYSTEM. Tests: TC-DES-020
// Implemented here: the DevPilot logo (assets/images/logo.png). The mark has a dark navy letter, so on a dark theme
// or a dark panel it sits on a white rounded tile to stay readable.

import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 34, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final tile = onDark || BL.dark;
    final image = Image.asset('assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticLabel: 'DevPilot logo',
        filterQuality: FilterQuality.medium);
    if (!tile) return SizedBox(width: size, height: size, child: image);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.26)),
      child: image,
    );
  }
}
