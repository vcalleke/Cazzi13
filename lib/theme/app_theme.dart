import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFF8F6F0);
  static const Color primary = Color(0xFF2C3E50);
  static const Color accent = Color(0xFFD4AF37);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212121);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF27AE60);
  static const Color danger = Color(0xFFE74C3C);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textLight,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: accent,
        background: background,
        onPrimary: textLight,
        onSecondary: textDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: textDark,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        bodyMedium: TextStyle(fontSize: 16, color: textDark),
      ),
    );
  }
}
