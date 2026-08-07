import 'package:flutter/material.dart';

import '../core/design/app_colors.dart';
import '../core/design/app_radius.dart';

ThemeData buildSalonTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.indigo,
    primary: AppColors.indigo,
    secondary: AppColors.violet,
    surface: AppColors.surface,
    error: AppColors.rose,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    splashColor: AppColors.indigo.withValues(alpha: 0.08),
    highlightColor: AppColors.indigo.withValues(alpha: 0.04),
    dividerColor: AppColors.subtle,
    visualDensity: VisualDensity.standard,
    textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w900,
        fontSize: 24,
        letterSpacing: 0,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.surface,
        minimumSize: const Size(48, 50),
        side: const BorderSide(color: AppColors.subtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceSoft,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.subtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.indigo, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.indigo,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.darkNav,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  );
}
