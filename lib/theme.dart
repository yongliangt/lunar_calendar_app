import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Deep Vermilion (Red) - Primary Brand Color
  static const Color primaryRed = Color(0xFFB71C1C);
  
  // Muted Gold - Accents
  static const Color accentGold = Color(0xFFC5A059);
  
  // Rice Paper (Beige) - Background
  static const Color backgroundBeige = Color(0xFFF9F7F0);
  
  // Dark Brown/Black - Primary Text
  static const Color textPrimary = Color(0xFF3E2723);
  
  // Lighter Beige for Cards/Surfaces
  static const Color surfaceBeige = Color(0xFFFFFDF5);

  // Border Beige for Tiles
  static const Color borderBeige = Color(0xFFE0D8C0);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primaryRed,
      scaffoldBackgroundColor: AppColors.backgroundBeige,
      
      // Typography
      textTheme: GoogleFonts.notoSerifScTextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.accentGold,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.accentGold),
        titleTextStyle: TextStyle(
          color: AppColors.accentGold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Noto Serif SC', // Fallback if GoogleFonts fails initially
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceBeige,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Slightly squared for traditional look
          side: const BorderSide(color: Color(0xFFE0D8C0), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.accentGold,
      ),
      
      // Color Scheme (Material 3)
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryRed,
        primary: AppColors.primaryRed,
        secondary: AppColors.accentGold,
        surface: AppColors.surfaceBeige,
        onPrimary: AppColors.accentGold,
        onSurface: AppColors.textPrimary,
      ),
      
      // Dialog Theme
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceBeige,
        titleTextStyle: TextStyle(
          color: AppColors.primaryRed,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
