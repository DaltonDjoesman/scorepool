import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    const colors = AppColors.dark;

    final colorScheme = ColorScheme.dark(
      primary: colors.accent,
      onPrimary: colors.phoneBg,
      primaryContainer: colors.accentLight,
      onPrimaryContainer: colors.accent,
      secondary: colors.gold,
      onSecondary: colors.phoneBg,
      surface: colors.phoneSurface,
      onSurface: colors.phoneFg,
      onSurfaceVariant: colors.phoneMuted,
      error: colors.danger,
      onError: colors.phoneFg,
      outline: colors.phoneBorder,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.phoneBg,
      extensions: const [AppColors.dark],
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ).apply(bodyColor: colors.phoneFg, displayColor: colors.phoneFg),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.phoneBg,
        foregroundColor: colors.phoneFg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colors.phoneFg,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.phoneSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.phoneBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.phoneInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.phoneBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.phoneBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        labelStyle: TextStyle(color: colors.phoneMuted),
        hintStyle: TextStyle(color: colors.phoneMuted.withValues(alpha: 0.7)),
      ),
      dividerTheme: DividerThemeData(color: colors.phoneBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.phoneSurface,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: colors.phoneFg,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.phoneBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    return base;
  }
}
