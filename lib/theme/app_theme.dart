import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryBlue = Color(0xFF3366FF);
  static const Color darkBlue = Color(0xFF1A1A4E);
  static const Color lightBackground = Color(0xFFF7F7FA);
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color inputBackground = Color(0xFFF5F5F5);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF757575);
  static const Color bubblePurple = Color(0xFFD6D6F5);
  static const Color bubbleGreen = Color(0xFFD6F0E0);
  static const Color selectedCardBg = Color(0xFFE8EEFF);
  static const Color cardBorder = Color(0xFFE0E0E0);

  static ThemeData get theme => ThemeData(
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: lightBackground,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          surface: lightBackground,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: TextStyle(
            color: grey.withValues(alpha: 0.7),
            fontSize: 15,
          ),
        ),
      );
}
