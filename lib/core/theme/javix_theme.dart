import 'package:flutter/material.dart';

/// Javix theme - matches the reference UI (dark + gold).
class JavixColors {
  JavixColors._();

  static const Color background = Color(0xFF0A0E14);
  static const Color surface = Color(0xFF10161F);
  static const Color surfaceLight = Color(0xFF161D28);
  static const Color gold = Color(0xFFD4A24E);
  static const Color goldDim = Color(0xFF8A6A33);
  static const Color textPrimary = Color(0xFFF2EDE3);
  static const Color textSecondary = Color(0xFF9AA4B2);
  static const Color textTertiary = Color(0xFF5C6673);
  static const Color border = Color(0xFF232C3A);
  static const Color success = Color(0xFF4CAF7D);
  static const Color danger = Color(0xFFE05C5C);
}

class JavixTheme {
  JavixTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: JavixColors.background,
      colorScheme: const ColorScheme.dark(
        primary: JavixColors.gold,
        surface: JavixColors.surface,
        onSurface: JavixColors.textPrimary,
        error: JavixColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: JavixColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: JavixColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: JavixColors.border),
        ),
        elevation: 0,
      ),
      dividerColor: JavixColors.border,
      textTheme: base.textTheme.apply(
        bodyColor: JavixColors.textPrimary,
        displayColor: JavixColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: JavixColors.surfaceLight,
        hintStyle: const TextStyle(color: JavixColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: JavixColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: JavixColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: JavixColors.gold),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: JavixColors.surfaceLight,
        contentTextStyle: TextStyle(color: JavixColors.textPrimary),
      ),
    );
  }
}
