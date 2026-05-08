import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/medical_card.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'center_profile_screen.dart';
import 'manage_categories_screen.dart';
import 'opening_hours_screen.dart';

/// Écran des paramètres du centre d'analyse
class CenterSettingsScreen extends StatefulWidget {
  const CenterSettingsScreen({super.key});

  @override
  State<CenterSettingsScreen> createState() => _CenterSettingsScreenState();
}

class _CenterSettingsScreenState extends State<CenterSettingsScreen> {
  String? _labName;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadLabProfile();
  }

  String? _profilePhoto;

  Future<void> _loadLabProfile() async {
    try {
      final labProfile = await ApiService.getLabProfile();
      if (mounted) {
        setState(() {
          _labName = labProfile['name'] ?? labProfile['centreName'] ?? labProfile['centre_name'];
          final profilePhotoPath = labProfile['profilePhoto'] ?? 
                         labProfile['photo'] ?? 
                         labProfile['photoUrl'] ?? 
                         labProfile['image'] ?? 
                         labProfile['imageUrl'] ?? 
                         labProfile['logo'] ?? 
                         labProfile['logoUrl'];
          _profilePhoto = profilePhotoPath;
          debugPrint('🔵 Settings: ProfilePhotoPath: $profilePhotoPath');
          debugPrint('🔵 Settings: ProfilePhoto URL finale: ${_profilePhoto != null ? _buildImageUrl(_profilePhoto!) : null}');
        });
      }
    } catch (e) {
      debugPrint('❌ Settings: Erreur chargement profil: $e');
      if (mounted) {
        setState(() {
          _labName = null;
          _profilePhoto = null;
        });
      }
    }
  }

  String _buildImageUrl(String profilePhotoPath) {
    if (profilePhotoPath.isEmpty) return '';
    
    if (profilePhotoPath.startsWith('http')) {
      return profilePhotoPath;
    } else {
      // Construire l'URL complète en extrayant le nom du fichier
      // Format attendu: /lab/uploads/profiles/filename.png ou uploads/profiles/filename.png
      final filename = profilePhotoPath.split('/').last;
      final imageUrl = '${ApiService.baseUrl}/lab/uploads/profiles/$filename';
      debugPrint('🔵 Settings: Construction URL image: $imageUrl');
      return imageUrl;
    }
  }

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
    final initials = _labName?.split(' ').map((n) => n[0]).take(2).join().toUpperCase() ?? 'LC';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15)],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _profilePhoto != null && _profilePhoto!.isNotEmpty
                  ? Image.network(
                      _buildImageUrl(_profilePhoto!),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ Erreur chargement image: $error');
                        return Center(
                          child: Text(
                            initials,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _labName ?? 'Labo Central',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return MedicalCard(
      title: 'Mon Espace',
      titleIcon: Icons.dashboard_rounded,
      child: Column(
        children: [
          _buildMenuItem(Icons.business_outlined, 'Informations du centre', AppColors.primary, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CenterProfileScreen()),
            );
          }),
          const SizedBox(height: 12),
          _buildMenuItem(Icons.science_outlined, 'Gestion des analyses', AppColors.secondary, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
            );
          }),
          const SizedBox(height: 12),
          _buildMenuItem(Icons.schedule_outlined, 'Horaires d\'ouverture', AppColors.diagnosis, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OpeningHoursScreen()),
            );
          }),
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
          _buildSettingItem(Icons.notifications_outlined, 'Notifications', _notificationsEnabled, (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          }),
          const SizedBox(height: 12),
          _buildSettingItem(Icons.lock_outline, 'Sécurité', null, null),
          const SizedBox(height: 12),
          _buildSettingItem(Icons.language_outlined, 'Langue', null, null),
          const SizedBox(height: 12),
          _buildSettingItem(Icons.help_outline, 'Aide et support', null, null),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String label, bool? hasSwitch, Function(bool)? onSwitchChanged) {
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
          if (hasSwitch != null && onSwitchChanged != null)
            Switch(
              value: hasSwitch,
              onChanged: onSwitchChanged,
              activeThumbColor: AppColors.primary,
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
          
          // Naviguer vers l'écran de login
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
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
