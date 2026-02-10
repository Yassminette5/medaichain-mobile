import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/medical_card.dart';
import '../../providers/auth_provider.dart';
import '../onboarding/welcome_screen.dart';

/// Écran du profil médecin
class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.background],
          stops: const [0, 0.3],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 28),
              _buildStatsSection(),
              const SizedBox(height: 28),
              _buildMenuSection(context),
              const SizedBox(height: 28),
              _buildSettingsSection(context),
              const SizedBox(height: 28),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
            ),
            child: const Center(
              child: Text('SM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Dr. Sarah Mitchell',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Médecin Généraliste',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Colors.white.withValues(alpha: 0.9), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Certifié MEDAIChain',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        _buildStatItem('Patients', '1,234', Icons.people_rounded, AppColors.primary),
        const SizedBox(width: 12),
        _buildStatItem('Consultations', '4,567', Icons.calendar_today_rounded, AppColors.secondary),
        const SizedBox(width: 12),
        _buildStatItem('Années', '12', Icons.workspace_premium_rounded, AppColors.prescription),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 15)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return MedicalCard(
      title: 'Mon Espace',
      titleIcon: Icons.dashboard_rounded,
      child: Column(
        children: [
          _buildMenuItem(Icons.person_outline, 'Informations personnelles', AppColors.primary, () {}),
          const SizedBox(height: 12),
          _buildMenuItem(Icons.school_outlined, 'Diplômes et certifications', AppColors.secondary, () {}),
          const SizedBox(height: 12),
          _buildMenuItem(Icons.schedule_outlined, 'Horaires de consultation', AppColors.diagnosis, () {}),
          const SizedBox(height: 12),
          _buildMenuItem(Icons.medical_services_outlined, 'Spécialités', AppColors.prescription, () {}),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return MedicalCard(
      title: 'Paramètres',
      titleIcon: Icons.settings_rounded,
      child: Column(
        children: [
          _buildSettingItem(Icons.notifications_outlined, 'Notifications', true),
          const SizedBox(height: 12),
          _buildSettingItem(Icons.lock_outline, 'Sécurité', null),
          const SizedBox(height: 12),
          _buildSettingItem(Icons.language_outlined, 'Langue', null),
          const SizedBox(height: 12),
          _buildSettingItem(Icons.help_outline, 'Aide et support', null),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String label, bool? hasSwitch) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          if (hasSwitch != null)
            Switch(
              value: hasSwitch,
              onChanged: (_) {},
              activeColor: AppColors.primary,
            )
          else
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Afficher confirmation
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Déconnexion', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );

        if (shouldLogout == true && context.mounted) {
          // Déconnexion
          await context.read<AuthProvider>().logout();
          
          // Naviguer vers l'écran d'accueil
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            Text(
              'Se déconnecter',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
