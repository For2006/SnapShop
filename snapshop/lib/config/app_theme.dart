import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme([double fontSizeScale = 1.0]) {
    return _buildTheme(Brightness.light, fontSizeScale);
  }

  static ThemeData darkTheme([double fontSizeScale = 1.0]) {
    return _buildTheme(Brightness.dark, fontSizeScale);
  }

  static ThemeData _buildTheme(Brightness brightness, double fontSizeScale) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.primaryBg,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: AppColors.brandBlue,
              secondary: AppColors.brandPurple,
              surface: AppColors.darkBgSecondary,
              onPrimary: AppColors.white,
              onSecondary: AppColors.white,
              onSurface: AppColors.white.withAlpha(230),
              onError: AppColors.white,
              error: AppColors.errorRed,
            )
          : const ColorScheme.light(
              primary: AppColors.brandBlue,
              secondary: AppColors.brandPurple,
              surface: AppColors.white,
              error: AppColors.errorRed,
              onPrimary: AppColors.white,
              onSecondary: AppColors.white,
              onSurface: AppColors.textPrimary,
              onError: AppColors.white,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkBgSecondary : AppColors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontSize: 18 * fontSizeScale,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkBgSecondary : AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkBgSecondary : AppColors.cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.brandBlueLight, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white54 : AppColors.textTertiary,
          fontSize: 14 * fontSizeScale,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : AppColors.divider,
        thickness: 0.5,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28 * fontSizeScale,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22 * fontSizeScale,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18 * fontSizeScale,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16 * fontSizeScale,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16 * fontSizeScale,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.white.withAlpha(222) : AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14 * fontSizeScale,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.white.withAlpha(179) : AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12 * fontSizeScale,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.white.withAlpha(153) : AppColors.textTertiary,
        ),
        labelLarge: TextStyle(
          fontSize: 14 * fontSizeScale,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: 10 * fontSizeScale,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.white.withAlpha(128) : AppColors.textTertiary,
        ),
      ),
    );
  }
}
