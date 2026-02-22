import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _controller;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _taglineSlideAnimation;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Pulse animation for glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Float animation for subtle movement
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _pageController = PageController();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _titleSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _taglineSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
      ),
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
    _pulseController.dispose();
    _particleController.dispose();
    _floatController.dispose();
    _pageController.dispose();
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
            // Animated particles background
            ...List.generate(15, (index) => _buildAnimatedParticle(index)),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        if (index == 1) {
                          // Trigger any specific animation for page 2 if needed
                          // The AnimatedSwitcher or Implicit Animations in the widget handle it
                        }
                      },
                      children: [
                        _buildWelcomePage(),
                        _buildDoctorProfilePage(),
                        _buildSecurityPage(),
                      ],
                    ),
                  ),
                  // Pagination dots
                  _buildPaginationDots(),
                  const SizedBox(height: 40),
                  // CTA Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _buildCTAButton(),
                  ),
                  const SizedBox(height: 24),
                  // Footer
                  _buildFooter(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedParticle(int index) {
    final random = math.Random(index);
    final size = random.nextDouble() * 6 + 2;
    final startX = random.nextDouble();
    final startY = random.nextDouble();

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        final progress = (_particleController.value + index * 0.1) % 1.0;
        final x = startX * screenWidth + math.sin(progress * math.pi * 2 + index) * 30;
        final y = (startY + progress * 0.3) % 1.0 * screenHeight;

        return Positioned(
          left: x,
          top: y,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                width: size * _pulseAnimation.value,
                height: size * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.6),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWelcomePage() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final floatOffset = math.sin(_floatController.value * math.pi) * 8;
        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animated glow effect
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildAnimatedLogo(),
              ),
            ),
            const SizedBox(height: 48),
            // App title with slide animation
            AnimatedBuilder(
              animation: _titleSlideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _titleSlideAnimation.value),
                  child: Opacity(
                    opacity: _controller.value.clamp(0.3, 1.0),
                    child: child,
                  ),
                );
              },
              child: _buildTitle(),
            ),
            const SizedBox(height: 16),
            // Tagline with delayed slide animation
            AnimatedBuilder(
              animation: _taglineSlideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _taglineSlideAnimation.value),
                  child: Opacity(
                    opacity: _controller.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: _buildTagline(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorProfilePage() {
    // Only animate when this page is active
    final isActive = _currentPage == 1;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: isActive ? 1.0 : 0.0,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            transform: Matrix4.translationValues(0, isActive ? 0 : 50, 0),
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Grand cœur animé avec pulsation
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 0.9 + (_pulseAnimation.value - 0.8) * 0.5,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFF6B9D),
                              Color(0xFFFF8A80),
                              Color(0xFFFF6B9D),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B9D).withValues(alpha: 0.4 + (_pulseAnimation.value - 0.8) * 1.5),
                              blurRadius: 30 + (_pulseAnimation.value - 0.8) * 40,
                              spreadRadius: 5 + (_pulseAnimation.value - 0.8) * 10,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF6B9D).withValues(alpha: 0.2),
                              blurRadius: 60,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 70,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
                // Titre
                const Text(
                  'Votre Santé,',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Notre Priorité',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                // Message conseil avec cœur
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Color(0xFFFF6B9D),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Conseil du jour',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.favorite,
                            color: Color(0xFFFF6B9D),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '"Prenez soin de vous chaque jour,\nvotre santé est votre plus grande richesse"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityPage() {
    final isActive = _currentPage == 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 600),
        opacity: isActive ? 1.0 : 0.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouclier animé avec cercles rotatifs
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cercle externe rotatif
                    AnimatedBuilder(
                      animation: _particleController,
                      builder: (context, _) {
                        return Transform.rotate(
                          angle: _particleController.value * math.pi * 2,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Points lumineux sur le cercle
                                Positioned(
                                  top: 0,
                                  left: 76,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.8),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 76,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF00D9FF),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00D9FF).withValues(alpha: 0.8),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Cercle interne avec pulsation inverse
                    AnimatedBuilder(
                      animation: _particleController,
                      builder: (context, _) {
                        return Transform.rotate(
                          angle: -_particleController.value * math.pi * 2,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Icône bouclier avec effet glow pulsant
                    Transform.scale(
                      scale: 0.95 + (_pulseAnimation.value - 0.8) * 0.3,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3 + (_pulseAnimation.value - 0.8) * 1.0),
                              blurRadius: 30 + (_pulseAnimation.value - 0.8) * 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 48),
            // Titre avec animation de slide
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, isActive ? 0 : 30, 0),
              child: const Text(
                'Données Sécurisées',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            // Description avec animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, isActive ? 0 : 40, 0),
              child: Text(
                'Vos données de santé sont cryptées et protégées par la technologie Blockchain.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.7), height: 1.5),
              ),
            ),
            const SizedBox(height: 32),
            // Badge de sécurité animé
            AnimatedContainer(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, isActive ? 0 : 50, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      const Color(0xFF00D9FF).withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Icon(
                          Icons.lock_rounded,
                          color: Colors.white.withValues(alpha: 0.7 + (_pulseAnimation.value - 0.8) * 1.5),
                          size: 18,
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Chiffrement de bout en bout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4 + (_pulseAnimation.value - 0.8) * 1.5),
                blurRadius: 30 + (_pulseAnimation.value - 0.8) * 50,
                spreadRadius: 5 + (_pulseAnimation.value - 0.8) * 10,
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2 + (_pulseAnimation.value - 0.8) * 0.5),
                blurRadius: 60 + (_pulseAnimation.value - 0.8) * 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating ring
              Transform.rotate(
                angle: _particleController.value * math.pi * 2,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.local_hospital_rounded,
                color: Colors.white,
                size: 48,
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                AppColors.primary,
                Color(0xFF00D9FF),
                AppColors.primary,
              ],
              stops: [
                (_particleController.value - 0.3).clamp(0.0, 1.0),
                _particleController.value,
                (_particleController.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
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
      },
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
          onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isActive ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(5),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
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
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3 + (_pulseAnimation.value - 0.8) * 0.5),
                blurRadius: 15 + (_pulseAnimation.value - 0.8) * 20,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: Stack(
              children: [
                // Base button
                ElevatedButton(
                  onPressed: _navigateToNextScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 58),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == 2 ? "C'est parti !" : 'Continuer',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(math.sin(_floatController.value * math.pi * 2) * 4, 0),
                            child: child,
                          );
                        },
                        child: const Icon(Icons.arrow_forward, size: 22),
                      ),
                    ],
                  ),
                ),
                // Shine effect overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedBuilder(
                      animation: _particleController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            (_particleController.value * 3 - 1) * MediaQuery.of(context).size.width * 0.5,
                            0,
                          ),
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.2),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }
}
