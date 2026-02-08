import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';

/// Welcome Screen - First screen shown on app launch
/// Dark themed with MEDAIChain branding
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0A0E1A),
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF0A0E1A),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Logo with glow effect
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildLogo(),
                  ),
                  const SizedBox(height: 48),
                  // App title
                  _buildTitle(),
                  const SizedBox(height: 16),
                  // Tagline
                  _buildTagline(),
                  const Spacer(),
                  // Pagination dots
                  _buildPaginationDots(),
                  const SizedBox(height: 40),
                  // CTA Button
                  _buildCTAButton(),
                  const SizedBox(height: 24),
                  // Footer
                  _buildFooter(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: const Color(0xFF00D4AA).withValues(alpha: 0.2),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
      child: const Icon(
        Icons.local_hospital_rounded,
        color: Colors.white,
        size: 48,
      ),
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF00D4AA), Color(0xFF00E5CC)],
      ).createShader(bounds),
      child: const Text(
        'MEDAIChain',
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Text(
      'Carnet de Santé Intelligent\net Sécurisé',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.7),
        height: 1.4,
      ),
    );
  }

  Widget _buildPaginationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentPage;
        return GestureDetector(
          onTap: () => setState(() => _currentPage = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isActive ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF00D4AA)
                  : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(5),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00D4AA).withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCTAButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _navigateToNextScreen,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D4AA),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: const Color(0xFF00D4AA).withValues(alpha: 0.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Commencer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.security_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Sécurisé par Blockchain',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToNextScreen() {
    // Navigate to login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }
}
