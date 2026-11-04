// User story: US-37 Usability and accessibility (Sprint 9, MVP)
// Requirements: NFR-USE-001
// Implemented here: BuildLoop design tokens (docs/DESIGN_SYSTEM.md). Single source of colour, spacing and type.

import 'package:flutter/material.dart';

/// BuildLoop design tokens. Names follow tokens.css in the design system.
abstract final class BL {
  // Surfaces
  static const Color background = Color(0xFFF4F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F4F8);
  static const Color selected = Color(0xFFEAF1FF);

  // Brand
  static const Color primary = Color(0xFF2457C5);
  static const Color primaryHover = Color(0xFF1D49A5);
  static const Color primarySoft = Color(0xFFEAF1FF);
  static const Color navy = Color(0xFF183153);

  // Text
  static const Color textPrimary = Color(0xFF17243B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  // Borders and semantic colours
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF16845B);
  static const Color warning = Color(0xFFB7791F);
  static const Color danger = Color(0xFFC24141);
  static const Color info = Color(0xFF2457C5);

  // Geometry
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double buttonRadius = 9;
  static const double buttonHeight = 40;

  // Spacing
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space6 = 24;
  static const double space8 = 32;

  // Layout
  static const double railWidth = 104;
  static const double topbarHeight = 64;
  static const double sideColumnWidth = 440;

  // Typography
  static const String fontUi = 'Inter';
  static const String fontMono = 'JetBrains Mono';
  /// Used until Inter is bundled; never downloaded at runtime.
  static const List<String> fontFallback = ['Segoe UI', 'Roboto', 'Noto Sans', 'Ubuntu', 'Helvetica Neue', 'Arial'];

  static const TextStyle codeStyle = TextStyle(
    fontFamily: fontMono,
    fontFamilyFallback: ['Consolas', 'Menlo', 'DejaVu Sans Mono', 'monospace'],
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  /// Dark palette for the code workspace (a separate preference from the light dashboard).
  static const Color editorBackground = Color(0xFF0F1B2D);
  static const Color editorText = Color(0xFFE6EDF7);
}
