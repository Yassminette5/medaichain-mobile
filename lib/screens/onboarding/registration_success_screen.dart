import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../dashboard/dashboard_screen.dart';

/// Registration Success Screen - Final onboarding step
/// Shows success confirmation with role and security badges
class RegistrationSuccessScreen extends StatefulWidget {
  final String role;

  const RegistrationSuccessScreen({
    super.key,
    required this.role,
  });

  @override
  State<RegistrationSuccessScreen> createState() =>
      _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState extends State<RegistrationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  String get _roleDisplayName {
    switch (widget.role) {
      case 'patient':
        return 'Patient';
      case 'medecin':
        return 'Médecin';
      case 'centre_analyse':
        return "Centre d'analyse";
      case 'pharmacie':
        return 'Pharmacie';
      default:
        return widget.role;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Set status bar style for light background
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 1),
                // Success illustration
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildSuccessIllustration(),
                ),
                const SizedBox(height: 32),
                // Success title
                _buildSuccessTitle(),
                const SizedBox(height: 16),
                // Success message
                _buildSuccessMessage(),
                const SizedBox(height: 40),
                // Role confirmed section
                _buildRoleConfirmedSection(),
                const SizedBox(height: 24),
                // Security badges
                _buildSecurityBadges(),
                const Spacer(flex: 2),
                // Commencer button
                _buildCommencerButton(),
                const SizedBox(height: 16),
                // Footer link
                _buildFooterLink(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti-like decorations
        ...List.generate(8, (index) {
          final angle = index * 0.785; // 45 degrees each
          final radius = 80.0;
          return Positioned(
            left: 75 + radius * (index.isEven ? 0.8 : 1.0) * 
                (index < 4 ? 1 : -1) * (index % 2 == 0 ? 0.5 : 1),
            top: 75 + radius * (index.isOdd ? 0.8 : 1.0) * 
                (index < 2 || index > 5 ? 1 : -1) * (index % 2 == 0 ? 1 : 0.5),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: [
                  const Color(0xFF3B82F6),
                  const Color(0xFF10B981),
                  const Color(0xFFF59E0B),
                  const Color(0xFFEC4899),
                ][index % 4],
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
        // Main robot icon
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4FD),
            borderRadius: BorderRadius.circular(75),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.smart_toy,
                size: 80,
                color: Color(0xFF3B82F6),
              ),
              // Checkmark badge
              Positioned(
                right: 20,
                bottom: 20,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessTitle() {
    return const Text(
      'Compte Créé\navec Succès !',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        height: 1.2,
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Text(
      'Félicitations ! Votre espace\nsécurisé MEDAIChain est prêt.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 15,
        color: Colors.grey[600],
        height: 1.5,
      ),
    );
  }

  Widget _buildRoleConfirmedSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Rôle Confirmé',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Vous êtes maintenant\nenregistré en tant que',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _roleDisplayName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBadge(Icons.lock_outline, 'Chiffré'),
        const SizedBox(width: 24),
        _buildBadge(Icons.verified_outlined, 'Blockchain'),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildCommencerButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _navigateToDashboard,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Commencer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink() {
    return TextButton(
      onPressed: () {
        // Handle help link
      },
      child: Text(
        "J'ai besoin d'aide",
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[500],
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      (route) => false,
    );
  }
}
