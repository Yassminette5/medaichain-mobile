import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thème dédié au module Clinique (séparé du reste de l'app)
/// MEDAIChain — Medical Blue + Healing Teal palette
class AppTheme {
  // ─── Core Brand Colors ────────────────────────────────────────────────────
  static const Color primaryMedical = Color(0xFF1565C0); // Medical Blue
  static const Color accentMedical  = Color(0xFF00897B); // Healing Teal
  static const Color darkNavy       = Color(0xFF0D1B3E); // Dark Navy
  static const Color background     = Color(0xFFF0F7FF); // Light blue-white
  static const Color white          = Color(0xFFFFFFFF);

  // ─── Status Colors ────────────────────────────────────────────────────────
  static const Color error   = Color(0xFFE53935); // Red
  static const Color success = Color(0xFF2E7D32); // Green
  static const Color warning = Color(0xFFF57C00); // Amber

  // ─── Secondary Palette ────────────────────────────────────────────────────
  static const Color lightBlue   = Color(0xFFE3F2FD); // Material Blue 50
  static const Color mediumBlue  = Color(0xFF42A5F5); // Medium sky blue
  static const Color chainAccent = Color(0xFF00897B); // Teal accent

  // ─── Typography & UI ──────────────────────────────────────────────────────
  static const Color textSecondary = Color(0xFF546E7A); // Blue-grey 600
  static const Color sidebarHover  = Color(0xFFE3F2FD); // Light blue
  static const Color sidebarActive = Color(0xFFE3F2FD); // Light blue

  // ─── Divider ──────────────────────────────────────────────────────────────
  static const Color dividerLight = Color(0xFFBBDEFB); // Blue 100

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF071832), Color(0xFF0D2240)], // Deep navy
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0288D1)], // Blue shades
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF00897B)], // Blue to Teal
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF57C00), Color(0xFFFFCC02)], // Amber
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF43A047)], // Green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Kept for backward compatibility — now maps to the primary blue gradient
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Misc Constants ───────────────────────────────────────────────────────
  static const Color indigo = Color(0xFF3F51B5); // Kept for compat

  // ─── Card Decoration ──────────────────────────────────────────────────────
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: primaryMedical.withValues(alpha: 0.08),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ─── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryMedical,
      scaffoldBackgroundColor: background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryMedical,
        brightness: Brightness.light,
        primary: primaryMedical,
        onPrimary: white,
        secondary: accentMedical,
        onSecondary: white,
        surface: white,
        onSurface: darkNavy,
        error: error,
        onError: white,
        tertiary: darkNavy,
        surfaceContainerLowest: background,
      ),

      // ── Typography ────────────────────────────────────────────────────────
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: darkNavy,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkNavy,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: darkNavy,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkNavy,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkNavy,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkNavy,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkNavy,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: const Color(0xFF1A3A5C), // dark blue-ish body
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkNavy,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),

      // ── App Bar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkNavy),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: darkNavy,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ── Elevated Button ───────────────────────────────────────────────────
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
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryMedical,
          side: const BorderSide(color: primaryMedical, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryMedical,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input Decoration ──────────────────────────────────────────────────
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
          borderSide: BorderSide(
            color: const Color(0xFFBBDEFB).withValues(alpha: 0.8), // blue 100
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryMedical, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFF90A4AE), // light blue-grey
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textSecondary,
        ),
        prefixIconColor: const Color(0xFF90A4AE),
        suffixIconColor: const Color(0xFF90A4AE),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: const Color(0xFFBBDEFB).withValues(alpha: 0.4),
          ),
        ),
        shadowColor: primaryMedical.withValues(alpha: 0.08),
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryMedical,
        unselectedItemColor: const Color(0xFF90A4AE),
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryMedical,
        foregroundColor: white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: lightBlue,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryMedical,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: dividerLight,
        thickness: 1,
        space: 1,
      ),

      // ── Icons ─────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: primaryMedical,
        size: 24,
      ),
    );
  }
}
