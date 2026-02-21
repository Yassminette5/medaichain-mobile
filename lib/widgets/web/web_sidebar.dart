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
        color: AppColors.primaryDark,
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
          // Header du sidebar - Sans couleur violette
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                // Image icone_dashboard
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/icone_dash.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.science_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Nom de l'application seulement
                const Expanded(
                  child: Text(
                    'MEDAIChain',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Menu items - Style comme la capture
          Expanded(
            child: Container(
              color: AppColors.surface,
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
                    index: 3,
                    icon: Icons.calendar_today_rounded,
                    label: 'Gestion RDV',
                  ),
                  _buildMenuItem(
                    context,
                    index: 2,
                    icon: Icons.description_rounded,
                    label: 'Prescriptions',
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
                    index: 8,
                    icon: Icons.people_rounded,
                    label: 'Patients',
                  ),
                  _buildMenuItem(
                    context,
                    index: 10,
                    icon: Icons.settings_rounded,
                    label: 'Paramètres',
                  ),
                  _buildMenuItem(
                    context,
                    index: 9,
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                  ),
                ],
              ),
            ),
          ),
          // Footer avec déconnexion
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
          ],
        ),
      ),
    );
  }
}
