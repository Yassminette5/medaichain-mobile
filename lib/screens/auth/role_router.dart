import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard_main_screen.dart';
import '../patientnesrine/main_screen.dart';
import '../pharmacie/pharmacie_dashboard_screen.dart';
import '../centre_analyse/home_centre_analyse.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../admin/admin_dashboard_screen.dart';
import '../clinique/home_admin_clinique_mobile.dart';
/// Router qui redirige vers l'interface appropriée selon le rôle de l'utilisateur
class RoleRouter {
  static Widget getHomeScreen(UserRole role) {
    switch (role) {
      case UserRole.medecin:
        return const DashboardScreen(); // Interface médecin
      
      case UserRole.patient:
        return const MainScreen(); // Interface patient
      
      case UserRole.pharmacie:
        return const PharmacieDashboardScreen();
      
      case UserRole.centreAnalyse:
        return const HomeCentreAnalyse();
      
      case UserRole.clinique:
        return kIsWeb ? const DashboardMainScreen() : const HomeAdminCliniqueMobile();
      case UserRole.admin:
        return const AdminDashboardScreen();
    }
  }
}
