import 'package:flutter/material.dart';
import 'dart:ui';

/// MEDAIChain Modern Healthcare Color Palette
/// Purple/Lavender theme with soft, premium design
class AppColors {
  AppColors._();

  // Primary Colors - Purple/Lavender
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8F89FF);
  static const Color primaryDark = Color(0xFF5A52E0);

  // Secondary Colors - Pastel Pink
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color secondaryLight = Color(0xFFF9A8D4);
  static const Color secondaryDark = Color(0xFFBE185D);

  // Background Colors - Light Mode
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF1E1B4B);
  static const Color darkSurface = Color(0xFF312E81);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors - Soft Pastels
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoLight = Color(0xFFE0F2FE);

  // Category Colors - Vibrant Pastels (like reference image)
  static const Color categoryGreen = Color(0xFF34D399);
  static const Color categoryCoral = Color(0xFFFB7185);
  static const Color categoryYellow = Color(0xFFFBBF24);
  static const Color categoryBlue = Color(0xFF60A5FA);
  static const Color categoryPurple = Color(0xFFA78BFA);

  //

  // Medical-specific Colors
  static const Color alert = Color(0xFFFF5252);
  static const Color alertLight = Color(0xFFFFCDD2);
  static const Color prescription = Color(0xFFA855F7);
  static const Color prescriptionLight = Color(0xFFF3E8FF);
  static const Color diagnosis = Color(0xFF06B6D4);
  static const Color diagnosisLight = Color(0xFFCFFAFE);
  static const Color blockchain = Color(0xFF818CF8);
  static const Color blockchainLight = Color(0xFFE0E7FF);
  static const Color ai = Color(0xFFEC4899);
  static const Color aiLight = Color(0xFFFCE7F3);

  // Modern Gradients - Purple/Lavender Theme
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF8F89FF)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF8F89FF)],
  );

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x40FFFFFF), Color(0x10FFFFFF)],
  );

  static const LinearGradient neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFFC4B5FD)],
  );

  // Soft category gradients
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF6EE7B7)],
  );

  static const LinearGradient coralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB7185), Color(0xFFFDA4AF)],
  );

  static const LinearGradient yellowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFFDE68A)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF60A5FA), Color(0xFF93C5FD)],
  );

  // Shadow Colors - Soft purple tint
  static Color shadowColor = const Color(0xFF6C63FF).withValues(alpha: 0.12);
  static Color cardShadow = const Color(0xFF6C63FF).withValues(alpha: 0.08);
  static Color glowShadow = const Color(0xFF6C63FF).withValues(alpha: 0.3);

  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color glassBorder = Color(0x30FFFFFF);

  // Biometric
  static const Color biometric = Color(0xFF10B981);
  static const Color biometricLight = Color(0xFFD1FAE5);

  // Gradient Colors
  static const Color gradientStart = Color(0xFF6C63FF);
  static const Color gradientMiddle = Color(0xFF8F89FF);
  static const Color gradientEnd = Color(0xFFB4A5FF);

  // Accent Colors
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentOrange = Color(0xFFFF9B71);
  static const Color accentCyan = Color(0xFF4ECDC4);
  static const Color accentGreen = Color(0xFF95E1D3);

  // Background Colors
  static const Color backgroundDark = Color(0xFFEEF0F8);

  // Text Colors
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMedium = Color(0xFF4A4A68);
  static const Color textGrey = Color(0xFF9E9EB0);


  static const Color white = Colors.white;
  static const Color accentBlue = Color(0xFFE0E7FF);
  static const Color accentPurple = Color(0xFFEEE5FF);

  // Gradients
 static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentPink, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> small = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> large = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> colored(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

class AppStyles {
  static BoxDecoration glassmorphic({Color? color}) => BoxDecoration(
    color: (color ?? Colors.white).withOpacity(0.7),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1.5,
    ),
    boxShadow: AppColors.medium,
  );

  static BoxDecoration neumorphic({Color? color}) => BoxDecoration(
    color: color ?? AppColors.background,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withOpacity(0.7),
        offset: const Offset(-6, -6),
        blurRadius: 12,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        offset: const Offset(6, 6),
        blurRadius: 12,
      ),
    ],
  );
}
/// Glassmorphism Card Widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.glassGradient,
              borderRadius: borderRadius ?? BorderRadius.circular(28),
              border: Border.all(color: AppColors.glassBorder, width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Neon Glow Container
class NeonGlowBox extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double blurRadius;

  const NeonGlowBox({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF6C63FF),
    this.blurRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.3),
            blurRadius: blurRadius,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
