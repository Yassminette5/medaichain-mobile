import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/medical_card.dart';
import '../../widgets/primary_button.dart';
import '../auth/login_screen.dart';
import '../history/access_history_screen.dart';
import '../operations/operation_presets_screen.dart';

/// Écran Profil Médecin
class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _buildProfileHeader(context),
          const SizedBox(height: 24),
          _buildStatsSection(context),
          const SizedBox(height: 24),
          _buildCertificationsSection(context),
          const SizedBox(height: 24),
          _buildSettingsSection(context),
          const SizedBox(height: 24),
          _buildLogoutButton(context),
        ]),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: const Text('SM', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        const Text('Dr. Sarah Mitchell', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Spécialiste Médecine Interne', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildBadge(Icons.verified, 'Vérifié'),
          const SizedBox(width: 16),
          _buildBadge(Icons.star, '15 ans exp.'),
        ]),
      ]),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Row(children: [
      Expanded(child: _buildStatCard('1 248', 'Total Patients', Icons.people, AppColors.primary)),
      const SizedBox(width: 12),
      Expanded(child: _buildStatCard('4.9', 'Note', Icons.star, AppColors.warning)),
    ]);
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)]),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildCertificationsSection(BuildContext context) {
    return MedicalCard(
      title: 'Certifications',
      titleIcon: Icons.workspace_premium,
      child: Column(children: [
        _buildCertItem('Certifié - Médecine Interne', '2015'),
        _buildCertItem('Réanimation Cardiaque Avancée (ACLS)', '2024'),
        _buildCertItem('Spécialiste Gestion du Diabète', '2022'),
      ]),
    );
  }

  Widget _buildCertItem(String name, String year) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.verified, color: AppColors.success, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
        Text(year, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return MedicalCard(
      title: 'Paramètres',
      titleIcon: Icons.settings,
      child: Column(children: [
        _buildSettingsItem(context, Icons.history, "Historique d'accès", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessHistoryScreen()))),
        _buildSettingsItem(context, Icons.receipt_long, 'Modèles opérations', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationPresetsScreen()))),
        _buildSettingsItem(context, Icons.notifications, 'Notifications', () {}),
        _buildSettingsItem(context, Icons.security, 'Sécurité & Confidentialité', () {}),
        _buildSettingsItem(context, Icons.help_outline, 'Aide & Support', () {}),
      ]),
    );
  }

  Widget _buildSettingsItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SecondaryButton(
      text: 'Déconnexion',
      color: AppColors.error,
      icon: Icons.logout,
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                },
                child: const Text('Déconnexion'),
              ),
            ],
          ),
        );
      },
    );
  }
}
