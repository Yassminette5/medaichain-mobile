import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../dashboard/dashboard_screen.dart';
import '../patientnesrine/main_screen.dart';
import '../pharmacie/pharmacie_dashboard_screen.dart';
import '../centre_analyse/centre_analyse_dashboard_screen.dart';

/// Router qui redirige vers l'interface appropriée selon le rôle de l'utilisateur
class RoleRouter {
  static Widget getHomeScreen(UserRole role) {
    switch (role) {
      case UserRole.medecin:
        return const DashboardScreen(); // Interface médecin
      
      case UserRole.patient:
        return const MainScreen(); // Interface patient
      
      case UserRole.pharmacie:
        // Vérifier si l'écran existe, sinon utiliser un placeholder
        try {
          return const PharmacieDashboardScreen();
        } catch (e) {
          return _buildPlaceholderScreen('Pharmacie', role);
        }
      
      case UserRole.centreAnalyse:
        // Vérifier si l'écran existe, sinon utiliser un placeholder
        try {
          return const CentreAnalyseDashboardScreen();
        } catch (e) {
          return _buildPlaceholderScreen('Centre d\'Analyse', role);
        }
      
      case UserRole.clinique:
        return _buildPlaceholderScreen('Clinique', role);
      
      default:
        return const MainScreen(); // Par défaut, interface patient
    }
  }

  static Widget _buildPlaceholderScreen(String roleName, UserRole role) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interface $roleName'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'Interface $roleName',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'En cours de développement',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Text(
              'Rôle: ${role.displayName}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
