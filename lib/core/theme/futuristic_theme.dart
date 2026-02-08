import 'package:flutter/material.dart';

/// Futuristic Theme Colors for MEDAIChain
class FuturisticColors {
  // Dark Backgrounds
  static const primaryDark = Color(0xFF0A0E27);
  static const secondaryDark = Color(0xFF1A1F3A);
  static const cardDark = Color(0xFF1E2442);
  
  // Neon Accents
  static const neonCyan = Color(0xFF00E5FF);
  static const neonPurple = Color(0xFFA855F7);
  static const neonPink = Color(0xFFEC4899);
  static const neonGreen = Color(0xFF00FF88);
  static const neonYellow = Color(0xFFFFB800);
  
  // Glass & Overlays
  static const glassWhite = Color(0x1AFFFFFF);
  static const glassWhiteStrong = Color(0x33FFFFFF);
  static const glassBorder = Color(0x33FFFFFF);
  
  // Gradients
  static const cyberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, neonPurple],
  );
  
  static const aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonPurple, neonPink],
  );
  
  static const blockchainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5FF), Color(0xFF00FF88)],
  );
  
  static const meshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0E27),
      Color(0xFF1A1F3A),
      Color(0xFF2D1B4E),
      Color(0xFF1A1F3A),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );
}

/// Futuristic Theme Configuration
class FuturisticTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: FuturisticColors.primaryDark,
      colorScheme: ColorScheme.dark(
        primary: FuturisticColors.neonCyan,
        secondary: FuturisticColors.neonPurple,
        surface: FuturisticColors.cardDark,
        background: FuturisticColors.primaryDark,
      ),
      cardTheme: CardThemeData(
        color: FuturisticColors.glassWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: FuturisticColors.glassBorder, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.white70),
        bodyMedium: TextStyle(color: Colors.white60),
      ),
    );
  }
  
  /// Glass Card Shadow
  static List<BoxShadow> get glassCardShadow => [
    BoxShadow(
      color: FuturisticColors.neonCyan.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];
  
  /// Neon Glow Shadow
  static List<BoxShadow> neonGlow(Color color, {double intensity = 0.5}) => [
    BoxShadow(
      color: color.withValues(alpha: intensity),
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: color.withValues(alpha: intensity * 0.5),
      blurRadius: 40,
      spreadRadius: 5,
    ),
  ];
}
