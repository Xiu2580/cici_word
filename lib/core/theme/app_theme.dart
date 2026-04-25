import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({double fontScale = 1.0}) {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Color(0xFFFCFAF5),
      secondary: AppColors.secondary,
      onSecondary: Color(0xFFFCFAF5),
      error: AppColors.unknown,
      onError: Colors.white,
      surface: AppColors.cardLight,
      onSurface: AppColors.textPrimaryLight,
    );

    final textTheme = _buildTextTheme(
      scale: fontScale,
      bodyColor: AppColors.textPrimaryLight,
      mutedColor: AppColors.textSecondaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceLight,
      canvasColor: AppColors.surfaceLight,
      dividerColor: AppColors.dividerLight,
      shadowColor: Colors.transparent,
      textTheme: textTheme,
      cardTheme: const CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: AppColors.dividerLight),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.35,
          color: AppColors.textPrimaryLight,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryLight,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.dividerLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.textPrimaryLight,
          backgroundColor: AppColors.cardLight,
          side: const BorderSide(color: AppColors.dividerLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.navUnselectedLight,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
        unselectedLabelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.navUnselectedLight,
        ),
      ),
      splashColor: _withOpacity(AppColors.primary, 0.08),
      highlightColor: Colors.transparent,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.cardLight,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData dark({double fontScale = 1.0}) {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Color(0xFFF9F4EB),
      secondary: AppColors.secondary,
      onSecondary: Color(0xFF1D2530),
      error: AppColors.unknown,
      onError: Colors.white,
      surface: AppColors.surfaceSoftDark,
      onSurface: AppColors.textPrimaryDark,
    );

    final textTheme = _buildTextTheme(
      scale: fontScale,
      bodyColor: AppColors.textPrimaryDark,
      mutedColor: AppColors.textSecondaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceDark,
      canvasColor: AppColors.surfaceDark,
      dividerColor: AppColors.dividerDark,
      textTheme: textTheme,
      cardTheme: const CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppColors.dividerDark),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.35,
          color: AppColors.textPrimaryDark,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardDark,
        selectedItemColor: AppColors.textPrimaryDark,
        unselectedItemColor: AppColors.navUnselectedDark,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
        unselectedLabelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.navUnselectedDark,
        ),
      ),
      splashColor: _withOpacity(AppColors.primary, 0.12),
      highlightColor: Colors.transparent,
    );
  }

  static Color _withOpacity(Color color, double opacity) {
    return color.withAlpha((255 * opacity).round());
  }

  static TextTheme _buildTextTheme({
    required double scale,
    required Color bodyColor,
    required Color mutedColor,
  }) {
    const fallbackFonts = <String>[
      'PingFang SC',
      'Noto Sans SC',
      'Microsoft YaHei',
      'Heiti SC',
    ];

    TextStyle style(
      double size, {
      FontWeight weight = FontWeight.w500,
      double height = 1.5,
      Color? color,
    }) {
      return TextStyle(
        fontSize: size * scale,
        fontWeight: weight,
        height: height,
        color: color ?? bodyColor,
        fontFamilyFallback: fallbackFonts,
      );
    }

    return TextTheme(
      displayLarge: style(52, weight: FontWeight.w700, height: 1.18),
      displayMedium: style(40, weight: FontWeight.w700, height: 1.22),
      headlineLarge: style(30, weight: FontWeight.w700, height: 1.28),
      headlineMedium: style(26, weight: FontWeight.w700, height: 1.3),
      headlineSmall: style(22, weight: FontWeight.w700, height: 1.32),
      titleLarge: style(20, weight: FontWeight.w700, height: 1.35),
      titleMedium: style(17, weight: FontWeight.w700, height: 1.4),
      titleSmall: style(15, weight: FontWeight.w600, height: 1.4),
      bodyLarge: style(16, weight: FontWeight.w500, height: 1.6),
      bodyMedium: style(15, weight: FontWeight.w500, height: 1.65),
      bodySmall:
          style(13, weight: FontWeight.w500, height: 1.55, color: mutedColor),
      labelLarge: style(15, weight: FontWeight.w700, height: 1.35),
      labelMedium:
          style(13, weight: FontWeight.w600, height: 1.3, color: mutedColor),
      labelSmall:
          style(12, weight: FontWeight.w600, height: 1.25, color: mutedColor),
    );
  }
}
