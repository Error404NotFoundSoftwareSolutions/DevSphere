// User story: US-37 Usability and accessibility (Sprint 9, MVP)
// Requirements: NFR-USE-001 (consistent, accessible visual system)
// Test ID: TC-DES-001-01..05
// Implemented here: DevPilot design tokens and theme match docs/DESIGN_SYSTEM.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  tearDown(() => BL.dark = false);

  test('TC-DES-001-01 light tokens match the design system hex values', () {
    BL.dark = false;
    expect(BL.background, const Color(0xFFF5F7FB));
    expect(BL.surface, const Color(0xFFFFFFFF));
    expect(BL.surfaceMuted, const Color(0xFFEEF2F8));
    expect(BL.primary, const Color(0xFF2459E6));
    expect(BL.primaryHover, const Color(0xFF1B47C2));
    expect(BL.navy, const Color(0xFF0E2148));
    expect(BL.border, const Color(0xFFE3E8F1));
    expect(BL.textPrimary, const Color(0xFF0F1B33));
    expect(BL.textSecondary, const Color(0xFF5A6882));
    expect(BL.success, const Color(0xFF0A7D56));
    expect(BL.warning, const Color(0xFF9A5B00));
    expect(BL.danger, const Color(0xFFC02F2F));
  });

  test('TC-DES-001-02 dark tokens match the design system hex values', () {
    BL.dark = true;
    expect(BL.background, const Color(0xFF0A0F1C));
    expect(BL.surface, const Color(0xFF111A2E));
    expect(BL.primary, const Color(0xFF6B93FF));
    expect(BL.textPrimary, const Color(0xFFE8EEFB));
    expect(BL.border, const Color(0xFF1F2C48));
  });

  test('TC-DES-001-03 geometry, spacing and layout tokens', () {
    expect([BL.radiusSm, BL.radiusMd, BL.radiusLg, BL.radiusXl], [6, 10, 14, 20]);
    expect(BL.radiusCard, 16);
    expect([BL.space1, BL.space2, BL.space3, BL.space4, BL.space6, BL.space8, BL.space12], [4, 8, 12, 16, 24, 32, 48]);
    expect(BL.railWidth, 104);
    expect(BL.topbarHeight, 64);
    expect(BL.statusbarHeight, 28);
  });

  test('TC-DES-001-04 the theme follows the mode: brightness, background and primary', () {
    BL.dark = false;
    var t = devPilotTheme();
    expect(t.brightness, Brightness.light);
    expect(t.scaffoldBackgroundColor, BL.background);
    expect(t.colorScheme.primary, BL.primary);
    final lightPrimary = BL.primary;
    BL.dark = true;
    t = devPilotTheme();
    expect(t.brightness, Brightness.dark);
    expect(t.scaffoldBackgroundColor, BL.background);
    expect(BL.primary, isNot(lightPrimary));
  });

  test('TC-DES-001-05 cards have a 16px radius and a hairline; buttons are 42px high with 10px corners, never pills', () {
    BL.dark = false;
    final t = devPilotTheme();
    final card = t.cardTheme.shape as RoundedRectangleBorder;
    expect(card.borderRadius, BorderRadius.circular(16));
    expect(card.side.width, 1);
    expect(card.side.color, BL.border);
    for (final style in [t.elevatedButtonTheme.style!, t.filledButtonTheme.style!]) {
      expect(style.minimumSize!.resolve({}), const Size(0, 42));
      expect((style.shape!.resolve({}) as RoundedRectangleBorder).borderRadius, BorderRadius.circular(10));
    }
  });

  test('TC-DES-001-06 text scale: Inter for text and small labels, JetBrains Mono only for real code', () {
    final t = devPilotTheme();
    expect(t.textTheme.bodyMedium!.fontSize, 14);
    expect(t.textTheme.bodySmall!.fontSize, 13);
    expect(t.textTheme.bodyMedium!.fontFamily, 'Inter');
    expect(t.textTheme.labelSmall!.fontFamily, 'Inter');
    expect(BL.mono(size: 12).fontFamily, 'Inter', reason: 'the small-label voice is Inter with tabular figures');
    expect(BL.codeStyle.fontFamily, 'JetBrains Mono');
    expect(BL.codeStyle.fontSize, 13);
  });
}
