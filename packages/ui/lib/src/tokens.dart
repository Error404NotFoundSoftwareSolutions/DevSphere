// User story: US-37 Usability and accessibility (Sprint 9, MVP)
// Requirements: NFR-USE-001
// Implemented here: DevPilot design tokens (docs/DESIGN_SYSTEM.md). Single source of colour, spacing and type, with a
// light and a dark palette. The mode is a runtime switch: `BL.dark = true` and rebuild the app. Colours are getters so
// every screen follows the switch; geometry and spacing are constants.

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

class BLPalette {
  const BLPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.selected,
    required this.primary,
    required this.primaryHover,
    required this.primarySoft,
    required this.onPrimary,
    required this.navy,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.border,
    required this.borderStrong,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.heroStart,
    required this.heroEnd,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color selected;
  final Color primary;
  final Color primaryHover;
  final Color primarySoft;
  final Color onPrimary;
  final Color navy;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color border;
  final Color borderStrong;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// The two ends of the deep-blue "continue" panel.
  final Color heroStart;
  final Color heroEnd;
  final Color shadow;
}

abstract final class BL {
  /// The mode. Set it, then rebuild the whole app (the app does this when the person flips the switch).
  static bool dark = false;

  // Light: a cool off-white canvas, white surfaces, a trustworthy blue, deep navy for weight.
  static const BLPalette _light = BLPalette(
    background: Color(0xFFF5F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEEF2F8),
    selected: Color(0xFFE6EEFF),
    primary: Color(0xFF2459E6),
    primaryHover: Color(0xFF1B47C2),
    primarySoft: Color(0xFFE6EEFF),
    onPrimary: Color(0xFFFFFFFF),
    navy: Color(0xFF0E2148),
    textPrimary: Color(0xFF0F1B33),
    textSecondary: Color(0xFF5A6882),
    textDisabled: Color(0xFF9AA6BC),
    border: Color(0xFFE3E8F1),
    borderStrong: Color(0xFFCFD7E5),
    success: Color(0xFF0A7D56),
    warning: Color(0xFF9A5B00),
    danger: Color(0xFFC02F2F),
    info: Color(0xFF2459E6),
    heroStart: Color(0xFF0E2148),
    heroEnd: Color(0xFF2459E6),
    shadow: Color(0xFF0E2148),
  );

  // Dark: a blue-black canvas (not pure black), raised surfaces, the same blue lifted for contrast.
  static const BLPalette _dark = BLPalette(
    background: Color(0xFF0A0F1C),
    surface: Color(0xFF111A2E),
    surfaceMuted: Color(0xFF17213A),
    selected: Color(0xFF1B2A4E),
    primary: Color(0xFF6B93FF),
    primaryHover: Color(0xFF8AABFF),
    primarySoft: Color(0xFF1A2A52),
    onPrimary: Color(0xFF07112B),
    navy: Color(0xFF223052),
    textPrimary: Color(0xFFE8EEFB),
    textSecondary: Color(0xFF9AA8C6),
    textDisabled: Color(0xFF5C6A88),
    border: Color(0xFF1F2C48),
    borderStrong: Color(0xFF2B3B5E),
    success: Color(0xFF34D399),
    warning: Color(0xFFF2B84B),
    danger: Color(0xFFFF7A7A),
    info: Color(0xFF6B93FF),
    heroStart: Color(0xFF14264F),
    heroEnd: Color(0xFF2F5BD8),
    shadow: Color(0xFF000000),
  );

  static BLPalette get p => dark ? _dark : _light;

  static Color get background => p.background;
  static Color get surface => p.surface;
  static Color get surfaceMuted => p.surfaceMuted;
  static Color get selected => p.selected;
  static Color get primary => p.primary;
  static Color get primaryHover => p.primaryHover;
  static Color get primarySoft => p.primarySoft;
  static Color get onPrimary => p.onPrimary;
  static Color get glow => p.primary;
  static Color get navy => p.navy;
  static Color get textPrimary => p.textPrimary;
  static Color get textSecondary => p.textSecondary;
  static Color get textDisabled => p.textDisabled;
  static Color get border => p.border;
  static Color get borderStrong => p.borderStrong;
  static Color get success => p.success;
  static Color get warning => p.warning;
  static Color get danger => p.danger;
  static Color get info => p.info;
  static Color get heroStart => p.heroStart;
  static Color get heroEnd => p.heroEnd;

  /// Soft shadow under resting cards: visible in light, almost none in dark where hairlines do the work.
  static List<BoxShadow> get shadowCard => [
        BoxShadow(color: p.shadow.withValues(alpha: dark ? 0.0 : 0.05), blurRadius: 2, offset: const Offset(0, 1)),
        BoxShadow(color: p.shadow.withValues(alpha: dark ? 0.35 : 0.06), blurRadius: 24, offset: const Offset(0, 10)),
      ];
  static List<BoxShadow> get shadowLift => [
        BoxShadow(color: p.shadow.withValues(alpha: dark ? 0.0 : 0.06), blurRadius: 4, offset: const Offset(0, 2)),
        BoxShadow(color: p.shadow.withValues(alpha: dark ? 0.5 : 0.14), blurRadius: 32, offset: const Offset(0, 16)),
      ];

  // Category colours for icon tiles: a pale tile and the strong colour of the same hue. Same in both modes.
  static Color get tintBlue => dark ? const Color(0xFF1A2A52) : const Color(0xFFE6EEFF);
  static const Color blue = Color(0xFF2459E6);
  static Color get tintViolet => dark ? const Color(0xFF2A2250) : const Color(0xFFEFEAFF);
  static const Color violet = Color(0xFF7C5CFC);
  static Color get tintTeal => dark ? const Color(0xFF0F3A3A) : const Color(0xFFDDF6F1);
  static const Color teal = Color(0xFF12B5A6);
  static Color get tintAmber => dark ? const Color(0xFF3A2C10) : const Color(0xFFFFF1D6);
  static const Color amber = Color(0xFFE59A0E);
  static Color get tintRose => dark ? const Color(0xFF3A1822) : const Color(0xFFFFE6EC);
  static const Color rose = Color(0xFFE5486E);

  // Geometry
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusXl = 20;
  static const double radiusCard = 16;
  static const double buttonRadius = 10;
  static const double buttonHeight = 42;

  // Spacing (8-point grid)
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space12 = 48;

  // Layout
  static const double railWidth = 104;
  static const double topbarHeight = 64;
  static const double statusbarHeight = 28;
  static const double sidebarWidth = 232;
  static const double sidebarCollapsedWidth = 64;
  static const double sideColumnWidth = 420;
  static const double contentMaxWidth = 1800; // fills a full-screen window; narrower windows just use what they have

  // Typography
  static const String fontUi = 'Inter';
  static const String fontMono = 'JetBrains Mono';
  static const List<String> fontFallback = ['Segoe UI', 'Roboto', 'Noto Sans', 'Ubuntu', 'Helvetica Neue', 'Arial'];
  static const List<String> monoFallback = ['Consolas', 'Menlo', 'DejaVu Sans Mono', 'monospace'];

  /// Small supporting text (labels, numbers, ids, status). Inter with tabular figures, so numbers line up.
  /// The name is kept from the earlier design; it is not monospace any more.
  static TextStyle mono({double size = 12, FontWeight weight = FontWeight.w500, Color? color, double? spacing, double height = 1.4}) => TextStyle(
        fontFamily: fontUi,
        fontFamilyFallback: fontFallback,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: size,
        fontWeight: weight,
        color: color ?? textSecondary,
        letterSpacing: spacing,
        height: height,
      );

  /// Real code: file names, commands, the lab folder path.
  static TextStyle get codeStyle => TextStyle(
        fontFamily: fontMono,
        fontFamilyFallback: monoFallback,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  /// The code workspace keeps its own palette.
  static const Color editorBackground = Color(0xFF0B1220);
  static const Color editorText = Color(0xFFE6EDF7);
}
