import 'package:flutter/material.dart';
import 'dart:ui';

/// MEDAIChain Modern Healthcare Color Palette
/// Medical Blue + Healing Teal — elegant clinical design
class AppColors {
  AppColors._();

  // ─── Primary ─── Medical Blue ─────────────────────────────────────────────
  static const Color primary      = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark  = Color(0xFF0D47A1);

  // ─── Secondary ─── Healing Teal ───────────────────────────────────────────
  static const Color secondary      = Color(0xFF00897B);
  static const Color secondaryLight = Color(0xFF4DB6AC);
  static const Color secondaryDark  = Color(0xFF00695C);

  // ─── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background     = Color(0xFFF0F7FF); // very light blue-white
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF071832); // deep navy
  static const Color darkSurface    = Color(0xFF0D2240); // dark navy blue

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0D1B3E); // very dark blue
  static const Color textSecondary = Color(0xFF546E7A); // blue-grey
  static const Color textLight     = Color(0xFF90A4AE); // light blue-grey
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ─── Status ───────────────────────────────────────────────────────────────
  static const Color success      = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning      = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error        = Color(0xFFE53935);
  static const Color errorLight   = Color(0xFFFFEBEE);
  static const Color info         = Color(0xFF0288D1);
  static const Color infoLight    = Color(0xFFE1F5FE);

  // ─── Category Colors (used by patient screens) ────────────────────────────
  static const Color categoryGreen  = Color(0xFF43A047);
  static const Color categoryCoral  = Color(0xFFEF5350);
  static const Color categoryYellow = Color(0xFFFB8C00);
  static const Color categoryBlue   = Color(0xFF1E88E5);
  static const Color categoryPurple = Color(0xFF7E57C2);

  // ─── Medical-specific Colors ──────────────────────────────────────────────
  static const Color alert             = Color(0xFFEF5350);
  static const Color alertLight        = Color(0xFFFFEBEE);
  static const Color prescription      = Color(0xFF7E57C2);
  static const Color prescriptionLight = Color(0xFFEDE7F6);
  static const Color diagnosis         = Color(0xFF00ACC1);
  static const Color diagnosisLight    = Color(0xFFE0F7FA);
  static const Color blockchain        = Color(0xFF1565C0);
  static const Color blockchainLight   = Color(0xFFE3F2FD);
  static const Color ai                = Color(0xFF00897B);
  static const Color aiLight           = Color(0xFFE0F2F1);

  // ─── Gradients ────────────────────────────────────────────────────────────

  /// Blue shades — primary actions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
  );

  /// Deep blue — hero sections
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
  );

  /// Blue to Teal — AI / smart features
  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0288D1), Color(0xFF00897B)],
  );

  /// Deep navy — dark overlays
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF071832), Color(0xFF0D2240)],
  );

  /// Glassmorphism overlay
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x40FFFFFF), Color(0x10FFFFFF)],
  );

  /// Blue-to-Teal neon accent (replaces old purple neon — name kept for compat)
  static const LinearGradient neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF00897B)],
  );

  /// Green category gradient
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
  );

  /// Coral / red category gradient
  static const LinearGradient coralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF5350), Color(0xFFEF9A9A)],
  );

  /// Amber / orange category gradient
  static const LinearGradient yellowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB8C00), Color(0xFFFFCC02)],
  );

  /// Blue category gradient
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
  );

  // ─── Shadow Colors ────────────────────────────────────────────────────────
  static Color shadowColor = const Color(0xFF1565C0).withValues(alpha: 0.12);
  static Color cardShadow  = const Color(0xFF1565C0).withValues(alpha: 0.08);
  static Color glowShadow  = const Color(0xFF1565C0).withValues(alpha: 0.30);

  // ─── Border Colors ────────────────────────────────────────────────────────
  static const Color border      = Color(0xFFBBDEFB);
  static const Color borderLight = Color(0xFFE3F2FD);
  static const Color divider     = Color(0xFFE3F2FD);
  static const Color glassBorder = Color(0x30FFFFFF);

  // ─── Biometric ────────────────────────────────────────────────────────────
  static const Color biometric      = Color(0xFF00897B); // Teal
  static const Color biometricLight = Color(0xFFE0F2F1);

  // ─── Backward-compatible aliases ──────────────────────────────────────────
  static const Color textDark      = textPrimary;
  static const Color textGrey      = textSecondary;
  static const Color textMedium    = textSecondary;
  static const Color backgroundDark = Color(0xFFE3F2FD);

  // Accent colors kept for patient screens
  static const Color accentCyan   = Color(0xFF00BCD4);
  static const Color accentOrange = Color(0xFFF57C00);
  static const Color accentPink   = Color(0xFFEC407A);

  /// Accent gradient — Blue to Teal (replaces old pink-purple)
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF00897B)],
  );

  // ─── Box-shadow presets ───────────────────────────────────────────────────
  static List<BoxShadow> small = [
    BoxShadow(
      color: shadowColor,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: shadowColor,
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> colored(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
/// Glassmorphism Card Widget
// ─────────────────────────────────────────────────────────────────────────────
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
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Neon Glow Container  (default glow = Medical Blue)
// ─────────────────────────────────────────────────────────────────────────────
class NeonGlowBox extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double blurRadius;

  const NeonGlowBox({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF1565C0), // Medical Blue
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
