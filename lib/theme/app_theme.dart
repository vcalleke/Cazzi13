import 'package:flutter/material.dart';

class AppTheme {
  // Aanpasbare kleuren: wijzig deze waarden om het hele thema te veranderen
  static const Color background = Color(0xFFFFFFFF); // wit
  static const Color primary = Color(
    0xFFF3F4F6,
  ); // lichtgrijs voor kaarten/achtergrond
  static const Color accent = Color(0xFFFFC107); // goud/geel accent (standaard)

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: accent,
        background: background,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }
}
