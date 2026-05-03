import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF1A1833);
  static const Color surface = Color(0xFF252248);
  static const Color surfaceVariant = Color(0xFF2D2A5E);
  static const Color primary = Color(0xFF4F7CFF);
  static const Color accent = Color(0xFF4ECDC4);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0ADCA);
  static const Color textMuted = Color(0xFF7A7899);
  static const Color success = Color(0xFF4CAF8E);
  static const Color warning = Color(0xFFFF9F43);
  static const Color error = Color(0xFFFF6B6B);
  static const Color cardBorder = Color(0xFF3D3A6B);
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? AppColors.primary : AppColors.textMuted,
              fontSize: 11,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 22,
            );
          }),
        ),
        useMaterial3: true,
      );
}
