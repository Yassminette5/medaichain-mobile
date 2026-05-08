// ignore_for_file: avoid_print, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/pharmacy_service.dart';
import '../../models/pharmacy_dashboard.dart';
import '../auth/login_screen.dart';
import 'web/pharmacy_web_profile.dart';

/// Pharmacy Profile Screen - Automatically uses web version on web platform
class PharmacyProfileScreen extends StatelessWidget {
  const PharmacyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Automatically use web version when running on web
    if (kIsWeb) {
      return const PharmacyWebProfile();
    }
    
    // Use mobile version for mobile platforms
    return const _PharmacyProfileMobile();
  }
}

/// Mobile version of Pharmacy Profile
class _PharmacyProfileMobile extends StatefulWidget {
  const _PharmacyProfileMobile();

  @override
  State<_PharmacyProfileMobile> createState() => _PharmacyProfileMobileState();
}

class _PharmacyProfileMobileState extends State<_PharmacyProfileMobile> {
  PharmacyDashboard? _dashboard;
  Map<String, dynamic>? _pharmacyProfile;
  String? _walletBalance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pharmacyId = authProvider.user?.id ?? 'pharmacy-1';
      final walletAddress = authProvider.user?.walletAddress;
      
      final dashboard = await PharmacyService.getDashboard(pharmacyId);
      final profile = await PharmacyService.getPharmacyProfile();
      final raw = await PharmacyService.getPharmacyProfileRaw();
      final merged = <String, dynamic>{...raw, ...profile};
      final balance = walletAddress != null && walletAddress.isNotEmpty
          ? await PharmacyService.getWalletTokenBalance(walletAddress)
          : null;
      
      setState(() {
        _dashboard = dashboard;
        _pharmacyProfile = merged;
        _walletBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _toggleDeliveryService(bool value) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pharmacyId = authProvider.user?.id ?? 'pharmacy-1';

      await PharmacyService.updatePharmacySettings(
        pharmacyId,
        {
          // Backend variants (keep both for compatibility across environments)
          'hasDelivery': value,
          'offersDelivery': value,
        },
      );

      // Reload profile to get updated data
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Service de livraison activé'
                  : 'Service de livraison désactivé',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final pharmacyId = authProvider.user?.id ?? 'pharmacy-1';

      await PharmacyService.updatePharmacySettings(
        pharmacyId,
        {'notificationsEnabled': value},
      );

      // Reload profile to get updated data
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Notifications activées'
                  : 'Notifications désactivées',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Changer le mot de passe'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe actuel *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le mot de passe actuel est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau mot de passe *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nouveau mot de passe est requis';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le mot de passe *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer le mot de passe';
                    }
                    if (value != newPasswordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _updatePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePassword(String currentPassword, String newPassword) async {
    try {
      await PharmacyService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe mis à jour avec succès'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _effectiveBalance() {
    final rawBalance = double.tryParse(_walletBalance ?? '0') ?? 0.0;
    final boostScore = _pharmacyProfile?['boostScore'] as num? ?? 0;
    final effective = rawBalance - boostScore.toDouble();
    return effective > 0 ? effective.toStringAsFixed(1) : '0.0';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 24),
                        _buildWalletSection(user),
                        const SizedBox(height: 24),
                        _buildInfoSection(user),
                        const SizedBox(height: 24),
                        _buildStatsSection(),
                        const SizedBox(height: 24),
                        _buildSettingsSection(),
                        const SizedBox(height: 32),
                        _buildLogoutButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4FACFE).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _dashboard?.pharmacyInfo.name ?? 'Pharmacie',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                SizedBox(width: 6),
                Text(
                  'Compte Vérifié',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(user) {
    final profile = _pharmacyProfile ?? const <String, dynamic>{};
    final String pharmacyName =
        (profile['pharmacyName'] ?? profile['name'] ?? _dashboard?.pharmacyInfo.name ?? '—').toString();
    final String address = (profile['address'] ?? profile['location']?['address'] ?? '—').toString();
    final String city = (profile['city'] ?? profile['location']?['city'] ?? '—').toString();
    final String wilaya = (profile['wilaya'] ?? profile['location']?['wilaya'] ?? '—').toString();
    final String licenseNumber = (profile['licenseNumber'] ?? profile['license'] ?? '—').toString();

    return _buildCard(
      title: 'Informations du compte',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.local_pharmacy_outlined,
            label: 'Nom Pharmacie',
            value: pharmacyName,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user?.email ?? 'Non disponible',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Téléphone',
            value: user?.phone ?? 'Non disponible',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Adresse',
            value: address,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.location_city_outlined,
            label: 'Ville',
            value: city,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.map_outlined,
            label: 'Wilaya',
            value: wilaya,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'N° Licence',
            value: licenseNumber,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet blockchain',
            value: user?.walletAddress ?? 'Non lié',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'ID Pharmacie',
            value: _dashboard?.pharmacyInfo.id ?? 'N/A',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Membre depuis',
            value: user?.createdAt != null
                ? '${user!.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
                : 'N/A',
          ),
          if (user?.lastLoginAt != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.access_time_outlined,
              label: 'Dernière connexion',
              value: '${user!.lastLoginAt!.day}/${user.lastLoginAt!.month}/${user.lastLoginAt!.year}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWalletSection(user) {
    final walletAddress = user?.walletAddress;

    return _buildCard(
      title: 'Mes FRYMN',
      icon: Icons.account_balance_wallet_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Adresse wallet',
            value: walletAddress ?? 'Wallet non configuré',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.monetization_on_outlined,
            label: 'Solde FRYMN',
            value: _effectiveBalance(),
          ),
          const SizedBox(height: 8),
          Text(
            'Le solde est lu depuis la blockchain via le wallet lié à votre compte pharmacie.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final totalOrders = _dashboard?.pharmacyInfo.totalOrders ?? 0;
    final totalPackages = _dashboard?.pharmacyInfo.totalPackages ?? 0;
    final totalRequests = _dashboard?.medicationRequests.length ?? 0;

    return _buildCard(
      title: 'Statistiques',
      icon: Icons.analytics_outlined,
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.shopping_bag_outlined,
            label: 'En attente',
            value: '$totalOrders',
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 16),
          _buildStatItem(
            icon: Icons.inventory_2_outlined,
            label: 'Traitées',
            value: '$totalPackages',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 16),
          _buildStatItem(
            icon: Icons.receipt_long_outlined,
            label: 'Total',
            value: '$totalRequests',
            color: const Color(0xFF4FACFE),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    final hasDelivery = _pharmacyProfile?['hasDelivery'] ?? _pharmacyProfile?['offersDelivery'] ?? false;
    final notificationsEnabled = _pharmacyProfile?['notificationsEnabled'] ?? false;
    
    return _buildCard(
      title: 'Paramètres',
      icon: Icons.settings_outlined,
      child: Column(
        children: [
          _buildSettingRow(
            icon: Icons.local_shipping_outlined,
            label: 'Service de livraison',
            trailing: Switch(
              value: hasDelivery,
              onChanged: (value) => _toggleDeliveryService(value),
              activeThumbColor: const Color(0xFF10B981),
            ),
          ),
          const Divider(height: 24),
          _buildSettingRow(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (value) => _toggleNotifications(value),
              activeThumbColor: const Color(0xFF10B981),
            ),
          ),
          const Divider(height: 24),
          _buildSettingRow(
            icon: Icons.lock_outline,
            label: 'Changer le mot de passe',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showChangePasswordDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Se déconnecter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


