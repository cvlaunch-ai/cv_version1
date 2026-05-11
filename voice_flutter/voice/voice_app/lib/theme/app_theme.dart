import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF030712);
  static const Color secondaryBG = Color(0xFF0A0F1E);
  static const Color surface = Color(0xFF0D1628);
  static const Color surface2 = Color(0xFF111827);
  
  static const Color primaryAccent = Color(0xFF38BDF8);
  static const Color secondaryAccent = Color(0xFF818CF8);
  static const Color tertiaryAccent = Color(0xFF34D399);
  
  static const Color textPrimary = Color(0xFFF0F9FF);
  static const Color textMuted = Color(0xFF64748B);
  
  static const Color border = Color(0x1F63B3ED);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryAccent, secondaryAccent, tertiaryAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryAccent,
      secondary: AppColors.secondaryAccent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      background: AppColors.background,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textMuted),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );

  static TextStyle get headlineStyle => GoogleFonts.syne(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    color: AppColors.textPrimary,
  );

  static TextStyle get logoStyle => GoogleFonts.syne(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}
