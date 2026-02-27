import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette MedIaChain - Santé + Blockchain
  static const Color primaryMedical = Color(0xFF1E88E5); // Blue 600 - Confiance médicale
  static const Color accentMedical = Color(0xFF00ACC1); // Cyan 600 - Tech/Blockchain
  static const Color darkNavy = Color(0xFF0D47A1); // Blue 900 - Texte principal profond
  static const Color background = Color(0xFFF5F8FA); // Bleu très pâle - Fond propre
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFE53935); // Red 600
  static const Color success = Color(0xFF43A047); // Green 600
  static const Color warning = Color(0xFFFB8C00); // Orange 600
  
  // Couleurs secondaires MedIaChain
  static const Color lightBlue = Color(0xFFE3F2FD); // Blue 50
  static const Color mediumBlue = Color(0xFF64B5F6); // Blue 300
  static const Color chainAccent = Color(0xFF26C6DA); // Cyan 400 - Accent blockchain
  
  // Extended palette for premium dashboard
  static const Color sidebarDark = Color(0xFF0A1628); // Deep navy for sidebar
  static const Color sidebarHover = Color(0xFF132240); // Lighter navy for hover
  static const Color sidebarActive = Color(0xFF1A3158); // Active item bg
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textTertiary = Color(0xFFCBD5E1); // Slate 300
  static const Color dividerLight = Color(0xFFE2E8F0); // Slate 200
  static const Color purple = Color(0xFF7C3AED); // Violet 600
  static const Color pink = Color(0xFFEC4899); // Pink 500
  static const Color indigo = Color(0xFF6366F1); // Indigo 500

  // Backward compatibility
  static const Color primaryBlue = primaryMedical;
  static const Color primaryTeal = accentMedical;

  // Gradients MedIaChain
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryMedical, accentMedical],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0097A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF0F2035)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Premium card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: dividerLight.withOpacity(0.5)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0D47A1).withOpacity(0.04),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // Glassmorphism decoration
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: white.withOpacity(0.7),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: white.withOpacity(0.3)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
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
          color: Color(0xFF334155),
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
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
        prefixIconColor: const Color(0xFF94A3B8),
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
