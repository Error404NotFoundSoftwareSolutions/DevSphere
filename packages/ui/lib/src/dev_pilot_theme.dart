// User story: US-37 Usability and accessibility (Sprint 9, MVP)
// Requirements: NFR-USE-001
// Implemented here: the DevPilot theme (light or dark, from BL.dark) built only from tokens (docs/DESIGN_SYSTEM.md)

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
  final scheme = (BL.dark ? ColorScheme.dark : ColorScheme.light)(
    primary: BL.primary,
    onPrimary: BL.onPrimary,
    secondary: BL.navy,
    onSecondary: BL.textPrimary,
    surface: BL.surface,
    onSurface: BL.textPrimary,
    error: BL.danger,
    onError: BL.onPrimary,
    outline: BL.border,
    surfaceContainerHighest: BL.surfaceMuted,
    onSurfaceVariant: BL.textSecondary,
    primaryContainer: BL.primarySoft,
    onPrimaryContainer: BL.primary,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(BL.radiusMd));
  return ThemeData(
    useMaterial3: true,
    brightness: BL.dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: BL.background,
    canvasColor: BL.background,
    dividerColor: BL.border,
    dividerTheme: DividerThemeData(color: BL.border, thickness: 1, space: 1),
    fontFamily: BL.fontUi,
    fontFamilyFallback: BL.fontFallback,
    textTheme: TextTheme(
      headlineMedium: _t(28, FontWeight.w600, BL.textPrimary).copyWith(letterSpacing: -0.6, height: 1.2), // page heading
      headlineSmall: _t(22, FontWeight.w600, BL.textPrimary).copyWith(letterSpacing: -0.4, height: 1.25),
      titleLarge: _t(18, FontWeight.w600, BL.textPrimary).copyWith(letterSpacing: -0.2), // section heading
      titleMedium: _t(15, FontWeight.w600, BL.textPrimary).copyWith(letterSpacing: -0.1), // card heading
      titleSmall: _t(14, FontWeight.w600, BL.textPrimary),
      bodyLarge: _t(14, FontWeight.w400, BL.textPrimary),
      bodyMedium: _t(14, FontWeight.w400, BL.textPrimary),
      bodySmall: _t(13, FontWeight.w400, BL.textSecondary).copyWith(height: 1.5), // secondary
      labelLarge: _t(14, FontWeight.w500, BL.textPrimary),
      labelMedium: BL.mono(size: 12),
      labelSmall: BL.mono(size: 11, spacing: 0.6), // labels speak in mono
    ),
    cardTheme: CardThemeData(
      color: BL.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BL.radiusCard),
        side: BorderSide(color: BL.border, width: 1),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(BL.radiusMd))),
        side: WidgetStatePropertyAll(BorderSide(color: BL.borderStrong)),
        textStyle: WidgetStatePropertyAll(_t(13, FontWeight.w500, BL.textPrimary)),
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? BL.selected : Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? BL.textPrimary : BL.textSecondary),
        visualDensity: VisualDensity.compact,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: BL.surface,
      elevation: 8,
      shadowColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BL.radiusMd), side: BorderSide(color: BL.borderStrong)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BL.primary,
        foregroundColor: BL.onPrimary,
        disabledBackgroundColor: BL.surfaceMuted,
        disabledForegroundColor: BL.textDisabled,
        minimumSize: const Size(0, BL.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: BL.space4),
        shape: shape,
        elevation: 0,
        textStyle: _t(14, FontWeight.w600, BL.onPrimary),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return BL.surfaceMuted;
          if (s.contains(WidgetState.hovered) || s.contains(WidgetState.pressed)) return BL.primaryHover;
          return BL.primary;
        }),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BL.primary,
        foregroundColor: BL.onPrimary,
        disabledBackgroundColor: BL.surfaceMuted,
        disabledForegroundColor: BL.textDisabled,
        minimumSize: const Size(0, BL.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: BL.space4),
        shape: shape,
        elevation: 0,
        textStyle: _t(14, FontWeight.w600, BL.onPrimary),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return BL.surfaceMuted;
          if (s.contains(WidgetState.hovered) || s.contains(WidgetState.pressed)) return BL.primaryHover;
          return BL.primary;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BL.textPrimary,
        backgroundColor: Colors.transparent,
        minimumSize: const Size(0, BL.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: BL.space4),
        shape: shape,
        side: BorderSide(color: BL.borderStrong),
        textStyle: _t(14, FontWeight.w500, BL.textPrimary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: BL.primary, shape: shape, textStyle: _t(14, FontWeight.w500, BL.primary)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BL.surfaceMuted,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: BL.space3, vertical: BL.space3),
      hintStyle: _t(14, FontWeight.w400, BL.textSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(BL.radiusMd), borderSide: BorderSide(color: BL.borderStrong)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BL.radiusMd), borderSide: BorderSide(color: BL.borderStrong)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BL.radiusMd),
        borderSide: BorderSide(color: BL.primary, width: 1.2),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: BL.primary,
      linearTrackColor: BL.border,
      linearMinHeight: 6,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: BL.navy, borderRadius: BorderRadius.circular(BL.radiusSm)),
      textStyle: _t(12, FontWeight.w500, BL.textPrimary),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: BL.surface,
      elevation: 8,
      shadowColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BL.radiusLg), side: BorderSide(color: BL.borderStrong)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: BL.primary,
      unselectedLabelColor: BL.textSecondary,
      indicatorColor: BL.primary,
      dividerColor: BL.border,
    ),
    iconTheme: IconThemeData(color: BL.textSecondary, size: 20),
  );
}
