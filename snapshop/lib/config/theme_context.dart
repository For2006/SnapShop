import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/settings/settings_provider.dart';
import 'app_colors.dart';

class ThemeAwareColors {
  final bool isDark;

  const ThemeAwareColors(this.isDark);

  Color get primaryBg => isDark ? AppColors.darkBgPrimary : AppColors.primaryBg;
  Color get secondaryBg => isDark ? AppColors.darkBgSecondary : AppColors.secondaryBg;
  Color get surface => isDark ? AppColors.darkBgSecondary : AppColors.white;
  Color get cardBg => isDark ? AppColors.darkBgSecondary : AppColors.cardBg;
  Color get textPrimary => isDark ? AppColors.white : AppColors.textPrimary;
  Color get textSecondary => isDark ? AppColors.white.withAlpha(179) : AppColors.textSecondary;
  Color get textTertiary => isDark ? AppColors.white.withAlpha(128) : AppColors.textTertiary;
  Color get divider => isDark ? Colors.white12 : AppColors.divider;
  Color get border => isDark ? Colors.white12 : AppColors.border;
  Color get searchBarBg => isDark ? AppColors.darkBgSecondary : AppColors.searchBarBg;
  Color get searchIconBg => isDark ? AppColors.darkBgSecondary : AppColors.searchIconBg;
  Color get white => isDark ? AppColors.darkBgSecondary : AppColors.white;
}

extension ThemeAwareContext on BuildContext {
  ThemeAwareColors get colors {
    final brightness = Theme.of(this).brightness;
    return ThemeAwareColors(brightness == Brightness.dark);
  }

  double fs(double base) {
    final container = ProviderScope.containerOf(this);
    final scale = container.read(settingsProvider).fontSizeOption.scale;
    return base * scale;
  }
}
