import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Sidebar pour le dashboard web
class WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String? labName;

  const WebSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.labName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header du sidebar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.science_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'MEDAIChain',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  labName ?? 'Centre d\'Analyses',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(
                  context,
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: 'Tableau de bord',
                ),
                _buildMenuItem(
                  context,
                  index: 1,
                  icon: Icons.inbox_rounded,
                  label: 'Réception demandes',
                ),
                _buildMenuItem(
                  context,
                  index: 2,
                  icon: Icons.description_rounded,
                  label: 'Prescriptions',
                ),
                _buildMenuItem(
                  context,
                  index: 3,
                  icon: Icons.calendar_today_rounded,
                  label: 'Gestion RDV',
                ),
                _buildMenuItem(
                  context,
                  index: 4,
                  icon: Icons.assignment_rounded,
                  label: 'Résultats',
                ),
                _buildMenuItem(
                  context,
                  index: 5,
                  icon: Icons.upload_file_rounded,
                  label: 'Upload résultats',
                ),
                _buildMenuItem(
                  context,
                  index: 6,
                  icon: Icons.edit_rounded,
                  label: 'Signature numérique',
                ),
                _buildMenuItem(
                  context,
                  index: 7,
                  icon: Icons.history_rounded,
                  label: 'Historique',
                ),
                _buildMenuItem(
                  context,
                  index: 8,
                  icon: Icons.people_rounded,
                  label: 'Patients',
                ),
                _buildMenuItem(
                  context,
                  index: 9,
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                ),
                _buildMenuItem(
                  context,
                  index: 10,
                  icon: Icons.settings_rounded,
                  label: 'Paramètres',
                ),
              ],
            ),
          ),
          // Footer avec déconnexion
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: _buildMenuItem(
              context,
              index: -1,
              icon: Icons.logout_rounded,
              label: 'Déconnexion',
              isLogout: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    bool isLogout = false,
  }) {
    final isSelected = selectedIndex == index;
    final color = isLogout
        ? AppColors.error
        : (isSelected ? AppColors.primary : AppColors.textSecondary);

    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
