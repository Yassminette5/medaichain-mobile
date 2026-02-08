import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/futuristic_theme.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';

/// Doctor Profile & Settings Screen
class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  bool _biometricEnabled = true;
  bool _notificationsEnabled = true;
  bool _autoBackup = true;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildStats(),
                  const SizedBox(height: 24),
                  _buildSecuritySettings(),
                  const SizedBox(height: 24),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FuturisticColors.glassWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FuturisticColors.glassBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) => FuturisticColors.cyberGradient.createShader(bounds),
            child: const Text(
              'Profil',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      showGlow: true,
      glowColor: FuturisticColors.neonPurple,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: FuturisticColors.aiGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: FuturisticTheme.neonGlow(FuturisticColors.neonPurple, intensity: 0.6),
            ),
            child: const Center(
              child: Text(
                'SM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Dr. Sophie Martin',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Médecine Générale',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: FuturisticColors.blockchainGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'CERTIFIÉ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStatCard('1,248', 'Patients', FuturisticColors.neonCyan),
        const SizedBox(width: 14),
        _buildStatCard('856', 'Consultations', FuturisticColors.neonPurple),
        const SizedBox(width: 14),
        _buildStatCard('4.9', 'Note', FuturisticColors.neonYellow),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [color, color.withValues(alpha: 0.6)],
              ).createShader(bounds),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: FuturisticColors.blockchainGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.security, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              ShaderMask(
                shaderCallback: (bounds) => FuturisticColors.blockchainGradient.createShader(bounds),
                child: const Text(
                  'Sécurité',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingToggle(
            'Authentification Biométrique',
            _biometricEnabled,
            (value) => setState(() => _biometricEnabled = value),
            Icons.fingerprint,
          ),
          const SizedBox(height: 14),
          _buildSettingToggle(
            'Notifications Push',
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
            Icons.notifications_outlined,
          ),
          const SizedBox(height: 14),
          _buildSettingToggle(
            'Sauvegarde Automatique',
            _autoBackup,
            (value) => setState(() => _autoBackup = value),
            Icons.cloud_upload_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingToggle(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: value ? FuturisticColors.neonCyan : Colors.white.withValues(alpha: 0.5),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 30,
            decoration: BoxDecoration(
              gradient: value ? FuturisticColors.cyberGradient : null,
              color: value ? null : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
              boxShadow: value
                  ? FuturisticTheme.neonGlow(FuturisticColors.neonCyan, intensity: 0.4)
                  : null,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return NeonButton(
      text: 'DÉCONNEXION',
      icon: Icons.logout,
      onPressed: _handleLogout,
      gradient: const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFF87171)],
      ),
      glowColor: const Color(0xFFEF4444),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: FuturisticTheme.neonGlow(const Color(0xFFEF4444), intensity: 0.5),
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                'Déconnexion',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Êtes-vous sûr de vouloir vous déconnecter ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeonButton(
                      text: 'Confirmer',
                      height: 50,
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                      ),
                      glowColor: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
