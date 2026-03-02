import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thème dédié au module Clinique (séparé du reste de l'app)
class AppTheme {
  // Palette MedIaChain - Santé + Blockchain (Version Violette pour Clinique)
  static const Color primaryMedical = Color(0xFF7C3AED); // Purple 600
  static const Color accentMedical = Color(0xFFEC4899); // Pink 600
  static const Color darkNavy = Color(0xFF1E1B4B); // Deep Indigo/Navy
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFEF4444); // Red 600
  static const Color success = Color(0xFF4F46E5); // Indigo 600
  static const Color warning = Color(0xFF8B5CF6); // Violet 500

  // Couleurs secondaires MedIaChain
  static const Color lightBlue = Color(0xFFF5F3FF); // Violet 50
  static const Color mediumBlue = Color(0xFFA78BFA); // Violet 300
  static const Color chainAccent = Color(0xFFEC4899); // Pink 500
  
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color sidebarHover = Color(0xFFF1F5F9);
  static const Color sidebarActive = Color(0xFFF1F5F9);
  
  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)], // Dark Indigo to Deep Purple
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const Color dividerLight = Color(0xFFE2E8F0);

  // Gradients MedIaChain
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryMedical, Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
  );
  static const Color indigo = Color(0xFF6366F1);
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
  );
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(color: primaryMedical.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
    ],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryMedical,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryMedical,
        primary: primaryMedical,
        secondary: accentMedical,
        surface: white,
        error: error,
        tertiary: darkNavy,
        surfaceContainerLowest: background,
      ),

      // Typography Modern
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: darkNavy,
          letterSpacing: -0.5,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkNavy,
          letterSpacing: -0.5,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: Color(0xFF334155), // Slate 700
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B), // Slate 500
        ),
      ),

      // App Bar Pro
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkNavy),
        titleTextStyle: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: darkNavy,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Buttons High End
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMedical,
          foregroundColor: white,
          elevation: 4,
          shadowColor: primaryMedical.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input Decor
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryMedical, width: 2),
        ),
        prefixIconColor: const Color(0xFF94A3B8), // Slate 400
      ),

      // Cards Premium
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.05)),
        ),
      ),

      iconTheme: const IconThemeData(color: primaryMedical),
    );
  }
}

