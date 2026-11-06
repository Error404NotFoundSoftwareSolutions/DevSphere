// User story: US-37 Usability and accessibility (Sprint 9, MVP)
// Requirements: NFR-USE-001 (consistent, accessible visual system)
// Test ID: TC-DES-001-01..05
// Implemented here: DevPilot design tokens and theme match docs/DESIGN_SYSTEM.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  test('TC-DES-001-01 tokens match the design system hex values', () {
    expect(BL.background, const Color(0xFFF4F6FA));
    expect(BL.surface, const Color(0xFFFFFFFF));
    expect(BL.primary, const Color(0xFF2457C5));
    expect(BL.primaryHover, const Color(0xFF1D49A5));
    expect(BL.navy, const Color(0xFF183153));
    expect(BL.border, const Color(0xFFE2E8F0));
    expect(BL.selected, const Color(0xFFEAF1FF));
    expect(BL.textPrimary, const Color(0xFF17243B));
    expect(BL.textSecondary, const Color(0xFF64748B));
    expect(BL.success, const Color(0xFF16845B));
    expect(BL.warning, const Color(0xFFB7791F));
    expect(BL.danger, const Color(0xFFC24141));
  });

  test('TC-DES-001-02 geometry and spacing tokens', () {
    expect([BL.radiusSm, BL.radiusMd, BL.radiusLg, BL.radiusXl], [6, 10, 16, 24]);
    expect([BL.space1, BL.space2, BL.space3, BL.space4, BL.space6, BL.space8], [4, 8, 12, 16, 24, 32]);
    expect(BL.railWidth, 104);
    expect(BL.topbarHeight, 64);
    expect(BL.sideColumnWidth, inInclusiveRange(400, 500));
  });

  test('TC-DES-001-03 light theme uses canvas background and primary blue', () {
    final t = devPilotTheme();
    expect(t.brightness, Brightness.light);
    expect(t.scaffoldBackgroundColor, BL.background);
    expect(t.colorScheme.primary, BL.primary);
    expect(t.dividerColor, BL.border);
  });

  test('TC-DES-001-04 cards are 24px radius with a 1px border; buttons 40px and 9px radius', () {
    final t = devPilotTheme();
    final card = t.cardTheme.shape as RoundedRectangleBorder;
    expect(card.borderRadius, BorderRadius.circular(24));
    expect(card.side.width, 1);
    expect(card.side.color, BL.border);
    final style = t.elevatedButtonTheme.style!;
    expect(style.minimumSize!.resolve({}), const Size(0, 40));
    expect((style.shape!.resolve({}) as RoundedRectangleBorder).borderRadius, BorderRadius.circular(9));
  });

  test('TC-DES-001-05 text scale: body 14, secondary 13, label 12, code font is mono', () {
    final t = devPilotTheme();
    expect(t.textTheme.bodyMedium!.fontSize, 14);
    expect(t.textTheme.bodySmall!.fontSize, 13);
    expect(t.textTheme.labelSmall!.fontSize, 12);
    expect(BL.codeStyle.fontSize, 13);
    expect(BL.codeStyle.fontFamily, 'JetBrains Mono');
    expect(t.textTheme.bodyMedium!.fontFamily, 'Inter');
  });
}
