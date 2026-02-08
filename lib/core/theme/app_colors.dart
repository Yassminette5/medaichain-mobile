import 'package:flutter/material.dart';
import 'dart:ui';

/// MEDAIChain Modern Healthcare Color Palette
/// Contemporary design with glassmorphism and vibrant gradients
class AppColors {
  AppColors._();

  // Primary Colors - Vibrant Medical Teal
  static const Color primary = Color(0xFF00BFA6);
  static const Color primaryLight = Color(0xFF64FFDA);
  static const Color primaryDark = Color(0xFF00897B);

  // Secondary Colors - Electric Blue
  static const Color secondary = Color(0xFF536DFE);
  static const Color secondaryLight = Color(0xFF8C9EFF);
  static const Color secondaryDark = Color(0xFF304FFE);

  // Background Colors - Dark Mode Inspired
  static const Color background = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors - Vibrant
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoLight = Color(0xFFE0F2FE);

  // Medical-specific Colors - Neon Accents
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

  // Modern Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00BFA6), Color(0xFF00E5FF)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x40FFFFFF), Color(0x10FFFFFF)],
  );

  static const LinearGradient neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)],
  );

  // Shadow Colors
  static Color shadowColor = const Color(0xFF00BFA6).withValues(alpha: 0.15);
  static Color cardShadow = const Color(0xFF000000).withValues(alpha: 0.08);
  static Color glowShadow = const Color(0xFF00BFA6).withValues(alpha: 0.4);

  // Border Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color glassBorder = Color(0x30FFFFFF);

  // Biometric
  static const Color biometric = Color(0xFF10B981);
  static const Color biometricLight = Color(0xFFD1FAE5);
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
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.glassGradient,
              borderRadius: borderRadius ?? BorderRadius.circular(20),
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
    this.glowColor = const Color(0xFF00BFA6),
    this.blurRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: blurRadius,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
