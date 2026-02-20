import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Utilitaires pour détecter la plateforme et adapter l'UI
class PlatformUtils {
  /// Vérifie si l'application tourne sur le web
  static bool get isWeb => kIsWeb;

  /// Vérifie si l'application tourne sur mobile
  static bool get isMobile => !kIsWeb;

  /// Retourne la largeur de l'écran
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Retourne la hauteur de l'écran
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Vérifie si l'écran est large (desktop/tablet)
  static bool isLargeScreen(BuildContext context) {
    return getScreenWidth(context) >= 1024;
  }

  /// Vérifie si l'écran est moyen (tablet)
  static bool isMediumScreen(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= 768 && width < 1024;
  }

  /// Vérifie si l'écran est petit (mobile)
  static bool isSmallScreen(BuildContext context) {
    return getScreenWidth(context) < 768;
  }

  /// Retourne le type d'écran
  static ScreenType getScreenType(BuildContext context) {
    final width = getScreenWidth(context);
    if (width >= 1024) return ScreenType.desktop;
    if (width >= 768) return ScreenType.tablet;
    return ScreenType.mobile;
  }
}

enum ScreenType {
  mobile,
  tablet,
  desktop,
}
