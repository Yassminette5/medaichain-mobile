import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';

/// Welcome / Onboarding Screen — MEDAIChain
/// Medical Blue (#1565C0) + Healing Teal (#00897B) theme
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // ─── Controllers ──────────────────────────────────────────────────────────
  late PageController _pageController;
  late AnimationController _controller;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _floatController;
  late AnimationController _ekgController;

  // ─── Animations ───────────────────────────────────────────────────────────
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _taglineSlideAnimation;

  int _currentPage = 0;

  // ─── Particle palette — blue / teal / cyan ────────────────────────────────
  static const List<Color> _particleColors = [
    Color(0xFF1565C0),
    Color(0xFF00897B),
    Color(0xFF00BCD4),
    Color(0xFF42A5F5),
    Color(0xFF4DB6AC),
    Color(0xFF0288D1),
    Color(0xFF26C6DA),
    Color(0xFF00ACC1),
  ];

  @override
  void initState() {
    super.initState();

    // Main entrance animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Pulse / glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Particle drift
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Subtle float
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    // EKG sweep
    _ekgController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat();

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
        systemNavigationBarColor: const Color(0xFF071832),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _floatController.dispose();
    _ekgController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: Stack(
          children: [
            // Subtle grid overlay
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            // Blue / teal / cyan animated particles
            ...List.generate(20, (i) => _buildAnimatedParticle(i)),
            // Page content
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      children: [
                        _buildWelcomePage(),
                        _buildDoctorProfilePage(),
                        _buildSecurityPage(),
                      ],
                    ),
                  ),
                  _buildPaginationDots(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _buildCTAButton(),
                  ),
                  const SizedBox(height: 14),
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PARTICLES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAnimatedParticle(int index) {
    final rng    = math.Random(index * 7 + 13);
    final size   = rng.nextDouble() * 5.5 + 1.8;
    final startX = rng.nextDouble();
    final startY = rng.nextDouble();
    final color  = _particleColors[index % _particleColors.length];

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, _) {
        final screen   = MediaQuery.of(context).size;
        final progress = (_particleController.value + index * 0.07) % 1.0;
        final x = startX * screen.width +
            math.sin(progress * math.pi * 2 + index) * 28;
        final y = (startY + progress * 0.22) % 1.0 * screen.height;

        return Positioned(
          left: x,
          top: y,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) => Container(
              width:  size * _pulseAnimation.value,
              height: size * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.75),
                    color.withValues(alpha: 0.0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.40),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1 — WELCOME
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWelcomePage() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, math.sin(_floatController.value * math.pi) * 8),
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Logo orb + EKG
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      _buildGradientLogoOrb(),
                      const SizedBox(height: 14),
                      _buildEKGLine(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // Title
              AnimatedBuilder(
                animation: _titleSlideAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _titleSlideAnimation.value),
                  child: Opacity(
                    opacity: _controller.value.clamp(0.3, 1.0),
                    child: child,
                  ),
                ),
                child: _buildTitle(),
              ),

              const SizedBox(height: 10),

              // Tagline
              AnimatedBuilder(
                animation: _taglineSlideAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _taglineSlideAnimation.value),
                  child: Opacity(
                    opacity: _controller.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
                child: _buildTagline(),
              ),

              const SizedBox(height: 28),
              _buildFeaturePills(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logo gradient orb ────────────────────────────────────────────────────

  Widget _buildGradientLogoOrb() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glow = _pulseAnimation.value; // 0.8 … 1.0
        return Stack(
          alignment: Alignment.center,
          children: [
            // Ambient radial glow
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1565C0).withValues(
                        alpha: 0.18 + (glow - 0.8) * 0.5),
                    const Color(0xFF00897B).withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Outer orbit ring (clockwise)
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => Transform.rotate(
                angle: _particleController.value * math.pi * 2,
                child: Container(
                  width: 122,
                  height: 122,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF42A5F5).withValues(alpha: 0.32),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 2,
                        left: 58,
                        child: _orbitDot(const Color(0xFF42A5F5)),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 56,
                        child: _orbitDot(const Color(0xFF00BCD4)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Inner orbit ring (counter-clockwise)
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => Transform.rotate(
                angle: -_particleController.value * math.pi * 1.6,
                child: Container(
                  width: 98,
                  height: 98,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00897B).withValues(alpha: 0.22),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            // Main orb — blue → teal gradient
            Transform.scale(
              scale: 0.97 + (glow - 0.8) * 0.18,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1565C0),
                      Color(0xFF0288D1),
                      Color(0xFF00897B),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withValues(
                          alpha: 0.45 + (glow - 0.8) * 1.3),
                      blurRadius: 24 + (glow - 0.8) * 44,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFF00897B).withValues(
                          alpha: 0.22 + (glow - 0.8) * 0.8),
                      blurRadius: 50 + (glow - 0.8) * 20,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Spinning inner ring
                    AnimatedBuilder(
                      animation: _particleController,
                      builder: (context, _) => Transform.rotate(
                        angle: _particleController.value * math.pi * 3,
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _orbitDot(Color color) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.9),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  // ── EKG / heartbeat line ─────────────────────────────────────────────────

  Widget _buildEKGLine() {
    return AnimatedBuilder(
      animation: _ekgController,
      builder: (context, _) => SizedBox(
        width: 230,
        height: 42,
        child: CustomPaint(
          painter: _EKGPainter(
            progress: _ekgController.value,
            color: const Color(0xFF00BCD4),
          ),
        ),
      ),
    );
  }

  // ── Feature pills ─────────────────────────────────────────────────────────

  Widget _buildFeaturePills() {
    const features = [
      ('🏥', 'Cliniques'),
      ('💊', 'Pharmacies'),
      ('🧬', 'IA Médicale'),
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: ((_controller.value - 0.6) / 0.4).clamp(0.0, 1.0),
        child: child,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: features
            .map(
              (f) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF42A5F5).withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(f.$1,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 7),
                    Text(
                      f.$2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2 — DOCTOR / HEALTH
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDoctorProfilePage() {
    final isActive = _currentPage == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 700),
        opacity: isActive ? 1.0 : 0.0,
        curve: Curves.easeOut,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // Teal pulsing heart
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final pulse = _pulseAnimation.value;
                    return Transform.scale(
                      scale: 0.92 + (pulse - 0.8) * 0.55,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF00695C),
                              Color(0xFF00897B),
                              Color(0xFF26A69A),
                              Color(0xFF00BCD4),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00897B).withValues(
                                  alpha: 0.45 + (pulse - 0.8) * 1.5),
                              blurRadius: 28 + (pulse - 0.8) * 42,
                              spreadRadius: 4 + (pulse - 0.8) * 10,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00BCD4)
                                  .withValues(alpha: 0.18),
                              blurRadius: 55,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 66,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 34),

                // Title
                const Text(
                  'Consultez vos médecins',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Accédez à vos ordonnances, analyses\net rendez-vous en temps réel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.68),
                    height: 1.55,
                  ),
                ),

                const SizedBox(height: 30),

                // Stat cards
                _buildStatCards(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    final stats = [
      (
        Icons.medical_services_rounded,
        '28',
        'Médecins\ndisponibles',
        const Color(0xFF42A5F5),
      ),
      (
        Icons.bar_chart_rounded,
        '2.4k',
        'Consultations\nréalisées',
        const Color(0xFF00BCD4),
      ),
      (
        Icons.verified_rounded,
        '98%',
        'Patients\nsatisfaits',
        const Color(0xFF4DB6AC),
      ),
    ];

    return Row(
      children: stats.map((s) {
        final color = s.$4;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: 0.28),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(s.$1, color: color, size: 22),
                const SizedBox(height: 8),
                Text(
                  s.$2,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  s.$3,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.58),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 3 — SECURITY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSecurityPage() {
    final isActive = _currentPage == 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 600),
        opacity: isActive ? 1.0 : 0.0,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Animated shield
              _buildShieldWidget(isActive),

              const SizedBox(height: 40),

              // Title
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                transform:
                    Matrix4.translationValues(0, isActive ? 0 : 30, 0),
                child: const Text(
                  'Sécurité Blockchain',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                transform:
                    Matrix4.translationValues(0, isActive ? 0 : 40, 0),
                child: Text(
                  'Vos données médicales protégées\npar cryptographie avancée',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.68),
                    height: 1.55,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Security chips
              _buildSecurityChips(isActive),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShieldWidget(bool isActive) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glow = _pulseAnimation.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer rotating ring
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => Transform.rotate(
                angle: _particleController.value * math.pi * 2,
                child: Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.13),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 2,
                        left: 80,
                        child: _orbitDot(AppColors.primary),
                      ),
                      Positioned(
                        bottom: 2,
                        left: 80,
                        child: _orbitDot(const Color(0xFF00BCD4)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Inner counter-rotating ring
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => Transform.rotate(
                angle: -_particleController.value * math.pi * 2,
                child: Container(
                  width: 134,
                  height: 134,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.26),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // Shield with blue gradient
            Transform.scale(
              scale: 0.96 + (glow - 0.8) * 0.22,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF1565C0),
                      Color(0xFF0288D1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                          alpha: 0.42 + (glow - 0.8) * 1.3),
                      blurRadius: 26 + (glow - 0.8) * 38,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFF00BCD4).withValues(alpha: 0.14),
                      blurRadius: 55,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecurityChips(bool isActive) {
    final features = [
      (
        Icons.lock_rounded,
        'Chiffrement bout en bout',
        const Color(0xFF42A5F5),
      ),
      (
        Icons.vpn_key_rounded,
        'Clés privées personnelles',
        const Color(0xFF4DB6AC),
      ),
      (
        Icons.verified_user_rounded,
        'Audit immuable on-chain',
        const Color(0xFF00BCD4),
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, isActive ? 0 : 50, 0),
      child: Column(
        children: features.map((f) {
          final color = f.$3;
          return Container(
            margin: const EdgeInsets.only(bottom: 11),
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: color.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) => Icon(
                      f.$1,
                      color: color.withValues(
                          alpha: 0.75 +
                              (_pulseAnimation.value - 0.8) * 1.25),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    f.$2,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.check_circle_rounded,
                  color: color.withValues(alpha: 0.72),
                  size: 18,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: const [
            Color(0xFF42A5F5),
            Color(0xFFFFFFFF),
            Color(0xFF4DB6AC),
          ],
          stops: [
            (_particleController.value - 0.3).clamp(0.0, 1.0),
            _particleController.value.clamp(0.0, 1.0),
            (_particleController.value + 0.3).clamp(0.0, 1.0),
          ],
        ).createShader(bounds),
        child: const Text(
          'MEDAIChain',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Text(
      'Votre santé numérisée,\nsécurisée par blockchain',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.65),
        height: 1.52,
      ),
    );
  }

  Widget _buildPaginationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = index == _currentPage;
        return GestureDetector(
          onTap: () => _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: active ? 30 : 9,
            height: 9,
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF00897B)],
                    )
                  : null,
              color: active
                  ? null
                  : Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(5),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.65),
                        blurRadius: 10,
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
      builder: (context, _) {
        final glow = _pulseAnimation.value;
        return Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppColors.neonGradient,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withValues(
                    alpha: 0.38 + (glow - 0.8) * 0.55),
                blurRadius: 16 + (glow - 0.8) * 24,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: const Color(0xFF00897B).withValues(
                    alpha: 0.18 + (glow - 0.8) * 0.3),
                blurRadius: 32,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Tappable gradient surface
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _navigateToNextScreen,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.white.withValues(alpha: 0.15),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == 2 ? 'Commencer' : 'Continuer',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedBuilder(
                            animation: _floatController,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(
                                math.sin(
                                        _floatController.value * math.pi * 2) *
                                    4,
                                0,
                              ),
                              child: child,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Shine sweep
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, _) => Transform.translate(
                      offset: Offset(
                        (_particleController.value * 3 - 1) *
                            MediaQuery.of(context).size.width * 0.55,
                        0,
                      ),
                      child: Container(
                        width: 55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.52),
            fontSize: 14,
          ),
          children: [
            const TextSpan(text: 'Vous avez déjà un compte? '),
            TextSpan(
              text: 'Connexion',
              style: TextStyle(
                color: const Color(0xFF42A5F5).withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToNextScreen() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════════════════════

/// EKG / heartbeat line that sweeps left-to-right on each cycle.
class _EKGPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 (repeating)
  final Color color;

  const _EKGPainter({required this.progress, required this.color});

  // EKG waypoints: [normalised-x (0..1), y-offset (-1..1)]
  static const List<List<double>> _pts = [
    [0.00,  0.0 ],
    [0.10,  0.0 ],
    [0.18, -0.10],
    [0.22,  0.0 ],
    [0.28, -0.38], // P wave
    [0.34,  0.0 ],
    [0.39,  0.42], // Q dip
    [0.44, -1.00], // R spike
    [0.49,  0.60], // S dip
    [0.54,  0.0 ],
    [0.60, -0.32], // T wave
    [0.67,  0.0 ],
    [0.78,  0.0 ],
    [0.84, -0.10],
    [0.88,  0.0 ],
    [0.94, -0.38],
    [1.00,  0.0 ],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w   = size.width;
    final mid = size.height / 2;

    double yAt(double normX) {
      for (int i = 0; i < _pts.length - 1; i++) {
        if (normX >= _pts[i][0] && normX <= _pts[i + 1][0]) {
          final segLen = _pts[i + 1][0] - _pts[i][0];
          if (segLen == 0) return mid + _pts[i][1] * mid * 0.86;
          final frac = (normX - _pts[i][0]) / segLen;
          return mid +
              (_pts[i][1] + (_pts[i + 1][1] - _pts[i][1]) * frac) *
                  mid *
                  0.86;
        }
      }
      return mid;
    }

    // ── Full ghost path ──────────────────────────────────────────────────────
    final ghostPath = Path()..moveTo(0, mid);
    for (final pt in _pts) {
      ghostPath.lineTo(pt[0] * w, mid + pt[1] * mid * 0.86);
    }
    canvas.drawPath(
      ghostPath,
      Paint()
        ..color = color.withOpacity(0.11)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // ── Active (lit) path ────────────────────────────────────────────────────
    final targetX = progress * w;
    final activePath = Path()..moveTo(0, mid);

    double tipX = 0, tipY = mid;

    for (int i = 0; i < _pts.length; i++) {
      final px = _pts[i][0] * w;
      final py = mid + _pts[i][1] * mid * 0.86;

      if (px <= targetX) {
        activePath.lineTo(px, py);
        tipX = px;
        tipY = py;
      } else {
        // Interpolate to exact targetX within this segment
        final prevX = i > 0 ? _pts[i - 1][0] * w : 0.0;
        final prevY =
            i > 0 ? mid + _pts[i - 1][1] * mid * 0.86 : mid;
        final segLen = px - prevX;
        if (segLen > 0) {
          final frac = (targetX - prevX) / segLen;
          final interpY = prevY + (py - prevY) * frac;
          activePath.lineTo(targetX, interpY);
          tipX = targetX;
          tipY = interpY;
        }
        break;
      }
    }

    // Glow layer
    canvas.drawPath(
      activePath,
      Paint()
        ..color = color.withOpacity(0.38)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Bright line
    canvas.drawPath(
      activePath,
      Paint()
        ..color = color.withOpacity(0.96)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Tip — outer glow
    canvas.drawCircle(
      Offset(tipX, tipY),
      6,
      Paint()
        ..color = color.withOpacity(0.60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Tip — solid dot
    canvas.drawCircle(
      Offset(tipX, tipY),
      3.2,
      Paint()..color = color.withOpacity(1.0),
    );
    // Tip — bright core
    canvas.drawCircle(
      Offset(tipX, tipY),
      1.4,
      Paint()..color = Colors.white.withOpacity(0.92),
    );
  }

  @override
  bool shouldRepaint(_EKGPainter old) => old.progress != progress;
}

/// Faint dot-grid for a medical-tech feel.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF42A5F5).withOpacity(0.05)
      ..strokeWidth = 1.0;

    const step = 42.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
