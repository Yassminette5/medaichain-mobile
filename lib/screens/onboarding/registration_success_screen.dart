import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/login_web_screen.dart';

/// Registration Success Screen - Premium Animated Design
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
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

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

  Color get _roleColor {
    switch (widget.role) {
      case 'patient':
        return const Color(0xFF667EEA);
      case 'medecin':
        return const Color(0xFF00D4AA);
      case 'centre_analyse':
        return const Color(0xFFF5576C);
      case 'pharmacie':
        return const Color(0xFF4FACFE);
      default:
        return const Color(0xFF00D4AA);
    }
  }

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _mainController.forward();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0F172A),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: Stack(
          children: [
            // Animated background particles
            ..._buildParticles(),
            // Main content
            SafeArea(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Success icon with animations
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildSuccessIcon(),
                        ),
                        const SizedBox(height: 40),
                        // Title and message
                        Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: _buildTitleSection(),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Role card
                        Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value * 1.2),
                            child: _buildRoleCard(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Features
                        Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value * 1.4),
                            child: _buildFeatures(),
                          ),
                        ),
                        const Spacer(),
                        // CTA Button
                        Opacity(
                          opacity: _fadeAnimation.value,
                          child: _buildCommencerButton(),
                        ),
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: _fadeAnimation.value * 0.6,
                          child: _buildFooterText(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParticles() {
    return List.generate(6, (index) {
      final random = math.Random(index);
      final size = 100.0 + random.nextDouble() * 150;
      final top = random.nextDouble() * MediaQuery.of(context).size.height;
      final left = random.nextDouble() * MediaQuery.of(context).size.width;
      final color = index % 2 == 0 ? AppColors.primary : const Color(0xFF667EEA);

      return Positioned(
        top: top,
        left: left,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Opacity(
              opacity: 0.03 + (_pulseController.value * 0.05),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [color, color.withValues(alpha: 0)],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildSuccessIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 50,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
              // Middle ring
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              // Main circle
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 55,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.neonGradient.createShader(bounds),
          child: const Text(
            'Compte Créé !',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Votre compte a été créé avec succès.\nVous pouvez vous connecter avec vos identifiants.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_roleColor, _roleColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _roleColor.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rôle Confirmé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vous êtes enregistré en tant que',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _roleDisplayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _roleColor,
                  ),
                ),
              ],
            ),
          ),
          // Checkmark
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFeatureBadge(Icons.lock_rounded, 'Chiffré', const Color(0xFF10B981)),
        const SizedBox(width: 24),
        _buildFeatureBadge(Icons.link_rounded, 'Blockchain', const Color(0xFF667EEA)),
        const SizedBox(width: 24),
        _buildFeatureBadge(Icons.security_rounded, 'Sécurisé', const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCommencerButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _navigateToLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Aller à la connexion',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Étape finale complétée',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  void _navigateToLogin() {
    final Widget screen = kIsWeb ? const LoginWebScreen() : const LoginScreen();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }
}
