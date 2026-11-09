// User story: US-37 Usability and accessibility (Sprint 9, MVP)
// Requirements: NFR-USE-001
// Implemented here: DevPilot light theme built only from tokens (docs/DESIGN_SYSTEM.md)

import 'package:flutter/material.dart';
import 'tokens.dart';

TextStyle _t(double size, FontWeight weight, Color color) => TextStyle(
      fontFamily: BL.fontUi,
      fontFamilyFallback: BL.fontFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.4,
    );

ThemeData devPilotTheme() {
  const scheme = ColorScheme.light(
    primary: BL.primary,
    onPrimary: Colors.white,
    secondary: BL.navy,
    onSecondary: Colors.white,
    surface: BL.surface,
    onSurface: BL.textPrimary,
    error: BL.danger,
    onError: Colors.white,
    outline: BL.border,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(BL.buttonRadius));
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: BL.background,
    canvasColor: BL.background,
    dividerColor: BL.border,
    dividerTheme: const DividerThemeData(color: BL.border, thickness: 1, space: 1),
    fontFamily: BL.fontUi,
    fontFamilyFallback: BL.fontFallback,
    textTheme: TextTheme(
      headlineMedium: _t(28, FontWeight.w600, BL.textPrimary), // page heading
      titleLarge: _t(20, FontWeight.w600, BL.textPrimary), // section heading
      titleMedium: _t(16, FontWeight.w600, BL.textPrimary), // card heading
      bodyLarge: _t(14, FontWeight.w400, BL.textPrimary),
      bodyMedium: _t(14, FontWeight.w400, BL.textPrimary),
      bodySmall: _t(13, FontWeight.w400, BL.textSecondary), // secondary
      labelLarge: _t(14, FontWeight.w500, BL.textPrimary),
      labelMedium: _t(12, FontWeight.w500, BL.textSecondary),
      labelSmall: _t(12, FontWeight.w500, BL.textSecondary), // labels
    ),
    cardTheme: CardThemeData(
      color: BL.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BL.radiusXl),
        side: const BorderSide(color: BL.border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BL.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: BL.border,
        disabledForegroundColor: BL.textDisabled,
        minimumSize: const Size(0, BL.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: BL.space4),
        shape: shape,
        elevation: 0,
        textStyle: _t(14, FontWeight.w500, Colors.white),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return BL.border;
          if (s.contains(WidgetState.hovered) || s.contains(WidgetState.pressed)) return BL.primaryHover;
          return BL.primary;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BL.textPrimary,
        backgroundColor: BL.surface,
        minimumSize: const Size(0, BL.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: BL.space4),
        shape: shape,
        side: const BorderSide(color: BL.border),
        textStyle: _t(14, FontWeight.w500, BL.textPrimary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: BL.primary, textStyle: _t(14, FontWeight.w500, BL.primary)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BL.surfaceMuted,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: BL.space3, vertical: BL.space3),
      hintStyle: _t(14, FontWeight.w400, BL.textSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(BL.radiusMd), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BL.radiusMd), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BL.radiusMd),
        borderSide: const BorderSide(color: BL.primary, width: 1.5),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: BL.primary,
      linearTrackColor: BL.border,
      linearMinHeight: 6,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: BL.navy, borderRadius: BorderRadius.circular(BL.radiusSm)),
      textStyle: _t(12, FontWeight.w500, Colors.white),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: BL.surface,
      elevation: 8,
      shadowColor: const Color(0x1A183153),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BL.radiusLg)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: BL.primary,
      unselectedLabelColor: BL.textSecondary,
      indicatorColor: BL.primary,
      dividerColor: BL.border,
    ),
    iconTheme: const IconThemeData(color: BL.textSecondary, size: 20),
  );
}
